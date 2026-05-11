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
    $vm = Get-VM -Name $vm_name -ErrorAction SilentlyContinue

    if (-not $vm) {
        $module.FailJson("Virtual Machine '$vm_name' not found.")
    }

    $snapshot = Get-VMSnapshot -VMName $vm_name -Name $name -ErrorAction SilentlyContinue

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
            $snapshot = Get-VMSnapshot -VMName $vm_name -Name $name
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
    $module.FailJson("Failed to manage VM Checkpoint: $($_.Exception.Message)")
}
