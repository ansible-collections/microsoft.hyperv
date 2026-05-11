#!powershell

# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
    options = @{
        vm_name = @{ type = "str"; required = $true; aliases = @("name") }
        state = @{ type = "str"; default = "enabled"; choices = @("enabled", "disabled") }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$vm_name = $module.Params.vm_name
$state = $module.Params.state

$module.Result.vm_name = $vm_name
$module.Result.state = $state

try {
    # Check VM existence
    $vmObjs = @(Get-VM -Name $vm_name -ErrorAction Ignore)
    if ($vmObjs.Count -eq 0) {
        $global:Error.Clear(); $module.FailJson("Virtual Machine '$vm_name' not found.")
    }
    if ($vmObjs.Count -gt 1) {
        $global:Error.Clear(); $module.FailJson("Ambiguous VM name: Multiple Virtual Machines found with name '$vm_name'. Please ensure VM names are unique.")
    }
    $vm = $vmObjs[0]

    # Fetch current processor state
    $proc = Get-VMProcessor -VMName $vm_name -ErrorAction Stop
    $currentExpose = $proc.ExposeVirtualizationExtensions

    # Fetch current network state (check all adapters, if any is off, we consider it inconsistent)
    $adapters = Get-VMNetworkAdapter -VMName $vm_name -ErrorAction Stop
    $currentMacSpoofing = if ($adapters) {
        $allOn = $true
        foreach ($a in $adapters) {
            if ($a.MacAddressSpoofing -ne 'On') { $allOn = $false; break }
        }
        if ($allOn) { "On" } else { "Off" }
    }
    else { "Off" }

    $desiredExpose = ($state -eq "enabled")
    $desiredMacSpoofing = if ($state -eq "enabled") { "On" } else { "Off" }

    $changed = $false

    # 1. Check Processor Change
    if ($currentExpose -ne $desiredExpose) {
        if ($vm.State -ne 'Off') {
            $global:Error.Clear()
            $module.FailJson("The Virtual Machine '$vm_name' must be in the 'Off' state " +
                "to change Processor Virtualization Extensions. Current state: $($vm.State)")
        }
        $changed = $true
        if (-not $module.CheckMode) {
            Set-VMProcessor -VMName $vm_name -ExposeVirtualizationExtensions $desiredExpose -ErrorAction Stop
        }
    }

    # 2. Check Network Change
    if ($currentMacSpoofing -ne $desiredMacSpoofing -and $adapters) {
        $changed = $true
        if (-not $module.CheckMode) {
            Set-VMNetworkAdapter -VMName $vm_name -MacAddressSpoofing $desiredMacSpoofing -ErrorAction Stop
        }
    }

    $module.Result.changed = $changed
    $module.ExitJson()
}
catch {
    $global:Error.Clear(); $module.FailJson("Failed to configure nested virtualization: $($_.Exception.Message)")
}
