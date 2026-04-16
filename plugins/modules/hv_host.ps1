#!powershell

# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.hyperv.plugins.module_utils.HyperV

$spec = @{
    options = @{
        virtual_machine_path = @{ type = "str" }
        virtual_hard_disk_path = @{ type = "str" }
        numa_spanning_enabled = @{ type = "bool" }
        enable_enhanced_session_mode = @{ type = "bool" }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

# Define the mapping between Ansible params and Hyper-V properties
$propertyMap = @(
    @{ Param = "virtual_machine_path"; Property = "VirtualMachinePath"; Type = "string" }
    @{ Param = "virtual_hard_disk_path"; Property = "VirtualHardDiskPath"; Type = "string" }
    @{ Param = "numa_spanning_enabled"; Property = "NumaSpanningEnabled"; Type = "bool" }
    @{ Param = "enable_enhanced_session_mode"; Property = "EnableEnhancedSessionMode"; Type = "bool" }
)

try {
    $hostConfig = Get-VMHost -ErrorAction SilentlyContinue

    if (-not $hostConfig) {
        $module.FailJson("Failed to retrieve Hyper-V host configuration.")
    }

    $changed = Test-HyperVPropertiesChanged -PropertyMap $propertyMap -CurrentObject $hostConfig -AnsibleParams $module.Params
    $module.Result.changed = $changed

    if ($changed) {
        if ($module.CheckMode) {
            Set-HyperVResultFromMap -PropertyMap $propertyMap -CurrentObject $hostConfig -ModuleResult $module.Result
            # Override with desired state for check mode
            foreach ($map in $propertyMap) {
                $paramValue = $module.Params.($map.Param)
                if ($null -ne $paramValue) {
                    $module.Result.($map.Param) = $paramValue
                }
            }
            $module.ExitJson()
        }

        $cmdParams = Get-HyperVParametersFromMap -PropertyMap $propertyMap -AnsibleParams $module.Params
        Set-VMHost @cmdParams | Out-Null
        $hostConfig = Get-VMHost -ErrorAction SilentlyContinue
    }

    Set-HyperVResultFromMap -PropertyMap $propertyMap -CurrentObject $hostConfig -ModuleResult $module.Result

    $module.ExitJson()
}
catch {
    $module.FailJson("Failed to configure Hyper-V host: $($_.Exception.Message)")
}
