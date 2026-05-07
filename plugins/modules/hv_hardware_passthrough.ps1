#!powershell

# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
    options = @{
        vm_name = @{ type = "str"; required = $true; aliases = @("name") }
        device_type = @{ type = "str"; required = $true; choices = @("gpu_partition", "dda") }
        gpu_name = @{ type = "str" }
        partition_count = @{ type = "int" }
        device_location_path = @{ type = "str" }
        state = @{ type = "str"; default = "present"; choices = @("present", "absent") }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$vm_name = $module.Params.vm_name
$device_type = $module.Params.device_type
$device_location_path = $module.Params.device_location_path
$state = $module.Params.state

$module.Result.vm_name = $vm_name
$module.Result.device_type = $device_type
$module.Result.state = $state

try {
    # Check VM existence
    $vmObjs = @(Get-VM -Name $vm_name -ErrorAction Ignore)
    if ($vmObjs.Count -eq 0) {
        $global:Error.Clear(); $module.FailJson("Virtual Machine '$vm_name' not found.")
    }
    if ($vmObjs.Count -gt 1) {
        $global:Error.Clear()
        $module.FailJson("Ambiguous VM name: Multiple Virtual Machines found with name '$vm_name'. " +
            "Please ensure VM names are unique.")
    }
    $vm = $vmObjs[0]

    $changed = $false

    if ($device_type -eq "dda") {
        # --- DDA Logic ---
        $currentDevices = Get-VMAssignableDevice -VMName $vm_name -ErrorAction SilentlyContinue

        switch ($state) {
            "present" {
                if ($null -eq $device_location_path) {
                    $global:Error.Clear()
                    $module.FailJson("The 'device_location_path' parameter is required " +
                        "when 'device_type' is 'dda' and 'state' is 'present'.")
                }

                $match = $currentDevices | Where-Object { $_.LocationPath -eq $device_location_path }
                if (-not $match) {
                    if ($vm.State -ne 'Off') {
                        $global:Error.Clear()
                        $module.FailJson("The Virtual Machine '$vm_name' must be in the 'Off' state to add an assignable device.")
                    }
                    $changed = $true
                    if (-not $module.CheckMode) {
                        Add-VMAssignableDevice -VMName $vm_name -LocationPath $device_location_path -ErrorAction Stop
                    }
                }
            }
            "absent" {
                if ($null -ne $device_location_path) {
                    $match = $currentDevices | Where-Object { $_.LocationPath -eq $device_location_path }
                    if ($match) {
                        if ($vm.State -ne 'Off') {
                            $global:Error.Clear(); $module.FailJson("The Virtual Machine '$vm_name' must be in the 'Off' state to remove an assignable device.")
                        }
                        $changed = $true
                        if (-not $module.CheckMode) {
                            Remove-VMAssignableDevice -VMName $vm_name -LocationPath $device_location_path -ErrorAction Stop
                        }
                    }
                }
                elseif ($currentDevices) {
                    if ($vm.State -ne 'Off') {
                        $global:Error.Clear(); $module.FailJson("The Virtual Machine '$vm_name' must be in the 'Off' state to remove assignable devices.")
                    }
                    $changed = $true
                    if (-not $module.CheckMode) {
                        Remove-VMAssignableDevice -VMName $vm_name -ErrorAction Stop
                    }
                }
            }
        }
    }
    else {
        # --- GPU Partitioning Logic ---
        $currentGpuAdapters = Get-VMGpuPartitionAdapter -VMName $vm_name -ErrorAction SilentlyContinue

        switch ($state) {
            "present" {
                if (-not $currentGpuAdapters) {
                    if ($vm.State -ne 'Off') {
                        $global:Error.Clear(); $module.FailJson("The Virtual Machine '$vm_name' must be in the 'Off' state to add a GPU partition adapter.")
                    }
                    $changed = $true
                    if (-not $module.CheckMode) {
                        Add-VMGpuPartitionAdapter -VMName $vm_name -ErrorAction Stop
                    }
                }
                # Check for property changes if adapter exists
                # Note: GPU-P properties like partition count can be set, but often depend on the physical GPU.
                $partition_count = $module.Params.partition_count
                $gpu_name = $module.Params.gpu_name
                if ($null -ne $partition_count -or $null -ne $gpu_name) {
                    # Future implementation for property setting
                }
            }
            "absent" {
                if ($currentGpuAdapters) {
                    if ($vm.State -ne 'Off') {
                        $global:Error.Clear(); $module.FailJson("The Virtual Machine '$vm_name' must be in the 'Off' state to remove a GPU partition adapter.")
                    }
                    $changed = $true
                    if (-not $module.CheckMode) {
                        Remove-VMGpuPartitionAdapter -VMName $vm_name -ErrorAction Stop
                    }
                }
            }
        }
    }

    $module.Result.changed = $changed
    $module.ExitJson()
}
catch {
    $module.FailJson("Failed to manage hardware passthrough: $($_.Exception.Message)")
}
