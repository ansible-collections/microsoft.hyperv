#!powershell

# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.hyperv.plugins.module_utils.HyperV

$spec = @{
    options = @{
        name = @{ type = "str"; required = $true; aliases = @("vm_name") }
        state = @{ type = "str"; default = "present"; choices = @("present", "absent") }
        generation = @{ type = "int"; default = 1; choices = @(1, 2) }
        memory_startup_bytes = @{ type = "raw" }
        boot_device = @{ type = "str"; choices = @("CD", "Floppy", "IDE", "LegacyNetworkAdapter", "NetworkAdapter", "VHD") }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$name = $module.Params.name
$state = $module.Params.state
$generation = $module.Params.generation
$memory_startup_bytes = $module.Params.memory_startup_bytes

if ($null -ne $memory_startup_bytes) {
    $memory_startup_bytes = Convert-ToByte -SizeString $memory_startup_bytes
}

$boot_device = $module.Params.boot_device

$module.Result.name = $name
$module.Result.state = ""

try {
    $vm = Get-VM -Name $name -ErrorAction SilentlyContinue

    if ($state -eq "present") {
        if ($vm) {
            $module.Result.state = "present"
            $module.ExitJson()
        }

        $module.Result.changed = $true
        $module.Result.state = "present"

        if ($module.CheckMode) {
            $module.ExitJson()
        }

        $cmdParams = @{
            Name = $name
            Generation = $generation
        }

        if ($null -ne $memory_startup_bytes) {
            $cmdParams.MemoryStartupBytes = $memory_startup_bytes
        }

        if ($null -ne $boot_device) {
            $cmdParams.BootDevice = $boot_device
        }

        New-VM @cmdParams | Out-Null
    }
    elseif ($state -eq "absent") {
        if (-not $vm) {
            $module.Result.state = "absent"
            $module.ExitJson()
        }

        $module.Result.changed = $true
        $module.Result.state = "absent"

        if ($module.CheckMode) {
            $module.ExitJson()
        }

        if ($vm.State -eq 'Running') {
            Stop-VM -Name $name -TurnOff -Force
        }

        Remove-VM -Name $name -Force
    }

    $module.ExitJson()
}
catch {
    $module.FailJson("Failed to manage VM: $($_.Exception.Message)")
}
