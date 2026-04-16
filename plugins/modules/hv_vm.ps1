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

if ($null -ne $module.Params.memory_startup_bytes) {
    $module.Params.memory_startup_bytes = Convert-ToByte -SizeString $module.Params.memory_startup_bytes
}

$module.Result.name = $name

# Mapping for New-VM parameters
$vmCreateMap = @(
    @{ Param = "generation"; Property = "Generation" }
    @{ Param = "memory_startup_bytes"; Property = "MemoryStartupBytes" }
    @{ Param = "boot_device"; Property = "BootDevice" }
)

try {
    $vm = Get-VM -Name $name -ErrorAction SilentlyContinue

    switch ($state) {
        "present" {
            if ($vm) {
                $module.Result.state = "present"
                $module.ExitJson()
            }

            $module.Result.changed = $true
            $module.Result.state = "present"

            if ($module.CheckMode) {
                $module.ExitJson()
            }

            $cmdParams = @{ Name = $name }
            $cmdParams += Get-HyperVParametersFromMap -PropertyMap $vmCreateMap -AnsibleParams $module.Params

            New-VM @cmdParams | Out-Null
        }
        "absent" {
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
    }

    $module.ExitJson()
}
catch {
    $module.FailJson("Failed to manage VM: $($_.Exception.Message)")
}
