#!powershell

# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.hyperv.plugins.module_utils.HyperV

$spec = @{
    options = @{
        vm_name = @{ type = "str"; required = $true }
        path = @{ type = "str"; required = $true }
        controller_number = @{ type = "int" }
        controller_location = @{ type = "int" }
        state = @{ type = "str"; default = "present"; choices = @("present", "absent") }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$vm_name = $module.Params.vm_name
$path = $module.Params.path
$state = $module.Params.state
$controller_number = $module.Params.controller_number
$controller_location = $module.Params.controller_location

$module.Result.vm_name = $vm_name
$module.Result.path = $path
$module.Result.state = $state

# Property map for result mapping and basic matching
$propertyMap = @(
    @{ Param = "path"; Property = "Path"; Type = "string" }
    @{ Param = "controller_number"; Property = "ControllerNumber"; Type = "int" }
    @{ Param = "controller_location"; Property = "ControllerLocation"; Type = "int" }
)

try {
    $vm = Get-VM -Name $vm_name -ErrorAction SilentlyContinue
    if (-not $vm) {
        $module.FailJson("Virtual Machine '$vm_name' not found.")
    }

    # Normalize path for comparison
    $fullPath = (Get-Item -LiteralPath $path -ErrorAction SilentlyContinue).FullName
    if (-not $fullPath) {
        $fullPath = $path
    }

    # Find the hard disk drive
    $drives = Get-VMHardDiskDrive -VMName $vm_name -ErrorAction SilentlyContinue
    $existingDrive = $null

    if ($drives) {
        foreach ($drive in $drives) {
            if ($drive.Path -eq $fullPath) {
                $existingDrive = $drive
                break
            }
        }
    }

    switch ($state) {
        "present" {
            $changed = ($null -eq $existingDrive)

            if (-not $changed) {
                # Check for controller relocation
                if ($null -ne $controller_number -and $existingDrive.ControllerNumber -ne $controller_number) {

                    $changed = $true

                }
                if ($null -ne $controller_location -and $existingDrive.ControllerLocation -ne $controller_location) {

                    $changed = $true

                }
            }

            $module.Result.changed = $changed

            if ($module.CheckMode) {
                if ($changed) {
                    $module.Result.path = $fullPath
                    if ($null -ne $controller_number) {

                        $module.Result.controller_number = $controller_number

                    }
                    if ($null -ne $controller_location) {

                        $module.Result.controller_location = $controller_location

                    }
                }
                else {
                    Set-HyperVResultFromMap -PropertyMap $propertyMap -CurrentObject $existingDrive -ModuleResult $module.Result
                }
                $module.ExitJson()
            }

            if ($changed) {
                if ($null -ne $existingDrive) {
                    # Remove first to relocate
                    Remove-VMHardDiskDrive -VMHardDiskDrive $existingDrive | Out-Null
                }

                $addParams = @{
                    VMName = $vm_name
                    Path = $fullPath
                }
                if ($null -ne $controller_number) {

                    $addParams.ControllerNumber = $controller_number

                }
                if ($null -ne $controller_location) {

                    $addParams.ControllerLocation = $controller_location

                }

                $existingDrive = Add-VMHardDiskDrive @addParams -Passthru
            }

            Set-HyperVResultFromMap -PropertyMap $propertyMap -CurrentObject $existingDrive -ModuleResult $module.Result
        }
        "absent" {
            if (-not $existingDrive) {
                $module.Result.changed = $false
                $module.ExitJson()
            }

            $module.Result.changed = $true
            if ($module.CheckMode) {
                $module.ExitJson()
            }

            Remove-VMHardDiskDrive -VMHardDiskDrive $existingDrive | Out-Null
        }
    }

    $module.ExitJson()
}
catch {
    $module.FailJson("Failed to manage VM hard disk: $($_.Exception.Message)")
}
