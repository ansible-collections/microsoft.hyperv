#!powershell

# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic

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
$count = $module.Params.count
$compatibility_for_migration_enabled = $module.Params.compatibility_for_migration_enabled
$expose_virtualization_extensions = $module.Params.expose_virtualization_extensions
$enable_host_resource_protection = $module.Params.enable_host_resource_protection
$maximum = $module.Params.maximum
$reserve = $module.Params.reserve
$relative_weight = $module.Params.relative_weight
$hw_thread_count_per_core = $module.Params.hw_thread_count_per_core

$module.Result.name = $name

try {
    $vm = Get-VM -Name $name -ErrorAction SilentlyContinue

    if (-not $vm) {
        $module.FailJson("Virtual Machine '$name' not found.")
    }

    $cpu = Get-VMProcessor -VMName $name -ErrorAction SilentlyContinue

    if (-not $cpu) {
        $module.FailJson("Failed to retrieve processor configuration for VM '$name'.")
    }

    $changed = $false
    $cmdParams = @{
        VMName = $name
    }

    $propertyMap = @(
        @{
            Name = 'count'
            Current = $cpu.Count
            Desired = $count
            CmdletParam = 'Count'
        }
        @{
            Name = 'compatibility_for_migration_enabled'
            Current = [bool]$cpu.CompatibilityForMigrationEnabled
            Desired = $compatibility_for_migration_enabled
            CmdletParam = 'CompatibilityForMigrationEnabled'
        }
        @{
            Name = 'expose_virtualization_extensions'
            Current = [bool]$cpu.ExposeVirtualizationExtensions
            Desired = $expose_virtualization_extensions
            CmdletParam = 'ExposeVirtualizationExtensions'
        }
        @{
            Name = 'enable_host_resource_protection'
            Current = [bool]$cpu.EnableHostResourceProtection
            Desired = $enable_host_resource_protection
            CmdletParam = 'EnableHostResourceProtection'
        }
        @{
            Name = 'maximum'
            Current = $cpu.Maximum
            Desired = $maximum
            CmdletParam = 'Maximum'
        }
        @{
            Name = 'reserve'
            Current = $cpu.Reserve
            Desired = $reserve
            CmdletParam = 'Reserve'
        }
        @{
            Name = 'relative_weight'
            Current = $cpu.RelativeWeight
            Desired = $relative_weight
            CmdletParam = 'RelativeWeight'
        }
        @{
            Name = 'hw_thread_count_per_core'
            Current = $cpu.HwThreadCountPerCore
            Desired = $hw_thread_count_per_core
            CmdletParam = 'HwThreadCountPerCore'
        }
    )

    foreach ($prop in $propertyMap) {
        $module.Result.($prop.Name) = $prop.Current

        if ($null -ne $prop.Desired -and $prop.Current -ne $prop.Desired) {
            $cmdParams.($prop.CmdletParam) = $prop.Desired
            $changed = $true

            if ($module.CheckMode) {
                $module.Result.($prop.Name) = $prop.Desired
            }
        }
    }

    $module.Result.changed = $changed

    if ($changed -and -not $module.CheckMode) {
        if ($vm.State -ne 'Off' -and ($null -ne $count -or $null -ne $expose_virtualization_extensions -or $null -ne $compatibility_for_migration_enabled)) {
            # Certain changes require the VM to be stopped. We fail explicitly to prevent accidental disruptions,
            # as forcing a VM off for a CPU change is extremely dangerous in production.
            $module.FailJson("Cannot apply CPU changes (Count, Nested Virt, or Compat Mode) while the VM is not Off. Stop the VM first.")
        }

        Set-VMProcessor @cmdParams | Out-Null

        # Refresh for accurate return data
        $newCpu = Get-VMProcessor -VMName $name
        foreach ($prop in $propertyMap) {
            $module.Result.($prop.Name) = $newCpu.($prop.CmdletParam)
        }
    }

    $module.ExitJson()
}
catch {
    $module.FailJson("Failed to manage VM Processor: $($_.Exception.Message)")
}
