#!powershell

# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
    options = @{
        virtual_machine_path = @{ type = "str" }
        virtual_hard_disk_path = @{ type = "str" }
        numa_spanning_enabled = @{ type = "bool" }
        enable_enhanced_session_mode = @{ type = "bool" }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$virtual_machine_path = $module.Params.virtual_machine_path
$virtual_hard_disk_path = $module.Params.virtual_hard_disk_path
$numa_spanning_enabled = $module.Params.numa_spanning_enabled
$enable_enhanced_session_mode = $module.Params.enable_enhanced_session_mode

try {
    $hostConfig = Get-VMHost -ErrorAction SilentlyContinue

    if (-not $hostConfig) {
        $module.FailJson("Failed to retrieve Hyper-V host configuration.")
    }

    $changed = $false
    $cmdParams = @{}

    # Virtual Machine Path
    if ($null -ne $virtual_machine_path) {
        $currentVmPath = $hostConfig.VirtualMachinePath.TrimEnd("\")
        $requestedVmPath = $virtual_machine_path.TrimEnd("\")

        if ($currentVmPath -ne $requestedVmPath) {
            $cmdParams.VirtualMachinePath = $virtual_machine_path
            $changed = $true
        }
    }

    # Virtual Hard Disk Path
    if ($null -ne $virtual_hard_disk_path) {
        $currentVhdPath = $hostConfig.VirtualHardDiskPath.TrimEnd("\")
        $requestedVhdPath = $virtual_hard_disk_path.TrimEnd("\")

        if ($currentVhdPath -ne $requestedVhdPath) {
            $cmdParams.VirtualHardDiskPath = $virtual_hard_disk_path
            $changed = $true
        }
    }

    # NUMA Spanning
    if ($null -ne $numa_spanning_enabled) {
        $currentNuma = [bool]$hostConfig.NumaSpanningEnabled
        if ($currentNuma -ne $numa_spanning_enabled) {
            $cmdParams.NumaSpanningEnabled = $numa_spanning_enabled
            $changed = $true
        }
    }

    # Enhanced Session Mode
    if ($null -ne $enable_enhanced_session_mode) {
        $currentEsm = [bool]$hostConfig.EnableEnhancedSessionMode
        if ($currentEsm -ne $enable_enhanced_session_mode) {
            $cmdParams.EnableEnhancedSessionMode = $enable_enhanced_session_mode
            $changed = $true
        }
    }

    if ($changed) {
        if (-not $module.CheckMode) {
            Set-VMHost @cmdParams | Out-Null
            $hostConfig = Get-VMHost -ErrorAction SilentlyContinue
        }
    }

    $module.Result.changed = $changed

    $propertyMap = @(
        @{ Name = 'virtual_machine_path'; Current = $hostConfig.VirtualMachinePath; Desired = $virtual_machine_path }
        @{ Name = 'virtual_hard_disk_path'; Current = $hostConfig.VirtualHardDiskPath; Desired = $virtual_hard_disk_path }
        @{ Name = 'numa_spanning_enabled'; Current = [bool]$hostConfig.NumaSpanningEnabled; Desired = $numa_spanning_enabled }
        @{ Name = 'enable_enhanced_session_mode'; Current = [bool]$hostConfig.EnableEnhancedSessionMode; Desired = $enable_enhanced_session_mode }
    )

    foreach ($prop in $propertyMap) {
        # Set the baseline current state
        $module.Result.($prop.Name) = $prop.Current

        # Override with the desired state if in Check Mode, a change will happen, and a value was provided
        if ($module.CheckMode -and $changed -and $null -ne $prop.Desired) {
            $module.Result.($prop.Name) = $prop.Desired
        }
    }

    $module.ExitJson()
}
catch {
    $module.FailJson("Failed to configure Hyper-V host: $($_.Exception.Message)")
}
