#!powershell

# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
    options = @{
        name = @{ type = "str"; required = $true; aliases = @("vm_name") }
        state = @{ type = "str"; required = $true; choices = @("running", "stopped", "restarted", "paused", "saved") }
        force = @{ type = "bool"; default = $false }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$name = $module.Params.name
$state = $module.Params.state
$force = $module.Params.force

$module.Result.name = $name
$module.Result.state = ""

try {
    $vm = Get-VM -Name $name -ErrorAction SilentlyContinue

    if (-not $vm) {
        $module.FailJson("Virtual Machine '$name' not found.")
    }

    $currentState = $vm.State.ToString()
    $module.Result.state = $currentState

    $targetMap = @{
        'running' = 'Running'
        'stopped' = 'Off'
        'paused' = 'Paused'
        'saved' = 'Saved'
        'restarted' = 'Restart'
    }

    $targetHvState = $targetMap[$state]

    if ($state -ne 'restarted' -and $currentState -eq $targetHvState) {
        $module.ExitJson()
    }

    $module.Result.changed = $true

    if ($state -ne 'restarted') {
        $module.Result.state = $targetHvState
    }
    else {
        $module.Result.state = 'Running'
    }

    if ($module.CheckMode) {
        $module.ExitJson()
    }

    if ($state -eq 'running') {
        if ($currentState -eq 'Paused') {
            Resume-VM -Name $name
        }
        else {
            Start-VM -Name $name
        }
    }
    elseif ($state -eq 'stopped') {
        if ($force) {
            Stop-VM -Name $name -TurnOff
        }
        else {
            Stop-VM -Name $name
        }
    }
    elseif ($state -eq 'restarted') {
        if ($force) {
            Restart-VM -Name $name -Force
        }
        else {
            Restart-VM -Name $name
        }
    }
    elseif ($state -eq 'paused') {
        Suspend-VM -Name $name
    }
    elseif ($state -eq 'saved') {
        Save-VM -Name $name
    }

    $newVm = Get-VM -Name $name
    if ($newVm) {
        $module.Result.state = $newVm.State.ToString()
    }

    $module.ExitJson()
}
catch {
    $module.FailJson("Failed to change VM state: $($_.Exception.Message)")
}
