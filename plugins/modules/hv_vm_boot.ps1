#!powershell

# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.hyperv.plugins.module_utils.HyperV

$spec = @{
    options = @{
        name = @{ type = "str"; required = $true; aliases = @("vm_name") }
        secure_boot = @{ type = "bool" }
        secure_boot_template = @{ type = "str"; choices = @("MicrosoftWindows", "MicrosoftUEFICertificateAuthority", "OpenSourceShieldedVM") }
        num_lock = @{ type = "bool" }
        startup_order = @{ type = "list"; elements = "str"; choices = @("CD", "Floppy", "IDE", "LegacyNetworkAdapter", "NetworkAdapter", "VHD") }
        boot_order = @{ type = "list"; elements = "str" }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$name = $module.Params.name

$module.Result.name = $name

# Property Maps
$gen1Map = @(
    @{ Param = "num_lock"; Property = "NumLockEnabled"; Type = "bool" }
)

try {
    $vm = Get-VM -Name $name -ErrorAction SilentlyContinue
    if (-not $vm) {
        $module.FailJson("Virtual Machine '$name' not found.")
    }

    $gen = $vm.Generation
    $module.Result.generation = $gen
    $changed = $false

    if ($gen -eq 1) {
        if ($null -ne $module.Params.secure_boot -or $null -ne $module.Params.secure_boot_template -or $null -ne $module.Params.boot_order) {
            $module.FailJson("secure_boot, secure_boot_template, and boot_order are only supported on Generation 2 Virtual Machines.")
        }

        $bios = Get-VMBios -VMName $name

        # Standard change detection for Gen1
        $changed = Test-HyperVPropertiesChanged -PropertyMap $gen1Map -CurrentObject $bios -AnsibleParams $module.Params

        # StartupOrder (Special list handling)
        if ($null -ne $module.Params.startup_order) {
            $currentOrder = @($bios.StartupOrder | ForEach-Object { $_.ToString() })
            $reqOrder = @($module.Params.startup_order)
            foreach ($item in $currentOrder) {
                if ($reqOrder -notcontains $item) {
                    $reqOrder += $item
                }
            }
            if (($currentOrder -join ",") -ne ($reqOrder -join ",")) {
                $changed = $true
            }
        }

        $module.Result.changed = $changed

        if ($changed -and -not $module.CheckMode) {
            if ($null -ne $module.Params.num_lock) {
                if ($module.Params.num_lock) {
                    Set-VMBios -VMName $name -EnableNumLock
                }
                else {
                    Set-VMBios -VMName $name -DisableNumLock
                }
            }
            if ($null -ne $module.Params.startup_order) {
                Set-VMBios -VMName $name -StartupOrder $reqOrder
            }
            $bios = Get-VMBios -VMName $name
        }

        Set-HyperVResultFromMap -PropertyMap $gen1Map -CurrentObject $bios -ModuleResult $module.Result
        $module.Result.startup_order = @($bios.StartupOrder | ForEach-Object { $_.ToString() })

        if ($module.CheckMode -and $changed) {
            if ($null -ne $module.Params.num_lock) {
                $module.Result.num_lock = $module.Params.num_lock
            }
            if ($null -ne $module.Params.startup_order) {
                $module.Result.startup_order = $reqOrder
            }
        }
    }
    else {
        # Generation 2
        if ($null -ne $module.Params.num_lock -or $null -ne $module.Params.startup_order) {
            $module.FailJson("num_lock and startup_order are only supported on Generation 1 Virtual Machines.")
        }

        $fw = Get-VMFirmware -VMName $name

        # Custom change detection for Gen2 because SecureBoot is an Enum string (On/Off)
        if ($null -ne $module.Params.secure_boot) {
            $curSB = ($fw.SecureBoot.ToString() -eq "On")
            if ($curSB -ne $module.Params.secure_boot) {
                $changed = $true
            }
        }
        if ($null -ne $module.Params.secure_boot_template -and $fw.SecureBootTemplate -ne $module.Params.secure_boot_template) {
            $changed = $true
        }

        # BootOrder detection
        if ($null -ne $module.Params.boot_order) {
            $currentBootOrder = $fw.BootOrder

            $desiredTypeOrder = @($module.Params.boot_order)
            $newBootOrder = @()

            # Pass 1: If 'File' is NOT explicitly requested, preserve any existing OS-injected 'File' entries at the top.
            if ($desiredTypeOrder -notcontains "File") {
                $fileMatches = $currentBootOrder | Where-Object { $_.BootType.ToString() -eq "File" -or $_.Description -like "*File*" }
                if ($fileMatches) {
                    $newBootOrder += @($fileMatches)
                }
            }

            # Pass 2: Append requested devices in exact order
            foreach ($type in $desiredTypeOrder) {
                if ($type -match "^SCSI:(\d+):(\d+)$") {
                    $controllerNum = [int]$matches[1]
                    $controllerLoc = [int]$matches[2]
                    $match = $currentBootOrder | Where-Object {
                        $_.Device.GetType().Name -eq 'HardDiskDrive' -and
                        $_.Device.ControllerNumber -eq $controllerNum -and
                        $_.Device.ControllerLocation -eq $controllerLoc
                    }
                    if ($match) {
                        $newBootOrder += @($match)
                    }
                }
                else {
                    $match = $currentBootOrder | Where-Object { $_.Description -like "*$type*" }
                    if ($match) {
                        $newBootOrder += @($match)
                    }
                }
            }

            # We DO NOT append unlisted standard devices (SCSI, DVD, Network). They are dropped.

            # Compare FirmwarePath for change
            $currPaths = @($currentBootOrder.FirmwarePath) -join ","
            $newPaths = @($newBootOrder.FirmwarePath) -join ","
            if ($currPaths -ne $newPaths) {
                $changed = $true
            }
        }

        $module.Result.changed = $changed

        if ($changed -and -not $module.CheckMode) {
            $fwParams = @{ VMName = $name }
            if ($null -ne $module.Params.secure_boot) {
                $fwParams.EnableSecureBoot = if ($module.Params.secure_boot) {
                    "On"
                }
                else {
                    "Off"
                }
            }
            if ($null -ne $module.Params.secure_boot_template) {
                $fwParams.SecureBootTemplate = $module.Params.secure_boot_template
            }
            if ($null -ne $module.Params.boot_order) {
                $fwParams.BootOrder = $newBootOrder
            }
            Set-VMFirmware @fwParams | Out-Null
            $fw = Get-VMFirmware -VMName $name
        }

        $module.Result.secure_boot = ($fw.SecureBoot.ToString() -eq "On")
        $module.Result.secure_boot_template = $fw.SecureBootTemplate

        # Return friendly types for boot_order
        $friendlyBootOrder = @()
        foreach ($device in $fw.BootOrder) {
            if ($device.Description -like "*Network*") {
                $friendlyBootOrder += "Network"
            }
            elseif ($device.Description -like "*SCSI*") {
                # Attempt to extract targeted SCSI info
                if ($device.Device -and $device.Device.GetType().Name -eq 'HardDiskDrive') {
                    $friendlyBootOrder += "SCSI:$($device.Device.ControllerNumber):$($device.Device.ControllerLocation)"
                }
                else {
                    $friendlyBootOrder += "SCSI"
                }
            }
            elseif ($device.Description -like "*DVD*") {
                $friendlyBootOrder += "DVD"
            }
            elseif ($device.Description -like "*File*") {
                $friendlyBootOrder += "File"
            }
            else {
                $friendlyBootOrder += $device.Description
            }
        }
        $module.Result.boot_order = $friendlyBootOrder

        if ($module.CheckMode -and $changed) {
            if ($null -ne $module.Params.secure_boot) {
                $module.Result.secure_boot = $module.Params.secure_boot
            }
            if ($null -ne $module.Params.secure_boot_template) {
                $module.Result.secure_boot_template = $module.Params.secure_boot_template
            }
            if ($null -ne $module.Params.boot_order) {
                $module.Result.boot_order = $module.Params.boot_order
            }
        }
    }

    $module.ExitJson()
}
catch {
    $module.FailJson("Failed to configure VM boot settings: $($_.Exception.Message)")
}
