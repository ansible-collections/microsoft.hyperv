#!powershell

# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic

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
$TAG_PREFIX = "[AnsibleTag]"

Function ConvertFrom-VMNote {
    param ([string]$Notes)
    $parsedTags = @{}
    $nonTagNotes = @()

    if ([string]::IsNullOrWhiteSpace($Notes)) {
        return @{ Tags = $parsedTags; NonTags = $nonTagNotes }
    }

    $lines = $Notes -split "`r`n|`n"
    foreach ($line in $lines) {
        if ($line.StartsWith($TAG_PREFIX)) {
            $tagStr = $line.Substring($TAG_PREFIX.Length).Trim()
            $idx = $tagStr.IndexOf(":")
            if ($idx -gt 0) {
                $key = $tagStr.Substring(0, $idx).Trim()
                $value = $tagStr.Substring($idx + 1).Trim()
                $parsedTags[$key] = $value
            }
        }
        else {
            $nonTagNotes += $line
        }
    }
    return @{ Tags = $parsedTags; NonTags = $nonTagNotes }
}

Function ConvertTo-VMNote {
    param ([hashtable]$Tags, [array]$NonTags)
    $lines = @()
    if ($NonTags -and $NonTags.Count -gt 0) {
        $lines += $NonTags
    }

    # Sort keys for consistent output (idempotency)
    $keys = @($Tags.Keys | Sort-Object)
    foreach ($k in $keys) {
        $lines += "$TAG_PREFIX $($k): $($Tags[$k])"
    }

    return ($lines -join "`n")
}

try {
    $vm = Get-VM -Name $vm_name -ErrorAction SilentlyContinue
    if (-not $vm) {
        $module.FailJson("Virtual Machine '$vm_name' not found.")
    }

    $parsedData = ConvertFrom-VMNote -Notes $vm.Notes
    $currentTags = $parsedData.Tags
    $nonTags = $parsedData.NonTags

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

    $module.Result.changed = $changed
    $module.Result.tags = $newTags

    if ($module.CheckMode) {
        $module.ExitJson()
    }

    if ($changed) {
        $newNotesString = ConvertTo-VMNote -Tags $newTags -NonTags $nonTags
        Set-VM -VM $vm -Notes $newNotesString -ErrorAction Stop | Out-Null
    }

    $module.ExitJson()
}
catch {
    $module.FailJson("Failed to manage VM tags: $($_.Exception.Message)")
}
