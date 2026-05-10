#!powershell

# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.hyperv.plugins.module_utils.HyperV

$spec = @{
    options = @{
        vm_name = @{ type = "str"; required = $true }
        name = @{ type = "str"; required = $true }
        state = @{ type = "str"; default = "present"; choices = @("present", "absent", "reverted") }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$vm_name = $module.Params.vm_name
$name = $module.Params.name
$state = $module.Params.state

$module.Result.name = $name
$module.Result.vm_name = $vm_name
$module.Result.state = ""
$module.Result.checkpoint = $null

try {
    $vmObjs = @(Get-VM -Name $vm_name -ErrorAction Ignore)

    if ($vmObjs.Count -eq 0) {
        $global:Error.Clear(); $module.FailJson("Virtual Machine '$vm_name' not found.")
    }
    if ($vmObjs.Count -gt 1) {
        $global:Error.Clear()
        $module.FailJson("Ambiguous VM name: Multiple Virtual Machines found with name '$vm_name'. Please ensure VM names are unique.")
    }
    $vm = $vmObjs[0]

    $snapshot = Get-VMSnapshot -VMName $vm_name -Name $name -ErrorAction Ignore

    switch ($state) {
        "present" {
            if ($snapshot) {
                $module.Result.state = "present"
                $module.Result.checkpoint = @{
                    id = $snapshot.Id.ToString()
                    creation_time = $snapshot.CreationTime.ToString("o")
                    parent_id = if ($snapshot.ParentSnapshotId) {
                        $snapshot.ParentSnapshotId.ToString()
                    }
                    else {
                        $null
                    }
                }
                $module.ExitJson()
            }

            $module.Result.changed = $true
            $module.Result.state = "present"

            if ($module.CheckMode) {
                $module.ExitJson()
            }

            Checkpoint-VM -Name $vm_name -SnapshotName $name | Out-Null

            # Retry loop to handle Hyper-V snapshot registration delay
            $retryCount = 0
            $maxRetries = 10
            while ($retryCount -lt $maxRetries) {
                $snapshot = Get-VMSnapshot -VMName $vm_name -Name $name -ErrorAction Ignore
                if ($snapshot) {
                    break
                }
                Start-Sleep -Seconds 1
                $retryCount++
            }

            if (-not $snapshot) {
                $global:Error.Clear()
                $module.FailJson("Checkpoint was created but could not be retrieved from Hyper-V after $maxRetries seconds.")
            }
        }
        "absent" {
            if (-not $snapshot) {
                $module.Result.state = "absent"
                $module.ExitJson()
            }

            $module.Result.changed = $true
            $module.Result.state = "absent"

            if ($module.CheckMode) {
                $module.ExitJson()
            }

            Remove-VMSnapshot -VMName $vm_name -Name $name | Out-Null
            $module.ExitJson()
        }
        "reverted" {
            if (-not $snapshot) {
                $module.FailJson("Checkpoint '$name' not found on VM '$vm_name'. Cannot revert.")
            }

            $isReverted = ($vm.ParentSnapshotName -eq $name)
            if ($isReverted) {
                $module.Result.state = "reverted"
                $module.Result.checkpoint = @{
                    id = $snapshot.Id.ToString()
                    creation_time = $snapshot.CreationTime.ToString("o")
                }
                $module.ExitJson()
            }

            $module.Result.changed = $true
            $module.Result.state = "reverted"

            if ($module.CheckMode) {
                $module.Result.checkpoint = @{
                    id = $snapshot.Id.ToString()
                    creation_time = $snapshot.CreationTime.ToString("o")
                }
                $module.ExitJson()
            }

            Restore-VMSnapshot -VMName $vm_name -Name $name -Confirm:$false | Out-Null
        }
    }

    if ($snapshot) {
        $module.Result.checkpoint = @{
            id = $snapshot.Id.ToString()
            creation_time = $snapshot.CreationTime.ToString("o")
            parent_id = if ($snapshot.ParentSnapshotId) {
                $snapshot.ParentSnapshotId.ToString()
            }
            else {
                $null
            }
        }
    }

    $module.ExitJson()
}
catch {
    $global:Error.Clear(); $module.FailJson("Failed to manage VM Checkpoint: $($_.Exception.Message)")
}
