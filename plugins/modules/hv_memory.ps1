#!powershell

# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.hyperv.plugins.module_utils.HyperV

$spec = @{
    options = @{
        name = @{ type = "str"; required = $true; aliases = @("vm_name") }
        dynamic_memory_enabled = @{ type = "bool" }
        startup_bytes = @{ type = "raw" }
        minimum_bytes = @{ type = "raw" }
        maximum_bytes = @{ type = "raw" }
        buffer = @{ type = "int" }
        priority = @{ type = "int" }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$name = $module.Params.name
$startup_bytes = $module.Params.startup_bytes
$minimum_bytes = $module.Params.minimum_bytes
$maximum_bytes = $module.Params.maximum_bytes

if ($null -ne $startup_bytes) {
    $startup_bytes = Convert-ToByte -SizeString $startup_bytes
    $module.Params.startup_bytes = $startup_bytes
}
if ($null -ne $minimum_bytes) {
    $minimum_bytes = Convert-ToByte -SizeString $minimum_bytes
    $module.Params.minimum_bytes = $minimum_bytes
}
if ($null -ne $maximum_bytes) {
    $maximum_bytes = Convert-ToByte -SizeString $maximum_bytes
    $module.Params.maximum_bytes = $maximum_bytes
}

$module.Result.name = $name

# Define the mapping between Ansible params and Hyper-V properties
$propertyMap = @(
    @{ Param = "dynamic_memory_enabled"; Property = "DynamicMemoryEnabled"; Type = "bool" }
    @{ Param = "startup_bytes"; Property = "Startup"; Type = "long"; CmdletParam = "StartupBytes" }
    @{ Param = "minimum_bytes"; Property = "Minimum"; Type = "long"; CmdletParam = "MinimumBytes" }
    @{ Param = "maximum_bytes"; Property = "Maximum"; Type = "long"; CmdletParam = "MaximumBytes" }
    @{ Param = "buffer"; Property = "Buffer"; Type = "int" }
    @{ Param = "priority"; Property = "Priority"; Type = "int" }
)

try {
    $vm = Get-VM -Name $name -ErrorAction SilentlyContinue

    if (-not $vm) {
        $module.FailJson("Virtual Machine '$name' not found.")
    }

    $mem = Get-VMMemory -VMName $name -ErrorAction SilentlyContinue
    if (-not $mem) {
        $module.FailJson("Failed to retrieve memory configuration for VM '$name'.")
    }

    $changed = Test-HyperVPropertiesChanged -PropertyMap $propertyMap -CurrentObject $mem -AnsibleParams $module.Params
    $module.Result.changed = $changed

    if ($changed) {
        if ($vm.State -ne 'Off' -and $null -ne $module.Params.startup_bytes) {
            $module.FailJson("Cannot apply Memory changes (Startup Bytes) while the VM is not Off. Stop the VM first.")
        }

        if ($module.CheckMode) {
            Set-HyperVResultFromMap -PropertyMap $propertyMap -CurrentObject $mem -ModuleResult $module.Result
            # Override with desired
            foreach ($map in $propertyMap) {
                $paramValue = $module.Params.($map.Param)
                if ($null -ne $paramValue) {
                    $module.Result.($map.Param) = $paramValue
                }
            }
            $module.ExitJson()
        }

        # Build parameters using map but handle the CmdletParam overrides
        $cmdParams = @{ VMName = $name }
        foreach ($map in $propertyMap) {
            $paramValue = $module.Params.($map.Param)
            if ($null -ne $paramValue) {
                $targetParam = if ($null -ne $map.CmdletParam) { $map.CmdletParam } else { $map.Property }
                $cmdParams.($targetParam) = $paramValue
            }
        }

        Set-VMMemory @cmdParams | Out-Null
        $mem = Get-VMMemory -VMName $name
    }

    Set-HyperVResultFromMap -PropertyMap $propertyMap -CurrentObject $mem -ModuleResult $module.Result

    $module.ExitJson()
}
catch {
    $module.FailJson("Failed to manage VM Memory: $($_.Exception.Message)")
}
