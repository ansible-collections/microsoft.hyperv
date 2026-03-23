#!powershell

# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
    options = @{
        vm_name = @{ type = "str"; required = $true }
        controller_number = @{ type = "int" }
        controller_location = @{ type = "int" }
        path = @{ type = "str" }
        state = @{ type = "str"; default = "present"; choices = @("present", "absent", "mounted", "ejected") }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$vm_name = $module.Params.vm_name
$controller_number = $module.Params.controller_number
$controller_location = $module.Params.controller_location
$path = $module.Params.path
$state = $module.Params.state

if ($state -eq "mounted" -and $null -eq $path) {
    $module.FailJson("The 'path' parameter is required when state is 'mounted'.")
}

$module.Result.vm_name = $vm_name

try {
    $vm = Get-VM -Name $vm_name -ErrorAction SilentlyContinue
    if (-not $vm) {
        $module.FailJson("Virtual Machine '$vm_name' not found.")
    }

    # Normalize path if provided
    $fullPath = $null
    if ($null -ne $path -and $state -ne "absent" -and $state -ne "ejected") {
        $fullPath = (Get-Item -LiteralPath $path -ErrorAction SilentlyContinue).FullName
        if (-not $fullPath) {
            # Let Hyper-V handle the path validation if we can't resolve it locally (e.g. UNC paths)
            $fullPath = $path
        }
    }

    # Find the specific DVD drive
    $drives = Get-VMDvdDrive -VMName $vm_name -ErrorAction SilentlyContinue
    $existingDrive = $null

    if ($drives) {
        if ($null -ne $controller_number -and $null -ne $controller_location) {
            foreach ($drive in $drives) {
                if ($drive.ControllerNumber -eq $controller_number -and $drive.ControllerLocation -eq $controller_location) {
                    $existingDrive = $drive
                    break
                }
            }
        }
        elseif ($null -ne $path) {
            # If no controller location specified, try to find by path
            foreach ($drive in $drives) {
                if ($drive.Path -eq $fullPath -or $drive.Path -eq $path) {
                    $existingDrive = $drive
                    break
                }
            }
        }
        else {
            # Default to the first DVD drive found if nothing specific is provided
            $existingDrive = $drives[0]
        }
    }

    switch ($state) {
        "absent" {
            if (-not $existingDrive) {
                $module.Result.state = "absent"
                $module.Result.changed = $false
                $module.ExitJson()
            }

            $module.Result.changed = $true
            $module.Result.state = "absent"

            if ($module.CheckMode) {
                $module.ExitJson()
            }

            Remove-VMDvdDrive -VMDvdDrive $existingDrive | Out-Null
        }
        "ejected" {
            if (-not $existingDrive) {
                $module.FailJson("No DVD Drive found to eject on VM '$vm_name'.")
            }

            $changed = ($null -ne $existingDrive.Path -and $existingDrive.Path -ne "")
            $module.Result.changed = $changed
            $module.Result.state = "ejected"
            $module.Result.path = $null
            $module.Result.controller_number = $existingDrive.ControllerNumber
            $module.Result.controller_location = $existingDrive.ControllerLocation

            if ($changed) {
                if ($module.CheckMode) {
                    $module.ExitJson()
                }

                Set-VMDvdDrive -VMDvdDrive $existingDrive -Path $null | Out-Null
            }
        }
        default {
            # Handle 'present' and 'mounted'
            $changed = $false
            $addRequired = ($null -eq $existingDrive)

            if ($addRequired) {
                $changed = $true
            }
            else {
                # Check path differences
                if ($state -eq "mounted" -or ($state -eq "present" -and $null -ne $path)) {
                    if ($existingDrive.Path -ne $fullPath -and $existingDrive.Path -ne $path) {
                        $changed = $true
                    }
                }
            }

            $module.Result.changed = $changed
            $module.Result.state = $state

            if ($module.CheckMode) {
                if ($addRequired) {
                    if ($null -ne $controller_number) { $module.Result.controller_number = $controller_number }
                    if ($null -ne $controller_location) { $module.Result.controller_location = $controller_location }
                }
                else {
                    $module.Result.controller_number = $existingDrive.ControllerNumber
                    $module.Result.controller_location = $existingDrive.ControllerLocation
                }

                if ($changed -and $null -ne $fullPath) {
                    $module.Result.path = $fullPath
                }
                elseif (-not $changed -and $existingDrive) {
                    $module.Result.path = $existingDrive.Path
                }
                $module.ExitJson()
            }

            if ($addRequired) {
                $addParams = @{ VMName = $vm_name }
                if ($null -ne $controller_number) { $addParams.ControllerNumber = $controller_number }
                if ($null -ne $controller_location) { $addParams.ControllerLocation = $controller_location }
                if ($null -ne $fullPath) { $addParams.Path = $fullPath }

                $existingDrive = Add-VMDvdDrive @addParams -Passthru
            }
            elseif ($changed) {
                Set-VMDvdDrive -VMDvdDrive $existingDrive -Path $fullPath | Out-Null
                # Refresh existingDrive object
                $existingDrive = Get-VMDvdDrive -VMName $vm_name | Where-Object { $_.ControllerNumber -eq $existingDrive.ControllerNumber -and $_.ControllerLocation -eq $existingDrive.ControllerLocation }
            }

            $module.Result.path = $existingDrive.Path
            $module.Result.controller_number = $existingDrive.ControllerNumber
            $module.Result.controller_location = $existingDrive.ControllerLocation
        }
    }

    $module.ExitJson()
}
catch {
    $module.FailJson("Failed to manage VM DVD Drive: $($_.Exception.Message)")
}
