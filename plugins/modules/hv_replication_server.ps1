#!powershell

# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.hyperv.plugins.module_utils.HyperV

$spec = @{
    options = @{
        replication_enabled = @{ type = "bool" }
        allowed_authentication_type = @{ type = "str"; choices = @("Kerberos", "Certificate", "CertificateAndKerberos") }
        certificate_thumbprint = @{ type = "str" }
        kerberos_port = @{ type = "int"; default = 80 }
        certificate_port = @{ type = "int"; default = 443 }
        default_storage_location = @{ type = "str" }
        allow_any_server = @{ type = "bool" }
        authorized_servers = @{ type = "list"; elements = "dict"; options = @{
            server = @{ type = "str"; required = $true }
            trust_group = @{ type = "str" }
            storage_location = @{ type = "str"; required = $true }
            state = @{ type = "str"; default = "present"; choices = @("present", "absent") }
        }}
        }
        supports_check_mode = $true
        }

        $module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

        $auth_servers = $module.Params.authorized_servers

        # Map Ansible parameters to PowerShell Set-VMReplicationServer parameters
        $propertyMap = @(
        @{ Param = "replication_enabled"; Property = "ReplicationEnabled"; Type = "bool" }
        @{ Param = "allowed_authentication_type"; Property = "AllowedAuthenticationType"; Type = "enum" }
        @{ Param = "certificate_thumbprint"; Property = "CertificateThumbprint"; Type = "string" }
        @{ Param = "kerberos_port"; Property = "KerberosAuthenticationPort"; Type = "int" }
        @{ Param = "certificate_port"; Property = "CertificateAuthenticationPort"; Type = "int" }
        @{ Param = "default_storage_location"; Property = "DefaultStorageLocation"; Type = "string" }
        @{ Param = "allow_any_server"; Property = "ReplicationAllowedFromAnyServer"; Type = "bool" }
        )

        try {
        $server = Get-VMReplicationServer -ErrorAction Stop

        # 1. Manage Core Server Properties
        $changed = Test-HyperVPropertiesChanged -PropertyMap $propertyMap -CurrentObject $server -AnsibleParams $module.Params

        # Validation
        $targetAuthType = if ($module.Params.ContainsKey("allowed_authentication_type") -and $null -ne $module.Params.allowed_authentication_type) { $module.Params.allowed_authentication_type } else { $server.AllowedAuthenticationType.ToString() }
        if ($targetAuthType -match "Certificate") {
        # If setting to certificate, thumbprint is usually required unless previously set
        $hasThumbprint = ($null -ne $module.Params.certificate_thumbprint -and $module.Params.certificate_thumbprint -ne "")
        if (-not $hasThumbprint -and -not $server.CertificateThumbprint) {
            $module.FailJson("A 'certificate_thumbprint' is required when 'allowed_authentication_type' uses Certificates.")
        }
        }

        # 2. Manage Authorization Entries (Allowed Servers)
        $authChanged = $false
        $currentEntries = @(Get-VMReplicationAuthorizationEntry -ErrorAction SilentlyContinue)

        $entriesToAddOrUpdate = @()
        $entriesToRemove = @()

        if ($module.Params.ContainsKey("authorized_servers") -and $null -ne $auth_servers) {
        foreach ($auth in $auth_servers) {
            $existing = $currentEntries | Where-Object { $_.AllowedPrimaryServer -eq $auth.server } | Select-Object -First 1

            if ($auth.state -eq "present") {
                if (-not $existing) {
                    $entriesToAddOrUpdate += $auth
                    $authChanged = $true
                } else {
                    # Check if trust group or storage location needs updating
                    $trustDiffers = $false
                    if ($module.Params.ContainsKey("authorized_servers")) {
                        # Normalize null and empty to compare consistently
                        $requestedTrust = if ($null -ne $auth.trust_group) { $auth.trust_group } else { "" }
                        $currentTrust = if ($null -ne $existing.TrustGroup) { $existing.TrustGroup } else { "" }
                        if ($requestedTrust -ne $currentTrust) {
                            $trustDiffers = $true
                        }
                    }

                    $storageDiffers = ($auth.storage_location -ne $existing.ReplicaStorageLocation)
                    if ($trustDiffers -or $storageDiffers) {
                        $entriesToAddOrUpdate += $auth
                        $authChanged = $true
                    }
                }
            } else {                if ($existing) {
                    $entriesToRemove += $existing
                    $authChanged = $true
                }
            }
        }
    }

    $module.Result.changed = ($changed -or $authChanged)

    # 3. Output Forecasting / Result Gathering
    if ($module.CheckMode) {
        Set-HyperVResultFromMap -PropertyMap $propertyMap -CurrentObject $server -ModuleResult $module.Result

        # Overlay user params for forecasting core properties
        foreach ($prop in $propertyMap) {
            if ($module.Params.ContainsKey($prop.Param) -and $null -ne $module.Params[$prop.Param]) {
                $module.Result.($prop.Param) = $module.Params[$prop.Param]
            }
        }

        # Format existing entries for check mode forecast
        $forecastEntries = @()
        foreach ($ce in $currentEntries) {
            # Skip if it's going to be removed
            $willRemove = $entriesToRemove | Where-Object { $_.AllowedPrimaryServer -eq $ce.AllowedPrimaryServer }
            if (-not $willRemove) {
                # Check if it's going to be updated
                $willUpdate = $entriesToAddOrUpdate | Where-Object { $_.server -eq $ce.AllowedPrimaryServer } | Select-Object -First 1
                if ($willUpdate) {
                    $forecastEntries += @{
                        server = $willUpdate.server
                        trust_group = if ($null -ne $willUpdate.trust_group) { $willUpdate.trust_group } else { $ce.TrustGroup }
                        storage_location = $willUpdate.storage_location
                    }
                } else {
                    $forecastEntries += @{
                        server = $ce.AllowedPrimaryServer
                        trust_group = $ce.TrustGroup
                        storage_location = $ce.ReplicaStorageLocation
                    }
                }
            }
        }
        # Add brand new entries
        foreach ($ne in $entriesToAddOrUpdate) {
            $exists = $currentEntries | Where-Object { $_.AllowedPrimaryServer -eq $ne.server }
            if (-not $exists) {
                $forecastEntries += @{
                    server = $ne.server
                    trust_group = $ne.trust_group
                    storage_location = $ne.storage_location
                }
            }
        }
        $module.Result.authorized_servers = $forecastEntries

        $module.ExitJson()
    }

    # 4. Actual Execution
    if ($changed) {
        $setParams = Get-HyperVParametersFromMap -PropertyMap $propertyMap -AnsibleParams $module.Params
        Set-VMReplicationServer @setParams -Force -ErrorAction Stop | Out-Null
    }

    if ($authChanged) {
        try {
            foreach ($entry in $entriesToRemove) {
                Remove-VMReplicationAuthorizationEntry -AllowedPrimaryServer $entry.AllowedPrimaryServer -ErrorAction Stop | Out-Null
            }
            foreach ($entry in $entriesToAddOrUpdate) {
                $existing = $currentEntries | Where-Object { $_.AllowedPrimaryServer -eq $entry.server } | Select-Object -First 1
                if ($existing) {
                    $setAuthParams = @{
                        AllowedPrimaryServer = $entry.server
                        ReplicaStorageLocation = $entry.storage_location
                        ErrorAction = "Stop"
                    }
                    if ($null -ne $entry.trust_group) { $setAuthParams.TrustGroup = $entry.trust_group }
                    Set-VMReplicationAuthorizationEntry @setAuthParams | Out-Null
                } else {
                    $newAuthParams = @{
                        AllowedPrimaryServer = $entry.server
                        ReplicaStorageLocation = $entry.storage_location
                        ErrorAction = "Stop"
                    }
                    if ($null -ne $entry.trust_group) { $newAuthParams.TrustGroup = $entry.trust_group }
                    New-VMReplicationAuthorizationEntry @newAuthParams | Out-Null
                }
            }
        } catch [Microsoft.HyperV.PowerShell.VirtualizationException], [CimException] {
            $module.FailJson("A concurrency error occurred while updating authorization entries. The Hyper-V WMI provider may be busy. Details: $($_.Exception.Message)")
        }
    }

    # 5. Final State Retrieval
    $finalServer = Get-VMReplicationServer -ErrorAction Stop
    Set-HyperVResultFromMap -PropertyMap $propertyMap -CurrentObject $finalServer -ModuleResult $module.Result

    $finalAuth = @()
    $finalEntries = Get-VMReplicationAuthorizationEntry -ErrorAction SilentlyContinue
    if ($finalEntries) {
        foreach ($fe in $finalEntries) {
            $finalAuth += @{
                server = $fe.AllowedPrimaryServer
                trust_group = $fe.TrustGroup
                storage_location = $fe.ReplicaStorageLocation
            }
        }
        $module.Result.authorized_servers = $finalAuth
    } else {
        # Explicitly set an empty typed array to avoid Ansible.Basic converting it to null
        # or creating a Dictionary artifact when returning empty lists from Windows.
        $module.Result.authorized_servers = New-Object object[] 0
    }

    $module.ExitJson()
}
catch {
    $module.FailJson("Failed to configure Replication Server settings: $($_.Exception.Message)")
}
