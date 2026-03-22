#!powershell

# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
    options = @{
        vm_name = @{ type = "str"; required = $true }
        path = @{ type = "str"; required = $true }
        state = @{ type = "str"; default = "present"; choices = @("present", "absent") }
        controller_type = @{ type = "str"; choices = @("IDE", "SCSI") }
        controller_number = @{ type = "int" }
        controller_location = @{ type = "int" }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$vm_name = $module.Params.vm_name
$path = $module.Params.path
$state = $module.Params.state
$controller_type = $module.Params.controller_type
$controller_number = $module.Params.controller_number
$controller_location = $module.Params.controller_location

$module.Result.vm_name = $vm_name
$module.Result.path = $path
$module.Result.state = $state

try {
    $vm = Get-VM -Name $vm_name -ErrorAction SilentlyContinue
    if (-not $vm) {
        $module.FailJson("Virtual Machine '$vm_name' not found.")
    }

    # Normalize path for comparison (Hyper-V usually returns absolute paths)
    $fullPath = $null
    if ($path) {
        $fullPath = (Get-Item -LiteralPath $path -ErrorAction SilentlyContinue).FullName
        if (-not $fullPath) {
            # VHD might not exist yet if being provisioned in the same playbook, but this module expects existing VHD.
            # However, for detachment we might not care if file is deleted already.
            $fullPath = $path
        }
    }

    # Get existing hard drives
    $drives = Get-VMHardDiskDrive -VMName $vm_name
    $existingDrive = $null
    foreach ($drive in $drives) {
        if ($drive.Path -eq $fullPath -or $drive.Path -eq $path) {
            $existingDrive = $drive
            break
        }
    }

    if ($state -eq "present") {
        if ($existingDrive) {
            $module.Result.controller_type = $existingDrive.ControllerType.ToString()
            $module.Result.controller_number = $existingDrive.ControllerNumber
            $module.Result.controller_location = $existingDrive.ControllerLocation

            # Check if it needs moving (if specific location requested)
            $needsMoving = $false
            if ($null -ne $controller_type -and $existingDrive.ControllerType.ToString() -ne $controller_type) { $needsMoving = $true }
            if ($null -ne $controller_number -and $existingDrive.ControllerNumber -ne $controller_number) { $needsMoving = $true }
            if ($null -ne $controller_location -and $existingDrive.ControllerLocation -ne $controller_location) { $needsMoving = $true }

            if (-not $needsMoving) {
                $module.ExitJson()
            }

            # If it needs moving, we'll remove and re-add in this implementation for simplicity
            # but usually you'd use Set-VMHardDiskDrive if it's the same controller type.
            $module.Result.changed = $true
            if ($module.CheckMode) {
                if ($null -ne $controller_type) { $module.Result.controller_type = $controller_type }
                if ($null -ne $controller_number) { $module.Result.controller_number = $controller_number }
                if ($null -ne $controller_location) { $module.Result.controller_location = $controller_location }
                $module.ExitJson()
            }

            Remove-VMHardDiskDrive -VMHardDiskDrive $existingDrive | Out-Null
        }
        else {
            $module.Result.changed = $true
            if ($module.CheckMode) {
                if ($null -ne $controller_type) { $module.Result.controller_type = $controller_type }
                if ($null -ne $controller_number) { $module.Result.controller_number = $controller_number }
                if ($null -ne $controller_location) { $module.Result.controller_location = $controller_location }
                $module.ExitJson()
            }
        }

        # Add the drive
        $addParams = @{
            VMName = $vm_name
            Path = $path
        }
        if ($null -ne $controller_type) { $addParams.ControllerType = $controller_type }
        if ($null -ne $controller_number) { $addParams.ControllerNumber = $controller_number }
        if ($null -ne $controller_location) { $addParams.ControllerLocation = $controller_location }

        Add-VMHardDiskDrive @addParams | Out-Null

        # Refresh result
        $drives = Get-VMHardDiskDrive -VMName $vm_name
        foreach ($drive in $drives) {
            if ($drive.Path -eq $fullPath -or $drive.Path -eq $path) {
                $module.Result.controller_type = $drive.ControllerType.ToString()
                $module.Result.controller_number = $drive.ControllerNumber
                $module.Result.controller_location = $drive.ControllerLocation
                break
            }
        }
    }
    elseif ($state -eq "absent") {
        if (-not $existingDrive) {
            $module.ExitJson()
        }

        $module.Result.changed = $true
        if ($module.CheckMode) {
            $module.ExitJson()
        }

        Remove-VMHardDiskDrive -VMHardDiskDrive $existingDrive | Out-Null
    }

    $module.ExitJson()
}
catch {
    $module.FailJson("Failed to manage VM hard disk: $($_.Exception.Message)")
}
