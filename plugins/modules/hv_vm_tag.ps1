#!powershell

# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.hyperv.plugins.module_utils.HyperV

$spec = @{
    options = @{
        vm_name = @{ type = "str"; required = $true; aliases = @("name") }
        tags = @{ type = "dict"; required = $true }
        state = @{ type = "str"; default = "present"; choices = @("present", "absent", "exact") }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$vm_name = $module.Params.vm_name
$ansibleTags = $module.Params.tags
$state = $module.Params.state

$module.Result.vm_name = $vm_name

try {
    $vm = Get-VM -Name $vm_name -ErrorAction SilentlyContinue
    if (-not $vm) {
        $module.FailJson("Virtual Machine '$vm_name' not found.")
    }

    $parsedData = ConvertFrom-VMNote -VM $vm
    $currentTags = $parsedData.Tags
    $nonTags = $parsedData.Notes

    $changed = $false
    $newTags = $currentTags.Clone()

    switch ($state) {
        "present" {
            foreach ($key in $ansibleTags.Keys) {
                $val = [string]$ansibleTags[$key]
                if (-not $currentTags.ContainsKey($key) -or $currentTags[$key] -ne $val) {
                    $newTags[$key] = $val
                    $changed = $true
                }
            }
        }
        "absent" {
            foreach ($key in $ansibleTags.Keys) {
                if ($currentTags.ContainsKey($key)) {
                    $newTags.Remove($key)
                    $changed = $true
                }
            }
        }
        "exact" {
            # Check for additions/modifications
            foreach ($key in $ansibleTags.Keys) {
                $val = [string]$ansibleTags[$key]
                if (-not $currentTags.ContainsKey($key) -or $currentTags[$key] -ne $val) {
                    $newTags[$key] = $val
                    $changed = $true
                }
            }
            # Check for removals (tags in current that are NOT in ansibleTags)
            $keysToRemove = @()
            foreach ($key in $currentTags.Keys) {
                if (-not $ansibleTags.ContainsKey($key)) {
                    $keysToRemove += $key
                    $changed = $true
                }
            }
            foreach ($k in $keysToRemove) {
                $newTags.Remove($k)
            }
        }
    }

    # Also check if the notes field format needs correction (enforce empty line standard)
    $currentFullNotes = if ($null -ne $vm.Notes) { $vm.Notes } else { "" }
    $desiredFullNotes = ConvertTo-VMNote -NoteData @{ Tags = $newTags; Notes = $nonTags }

    $currentFullNormalized = $currentFullNotes -replace "`r`n", "`n"
    $desiredFullNormalized = $desiredFullNotes -replace "`r`n", "`n"

    if ($currentFullNormalized -ne $desiredFullNormalized) {
        $changed = $true
    }

    $module.Result.changed = $changed
    $module.Result.tags = $newTags

    if ($module.CheckMode) {
        $module.ExitJson()
    }

    if ($changed) {
        Set-VM -VM $vm -Notes $desiredFullNotes -ErrorAction Stop | Out-Null
    }

    $module.ExitJson()
}
catch {
    $module.FailJson("Failed to manage VM tags: $($_.Exception.Message)")
}
