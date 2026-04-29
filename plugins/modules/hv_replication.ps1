#!powershell

# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.hyperv.plugins.module_utils.HyperV

$spec = @{
    options = @{
        vm_name = @{ type = "str"; required = $true; aliases = @("name") }
        replica_server = @{ type = "str" }
        replica_port = @{ type = "int" }
        authentication_type = @{ type = "str"; default = "Kerberos"; choices = @("Kerberos", "Certificate") }
        certificate_thumbprint = @{ type = "str" }
        frequency_sec = @{ type = "int"; default = 300; choices = @(30, 300, 900) }
        compression_enabled = @{ type = "bool"; default = $true }
        start_initial_replication = @{ type = "bool"; default = $false }
        state = @{ type = "str"; default = "present"; choices = @("present", "absent") }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$vm_name = $module.Params.vm_name
$state = $module.Params.state
$auth_type = $module.Params.authentication_type
$start_sync = $module.Params.start_initial_replication

$module.Result.vm_name = $vm_name
$module.Result.state = $state

# Map Ansible parameters to PowerShell Enable/Set-VMReplication parameters
$propertyMap = @(
    @{ Param = "replica_server"; Property = "ReplicaServerName"; Type = "string" }
    @{ Param = "replica_port"; Property = "ReplicaServerPort"; Type = "int" }
    @{ Param = "authentication_type"; Property = "AuthenticationType"; Type = "enum" }
    @{ Param = "certificate_thumbprint"; Property = "CertificateThumbprint"; Type = "string" }
    @{ Param = "frequency_sec"; Property = "ReplicationFrequencySec"; Type = "int" }
    @{ Param = "compression_enabled"; Property = "CompressionEnabled"; Type = "bool" }
)

try {
    $vm = Get-VM -Name $vm_name -ErrorAction SilentlyContinue
    if (-not $vm) {
        $module.FailJson("Virtual Machine '$vm_name' not found.")
    }

    $replication = Get-VMReplication -VMName $vm_name -ErrorAction SilentlyContinue
    $isReplicated = ($null -ne $replication)

    switch ($state) {
        "present" {
            # Inject dynamic default for replica_port to ensure accurate idempotency and Check Mode forecasting
            if (-not $module.Params.ContainsKey("replica_port") -or $null -eq $module.Params.replica_port) {
                if ($auth_type -eq "Kerberos") {
                    $module.Params.replica_port = 80
                }
                else {
                    $module.Params.replica_port = 443
                }
            }

            # Validation
            if (-not $module.Params.ContainsKey("replica_server") -or $null -eq $module.Params.replica_server -or $module.Params.replica_server -eq "") {
                if (-not $isReplicated) {
                    $module.FailJson("The 'replica_server' parameter is required to enable replication.")
                }
            }

            if ($auth_type -eq "Certificate") {
                $hasThumbprint = ($null -ne $module.Params.certificate_thumbprint -and $module.Params.certificate_thumbprint -ne "")
                if (-not $hasThumbprint -and (-not $isReplicated -or -not $replication.CertificateThumbprint)) {
                    $module.FailJson("A 'certificate_thumbprint' is required when 'authentication_type' is Certificate.")
                }
            }

            $changed = $false

            if (-not $isReplicated) {
                $changed = $true
                if (-not $module.CheckMode) {
                    $enableParams = Get-HyperVParametersFromMap -PropertyMap $propertyMap -AnsibleParams $module.Params
                    $enableParams.VMName = $vm_name

                    try {
                        Enable-VMReplication @enableParams -ErrorAction Stop | Out-Null
                    }
                    catch [Microsoft.HyperV.PowerShell.VirtualizationException], [CimException] {
                        $module.FailJson("Failed to enable replication for VM '$vm_name'. Details: $($_.Exception.Message)")
                    }

                    if ($start_sync) {
                        try {
                            Start-VMInitialReplication -VMName $vm_name -ErrorAction Stop | Out-Null
                        }
                        catch [Microsoft.HyperV.PowerShell.VirtualizationException], [CimException] {
                            $module.FailJson("Failed to start initial replication for VM '$vm_name'. Details: $($_.Exception.Message)")
                        }
                    }

                    $replication = Get-VMReplication -VMName $vm_name -ErrorAction Stop
                }
            }
            else {
                # Safety Check: Hyper-V crashes if you try to change the destination Replica Server via Set-VMReplication.
                # If the target server changes, we must safely tear down the old replication link and build a new one.
                if ($module.Params.ContainsKey("replica_server") -and $null -ne $module.Params.replica_server) {
                    if ($replication.ReplicaServerName -ne $module.Params.replica_server) {
                        $changed = $true
                        if (-not $module.CheckMode) {
                            try {
                                Remove-VMReplication -VMName $vm_name -ErrorAction Stop | Out-Null
                            }
                            catch [Microsoft.HyperV.PowerShell.VirtualizationException], [CimException] {
                                $errMsg = "Failed to remove old replication profile prior to destination change for VM '$vm_name'."
                                $module.FailJson("$errMsg Details: $($_.Exception.Message)")
                            }

                            $enableParams = Get-HyperVParametersFromMap -PropertyMap $propertyMap -AnsibleParams $module.Params
                            $enableParams.VMName = $vm_name

                            try {
                                Enable-VMReplication @enableParams -ErrorAction Stop | Out-Null
                            }
                            catch [Microsoft.HyperV.PowerShell.VirtualizationException], [CimException] {
                                $module.FailJson("Failed to enable replication to new destination for VM '$vm_name'. Details: $($_.Exception.Message)")
                            }

                            if ($start_sync) {
                                try {
                                    Start-VMInitialReplication -VMName $vm_name -ErrorAction Stop | Out-Null
                                }
                                catch [Microsoft.HyperV.PowerShell.VirtualizationException], [CimException] {
                                    $errMsg = "Failed to start initial replication to new destination for VM '$vm_name'."
                                    $module.FailJson("$errMsg Details: $($_.Exception.Message)")
                                }
                            }

                            $replication = Get-VMReplication -VMName $vm_name -ErrorAction Stop
                        }
                    }
                }

                # Only evaluate standard updates if we didn't just rebuild the entire connection
                if ($changed -eq $false) {
                    $changed = Test-HyperVPropertiesChanged -PropertyMap $propertyMap -CurrentObject $replication -AnsibleParams $module.Params
                    if ($changed -and -not $module.CheckMode) {
                        $setParams = Get-HyperVParametersFromMap -PropertyMap $propertyMap -AnsibleParams $module.Params
                        $setParams.VMName = $vm_name
                        try {
                            Set-VMReplication @setParams -ErrorAction Stop | Out-Null
                        }
                        catch [Microsoft.HyperV.PowerShell.VirtualizationException], [CimException] {
                            $module.FailJson("Failed to update replication settings for VM '$vm_name'. Details: $($_.Exception.Message)")
                        }
                        $replication = Get-VMReplication -VMName $vm_name -ErrorAction Stop
                    }
                }
            }

            $module.Result.changed = $changed

            # Output Forecasting / Result gathering
            if ($module.CheckMode) {
                if ($isReplicated) {
                    Set-HyperVResultFromMap -PropertyMap $propertyMap -CurrentObject $replication -ModuleResult $module.Result
                }

                # Overlay user params for forecasting
                foreach ($prop in $propertyMap) {
                    if ($module.Params.ContainsKey($prop.Param) -and $null -ne $module.Params[$prop.Param]) {
                        $module.Result.($prop.Param) = $module.Params[$prop.Param]
                    }
                }
                $module.ExitJson()
            }

            Set-HyperVResultFromMap -PropertyMap $propertyMap -CurrentObject $replication -ModuleResult $module.Result
        }
        "absent" {
            if (-not $isReplicated) {
                $module.Result.changed = $false
                $module.ExitJson()
            }

            $module.Result.changed = $true
            if ($module.CheckMode) {
                $module.ExitJson()
            }

            try {
                Remove-VMReplication -VMName $vm_name -ErrorAction Stop | Out-Null
            }
            catch [Microsoft.HyperV.PowerShell.VirtualizationException], [CimException] {
                $module.FailJson("Failed to disable replication for VM '$vm_name'. Details: $($_.Exception.Message)")
            }
        }
    }

    $module.ExitJson()
}
catch {
    $module.FailJson("Failed to configure VM replication for '$vm_name': $($_.Exception.Message)")
}
