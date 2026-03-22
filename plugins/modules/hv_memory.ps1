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
$dynamic_memory_enabled = $module.Params.dynamic_memory_enabled
$startup_bytes = $module.Params.startup_bytes
$minimum_bytes = $module.Params.minimum_bytes
$maximum_bytes = $module.Params.maximum_bytes
$buffer = $module.Params.buffer
$priority = $module.Params.priority

if ($null -ne $startup_bytes) { $startup_bytes = Convert-ToByte -SizeString $startup_bytes }
if ($null -ne $minimum_bytes) { $minimum_bytes = Convert-ToByte -SizeString $minimum_bytes }
if ($null -ne $maximum_bytes) { $maximum_bytes = Convert-ToByte -SizeString $maximum_bytes }

$module.Result.name = $name

try {
    $vm = Get-VM -Name $name -ErrorAction SilentlyContinue

    if (-not $vm) {
        $module.FailJson("Virtual Machine '$name' not found.")
    }

    $mem = Get-VMMemory -VMName $name -ErrorAction SilentlyContinue

    if (-not $mem) {
        $module.FailJson("Failed to retrieve memory configuration for VM '$name'.")
    }

    $changed = $false
    $cmdParams = @{
        VMName = $name
    }

    $propertyMap = @(
        @{ Name = 'dynamic_memory_enabled'; Current = [bool]$mem.DynamicMemoryEnabled; Desired = $dynamic_memory_enabled; CmdletParam = 'DynamicMemoryEnabled' }
        @{ Name = 'startup_bytes'; Current = [long]$mem.Startup; Desired = $startup_bytes; CmdletParam = 'StartupBytes' }
        @{ Name = 'minimum_bytes'; Current = [long]$mem.Minimum; Desired = $minimum_bytes; CmdletParam = 'MinimumBytes' }
        @{ Name = 'maximum_bytes'; Current = [long]$mem.Maximum; Desired = $maximum_bytes; CmdletParam = 'MaximumBytes' }
        @{ Name = 'buffer'; Current = [int]$mem.Buffer; Desired = $buffer; CmdletParam = 'Buffer' }
        @{ Name = 'priority'; Current = [int]$mem.Priority; Desired = $priority; CmdletParam = 'Priority' }
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
        if ($vm.State -ne 'Off' -and $null -ne $startup_bytes) {
            $module.FailJson("Cannot apply Memory changes (Startup Bytes) while the VM is not Off. Stop the VM first.")
        }

        # Handle Set-VMMemory dependency rules:
        # Minimum cannot be > Startup, Startup cannot be > Maximum
        # If changing multiple, it's safer to apply DynamicMemoryEnabled, Min/Max/Startup in one unified command
        # Hyper-V cmdlet handles the cross-property validation natively as long as all params are provided at once.
        Set-VMMemory @cmdParams | Out-Null

        $newMem = Get-VMMemory -VMName $name
        $module.Result.dynamic_memory_enabled = [bool]$newMem.DynamicMemoryEnabled
        $module.Result.startup_bytes = [long]$newMem.Startup
        $module.Result.minimum_bytes = [long]$newMem.Minimum
        $module.Result.maximum_bytes = [long]$newMem.Maximum
        $module.Result.buffer = [int]$newMem.Buffer
        $module.Result.priority = [int]$newMem.Priority
    }

    $module.ExitJson()
}
catch {
    $module.FailJson("Failed to manage VM Memory: $($_.Exception.Message)")
}
