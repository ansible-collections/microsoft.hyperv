#!powershell

# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.hyperv.plugins.module_utils.HyperV

$spec = @{
    options = @{
        name = @{ type = "str"; required = $true; aliases = @("vm_name") }
        count = @{ type = "int" }
        compatibility_for_migration_enabled = @{ type = "bool" }
        expose_virtualization_extensions = @{ type = "bool" }
        enable_host_resource_protection = @{ type = "bool" }
        maximum = @{ type = "int" }
        reserve = @{ type = "int" }
        relative_weight = @{ type = "int" }
        hw_thread_count_per_core = @{ type = "int" }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$name = $module.Params.name
$module.Result.name = $name

# Define the mapping between Ansible params and Hyper-V properties
$propertyMap = @(
    @{ Param = "count"; Property = "Count"; Type = "int" }
    @{ Param = "compatibility_for_migration_enabled"; Property = "CompatibilityForMigrationEnabled"; Type = "bool" }
    @{ Param = "expose_virtualization_extensions"; Property = "ExposeVirtualizationExtensions"; Type = "bool" }
    @{ Param = "enable_host_resource_protection"; Property = "EnableHostResourceProtection"; Type = "bool" }
    @{ Param = "maximum"; Property = "Maximum"; Type = "int" }
    @{ Param = "reserve"; Property = "Reserve"; Type = "int" }
    @{ Param = "relative_weight"; Property = "RelativeWeight"; Type = "int" }
    @{ Param = "hw_thread_count_per_core"; Property = "HwThreadCountPerCore"; Type = "int" }
)

try {
    $vm = Get-VM -Name $name -ErrorAction SilentlyContinue
    if (-not $vm) {
        $module.FailJson("Virtual Machine '$name' not found.")
    }

    $cpu = Get-VMProcessor -VMName $name -ErrorAction SilentlyContinue
    if (-not $cpu) {
        $module.FailJson("Failed to retrieve processor configuration for VM '$name'.")
    }

    $changed = Test-HyperVPropertiesChanged -PropertyMap $propertyMap -CurrentObject $cpu -AnsibleParams $module.Params
    $module.Result.changed = $changed

    if ($changed) {
        if ($vm.State -ne 'Off' -and (
                $null -ne $module.Params.count -or
                $null -ne $module.Params.expose_virtualization_extensions -or
                $null -ne $module.Params.compatibility_for_migration_enabled
            )) {
            $module.FailJson("Cannot apply CPU changes (Count, Nested Virt, or Compat Mode) while the VM is not Off. Stop the VM first.")
        }

        if ($module.CheckMode) {
            Set-HyperVResultFromMap -PropertyMap $propertyMap -CurrentObject $cpu -ModuleResult $module.Result
            # Override with desired
            foreach ($map in $propertyMap) {
                $paramValue = $module.Params.($map.Param)
                if ($null -ne $paramValue) {
                    $module.Result.($map.Param) = $paramValue
                }
            }
            $module.ExitJson()
        }

        $cmdParams = Get-HyperVParametersFromMap -PropertyMap $propertyMap -AnsibleParams $module.Params
        $cmdParams.VMName = $name
        Set-VMProcessor @cmdParams | Out-Null

        $cpu = Get-VMProcessor -VMName $name
    }

    Set-HyperVResultFromMap -PropertyMap $propertyMap -CurrentObject $cpu -ModuleResult $module.Result

    $module.ExitJson()
}
catch {
    $module.FailJson("Failed to manage VM Processor: $($_.Exception.Message)")
}
