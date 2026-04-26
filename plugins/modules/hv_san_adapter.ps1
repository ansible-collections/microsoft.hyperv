#!powershell

# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.hyperv.plugins.module_utils.HyperV

$spec = @{
    options = @{
        vm_name = @{ type = "str"; required = $true; aliases = @("name", "vm") }
        san_name = @{ type = "str" }
        wwn_set_a = @{
            type = "dict"
            options = @{
                wwnn = @{ type = "str" }
                wwpn = @{ type = "str" }
            }
        }
        wwn_set_b = @{
            type = "dict"
            options = @{
                wwnn = @{ type = "str" }
                wwpn = @{ type = "str" }
            }
        }
        generate_wwn = @{ type = "bool"; default = $true }
        state = @{ type = "str"; default = "present"; choices = @("present", "absent") }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$vm_name = $module.Params.vm_name
$san_name = $module.Params.san_name
$wwn_a = $module.Params.wwn_set_a
$wwn_b = $module.Params.wwn_set_b
$generate_wwn = $module.Params.generate_wwn
$state = $module.Params.state

$module.Result.vm_name = $vm_name

# Property Map for result formatting
$propertyMap = @(
    @{ Param = "san_name"; Property = "SanName"; Type = "string" }
)

Function Get-WwnDict {
    param ($Wwnn, $Wwpn)
    if ($null -eq $Wwnn -and $null -eq $Wwpn) { return $null }
    return @{
        wwnn = $Wwnn
        wwpn = $Wwpn
    }
}

try {
    $vm = Get-VM -Name $vm_name -ErrorAction SilentlyContinue
    if (-not $vm) {
        $module.FailJson("Virtual Machine '$vm_name' not found.")
    }

    $hbas = Get-VMFibreChannelHba -VMName $vm_name -ErrorAction SilentlyContinue
    $existingHba = $null

    if ($hbas) {
        if ($null -ne $san_name) {
            $hbaMatches = @($hbas | Where-Object { $_.SanName -eq $san_name })
            if ($hbaMatches.Count -gt 1) {
                $module.FailJson("Multiple Fibre Channel HBAs connected to SAN '$san_name' found on VM '$vm_name'. Targeting is ambiguous.")
            }
            elseif ($hbaMatches.Count -eq 1) {
                $existingHba = $hbaMatches[0]
            }
        }
        else {
            if ($hbas.Count -gt 1) {
                $module.FailJson("Multiple Fibre Channel HBAs found on VM '$vm_name'. You must specify 'san_name' to target a specific adapter.")
            }
            $existingHba = $hbas[0]
        }
    }

    switch ($state) {
        "present" {
            if (-not $existingHba) {
                if ($null -eq $san_name) {
                    $module.FailJson("san_name is required to create a new Fibre Channel HBA.")
                }

                $module.Result.changed = $true
                if ($module.CheckMode) {
                    $module.Result.san_name = $san_name
                    $module.ExitJson()
                }

                $addParams = @{
                    VMName = $vm_name
                    SanName = $san_name
                    ErrorAction = "Stop"
                }

                if ($generate_wwn) {
                    $addParams.GenerateWwn = $true
                }
                else {
                    if ($null -eq $wwn_a -or $null -eq $wwn_b) {
                        $module.FailJson("wwn_set_a and wwn_set_b are required if generate_wwn is false.")
                    }
                    $addParams.WorldWideNodeNameSetA = $wwn_a.wwnn
                    $addParams.WorldWidePortNameSetA = $wwn_a.wwpn
                    $addParams.WorldWideNodeNameSetB = $wwn_b.wwnn
                    $addParams.WorldWidePortNameSetB = $wwn_b.wwpn
                }

                $existingHba = Add-VMFibreChannelHba @addParams -Passthru
            }
            else {
                # Update logic (limited by Hyper-V cmdlets, usually involves Set-VMFibreChannelHba)
                $changed = $false
                $setParams = @{
                    VMFibreChannelHba = $existingHba
                    ErrorAction = "Stop"
                }

                if ($null -ne $san_name -and $existingHba.SanName -ne $san_name) {
                    $setParams.SanName = $san_name
                    $changed = $true
                }

                # WWN updates are rare and usually require GenerateWwn or explicit sets
                # We prioritize the provided WWNs if they differ from current
                if (-not $generate_wwn -and $null -ne $wwn_a) {
                    if ($existingHba.WorldWideNodeNameSetA -ne $wwn_a.wwnn -or $existingHba.WorldWidePortNameSetA -ne $wwn_a.wwpn) {
                        $setParams.NewWorldWideNodeNameSetA = $wwn_a.wwnn
                        $setParams.NewWorldWidePortNameSetA = $wwn_a.wwpn
                        $changed = $true
                    }
                }

                if (-not $generate_wwn -and $null -ne $wwn_b) {
                    if ($existingHba.WorldWideNodeNameSetB -ne $wwn_b.wwnn -or $existingHba.WorldWidePortNameSetB -ne $wwn_b.wwpn) {
                        $setParams.NewWorldWideNodeNameSetB = $wwn_b.wwnn
                        $setParams.NewWorldWidePortNameSetB = $wwn_b.wwpn
                        $changed = $true
                    }
                }

                $module.Result.changed = $changed
                if ($module.CheckMode) {
                    Set-HyperVResultFromMap -PropertyMap $propertyMap -CurrentObject $existingHba -ModuleResult $module.Result
                    $module.ExitJson()
                }

                if ($changed) {
                    Set-VMFibreChannelHba @setParams | Out-Null
                    $existingHba = Get-VMFibreChannelHba -VMName $vm_name | Where-Object {
                        $_.Id -eq $existingHba.Id
                    }
                }
            }

            # Return final state
            $module.Result.san_name = $existingHba.SanName
            $module.Result.wwn_set_a = Get-WwnDict -Wwnn $existingHba.WorldWideNodeNameSetA -Wwpn $existingHba.WorldWidePortNameSetA
            $module.Result.wwn_set_b = Get-WwnDict -Wwnn $existingHba.WorldWideNodeNameSetB -Wwpn $existingHba.WorldWidePortNameSetB
        }
        "absent" {
            if (-not $existingHba) {
                $module.Result.changed = $false
                $module.ExitJson()
            }

            $module.Result.changed = $true
            if ($module.CheckMode) {
                $module.ExitJson()
            }

            Remove-VMFibreChannelHba -VMFibreChannelHba $existingHba -ErrorAction Stop | Out-Null
        }
    }

    $module.ExitJson()
}
catch {
    $module.FailJson("Failed to manage Fibre Channel HBA on VM '$vm_name': $($_.Exception.Message)")
}
