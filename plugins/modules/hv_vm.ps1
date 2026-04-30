#!powershell

# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.hyperv.plugins.module_utils.HyperV

$spec = @{
    options = @{
        name = @{ type = "str"; required = $true; aliases = @("vm_name") }
        generation = @{ type = "int"; default = 1; choices = @(1, 2) }
        memory_startup_bytes = @{ type = "raw" }
        boot_device = @{ type = "str"; choices = @("CD", "Floppy", "IDE", "LegacyNetworkAdapter", "NetworkAdapter", "VHD") }
        notes = @{ type = "str" }
        state = @{ type = "str"; default = "present"; choices = @("present", "absent") }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$name = $module.Params.name
$state = $module.Params.state
$notes = $module.Params.notes

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
            $changed = $false

            if (-not $vm) {
                $changed = $true
                if (-not $module.CheckMode) {
                    $cmdParams = @{ Name = $name }
                    $cmdParams += Get-HyperVParametersFromMap -PropertyMap $vmCreateMap -AnsibleParams $module.Params

                    New-VM @cmdParams | Out-Null
                    $vm = Get-VM -Name $name -ErrorAction Stop
                }
            }
            # Manage Notes (Tag-Safe)
            if ($module.Params.ContainsKey("notes")) {
                # Fetch current state including tags
                $currentNotesData = ConvertFrom-VMNote -VM $vm
                $currentRawNotes = $currentNotesData.Notes

                # Normalize null/empty notes to empty string, and standardize line endings for comparison
                $desiredRawNotes = if ($null -ne $notes) { $notes -replace "`r`n", "`n" } else { "" }
                $currentNormalized = if ($null -ne $currentRawNotes) { $currentRawNotes -replace "`r`n", "`n" } else { "" }

                if ($currentNormalized -ne $desiredRawNotes) {
                    $changed = $true
                    if (-not $module.CheckMode) {
                        $currentNotesData.Notes = $desiredRawNotes
                        $finalNoteString = ConvertTo-VMNote -NoteData $currentNotesData
                        Set-VM -VM $vm -Notes $finalNoteString -ErrorAction Stop | Out-Null
                    }
                }
            }
            $module.Result.changed = $changed
            $module.Result.state = "present"

            if ($module.CheckMode) {
                if ($module.Params.ContainsKey("notes")) {
                    $module.Result.notes = $notes
                }
                elseif ($vm) {
                    $module.Result.notes = (ConvertFrom-VMNote -VM $vm).Notes
                }
                $module.ExitJson()
            }

            # Refresh and Return
            $finalVm = Get-VM -Name $name
            $finalNotesData = ConvertFrom-VMNote -VM $finalVm
            $module.Result.notes = $finalNotesData.Notes
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
