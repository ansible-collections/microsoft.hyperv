#!powershell

# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.hyperv.plugins.module_utils.HyperV

$spec = @{
    options = @{
        name = @{ type = "str"; required = $true }
        group_type = @{ type = "str"; default = "VMCollectionType"; choices = @("VMCollectionType", "ManagementCollectionType") }
        vm_members = @{ type = "list"; elements = "str" }
        group_members = @{ type = "list"; elements = "str" }
        state = @{ type = "str"; default = "present"; choices = @("present", "absent") }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$name = $module.Params.name
$group_type = $module.Params.group_type
$vm_members = $module.Params.vm_members
$group_members = $module.Params.group_members
$state = $module.Params.state

$module.Result.name = $name
$module.Result.group_type = $group_type

# Validation for conflicting parameters
if ($state -eq "present") {
    if ($group_type -eq "VMCollectionType" -and $null -ne $group_members) {
        $module.FailJson("Parameter 'group_members' is not valid when 'group_type' is 'VMCollectionType'.")
    }
    if ($group_type -eq "ManagementCollectionType" -and $null -ne $vm_members) {
        $module.FailJson("Parameter 'vm_members' is not valid when 'group_type' is 'ManagementCollectionType'.")
    }
}

try {
    # Check if group exists
    $group = Get-VMGroup -Name $name -ErrorAction SilentlyContinue
    $groupExists = ($null -ne $group)

    # Initialize current state variables early to prevent crashes in result formatting
    $currentVmNames = @()
    $currentGroupNames = @()
    if ($groupExists) {
        if ($group.VMMembers) {
            $currentVmNames = @($group.VMMembers.Name | Sort-Object)
        }
        if ($group.VMGroupMembers) {
            $currentGroupNames = @($group.VMGroupMembers.Name | Sort-Object)
        }
    }

    switch ($state) {
        "present" {
            $changed = $false
            if (-not $groupExists) {
                $changed = $true
                if ($module.CheckMode) {
                    $module.Result.changed = $true
                    if ($vm_members) { $module.Result.vm_members = $vm_members }
                    if ($group_members) { $module.Result.group_members = $group_members }
                    $module.ExitJson()
                }

                New-VMGroup -Name $name -GroupType $group_type -ErrorAction Stop | Out-Null
                $group = Get-VMGroup -Name $name -ErrorAction Stop
            }
            else {
                # Verify GroupType doesn't conflict
                if ($group.GroupType.ToString() -ne $group_type) {
                    $module.FailJson("A VM Group named '$name' already exists but with a different GroupType ($($group.GroupType.ToString())).")
                }
            }

            # Manage VM Members
            if ($group_type -eq "VMCollectionType" -and $module.Params.ContainsKey("vm_members")) {
                # Force to array, ensuring an empty list from Ansible clears the array
                $desiredVmNames = @()
                if ($null -ne $vm_members) {
                    $desiredVmNames = @($vm_members | Sort-Object)
                }

                $vmsToAdd = $desiredVmNames | Where-Object { $currentVmNames -notcontains $_ }
                $vmsToRemove = $currentVmNames | Where-Object { $desiredVmNames -notcontains $_ }

                if ($vmsToAdd -or $vmsToRemove) {
                    $changed = $true
                    if (-not $module.CheckMode) {
                        foreach ($vmName in $vmsToAdd) {
                            $vmObj = Get-VM -Name $vmName -ErrorAction Stop
                            Add-VMGroupMember -VMGroup $group -VM $vmObj -ErrorAction Stop
                        }
                        foreach ($vmName in $vmsToRemove) {
                            $vmObj = Get-VM -Name $vmName -ErrorAction Stop
                            Remove-VMGroupMember -VMGroup $group -VM $vmObj -ErrorAction Stop
                        }
                    }
                }
            }

            # Manage Group Members (Nested)
            if ($group_type -eq "ManagementCollectionType" -and $module.Params.ContainsKey("group_members")) {
                $desiredGroupNames = @()
                if ($null -ne $group_members) {
                    $desiredGroupNames = @($group_members | Sort-Object)
                }

                $groupsToAdd = $desiredGroupNames | Where-Object { $currentGroupNames -notcontains $_ }
                $groupsToRemove = $currentGroupNames | Where-Object { $desiredGroupNames -notcontains $_ }

                if ($groupsToAdd -or $groupsToRemove) {
                    $changed = $true
                    if (-not $module.CheckMode) {
                        foreach ($gName in $groupsToAdd) {
                            $nestedGroup = Get-VMGroup -Name $gName -ErrorAction Stop
                            Add-VMGroupMember -VMGroup $group -VMGroupMember $nestedGroup -ErrorAction Stop
                        }
                        foreach ($gName in $groupsToRemove) {
                            $nestedGroup = Get-VMGroup -Name $gName -ErrorAction Stop
                            Remove-VMGroupMember -VMGroup $group -VMGroupMember $nestedGroup -ErrorAction Stop
                        }
                    }
                }
            }

            $module.Result.changed = $changed

            # Refresh for return
            if ($module.CheckMode) {
                if ($group_type -eq "VMCollectionType") {
                    $module.Result.vm_members = if ($module.Params.ContainsKey("vm_members")) { @($desiredVmNames) } else { @($currentVmNames) }
                }
                else {
                    $module.Result.group_members = if ($module.Params.ContainsKey("group_members")) { @($desiredGroupNames) } else { @($currentGroupNames) }
                }
                $module.ExitJson()
            }

            $finalGroup = Get-VMGroup -Name $name
            if ($group_type -eq "VMCollectionType") {
                $module.Result.vm_members = if ($finalGroup.VMMembers) { @($finalGroup.VMMembers.Name) } else { @() }
            }
            else {
                $module.Result.group_members = if ($finalGroup.VMGroupMembers) { @($finalGroup.VMGroupMembers.Name) } else { @() }
            }
        }
        "absent" {
            if (-not $groupExists) {
                $module.Result.changed = $false
                $module.ExitJson()
            }

            $module.Result.changed = $true
            if ($module.CheckMode) {
                $module.ExitJson()
            }

            # Hyper-V requires groups to be empty before removal
            if ($group.VMMembers) {
                foreach ($vmMember in $group.VMMembers) {
                    Remove-VMGroupMember -VMGroup $group -VM $vmMember -ErrorAction Stop
                }
            }
            if ($group.VMGroupMembers) {
                foreach ($nestedGroup in $group.VMGroupMembers) {
                    Remove-VMGroupMember -VMGroup $group -VMGroupMember $nestedGroup -ErrorAction Stop
                }
            }

            Remove-VMGroup -VMGroup $group -Force -ErrorAction Stop | Out-Null
        }
    }

    $module.ExitJson()
}
catch {
    $module.FailJson("Failed to manage VM Group '$name': $($_.Exception.Message)")
}
