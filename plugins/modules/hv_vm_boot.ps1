#!powershell

# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
    options = @{
        name = @{ type = "str"; required = $true; aliases = @("vm_name") }
        secure_boot = @{ type = "bool" }
        secure_boot_template = @{ type = "str"; choices = @("MicrosoftWindows", "MicrosoftUEFICertificateAuthority", "OpenSourceShieldedVM") }
        num_lock = @{ type = "bool" }
        startup_order = @{ type = "list"; elements = "str"; choices = @("CD", "Floppy", "IDE", "LegacyNetworkAdapter") }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$name = $module.Params.name
$secure_boot = $module.Params.secure_boot
$secure_boot_template = $module.Params.secure_boot_template
$num_lock = $module.Params.num_lock
$startup_order = $module.Params.startup_order

$module.Result.name = $name

try {
    $vm = Get-VM -Name $name -ErrorAction SilentlyContinue

    if (-not $vm) {
        $module.FailJson("Virtual Machine '$name' not found.")
    }

    $gen = $vm.Generation
    $module.Result.generation = $gen
    $changed = $false

    if ($gen -eq 1) {
        if ($null -ne $secure_boot -or $null -ne $secure_boot_template) {
            $module.FailJson("secure_boot and secure_boot_template are only supported on Generation 2 Virtual Machines.")
        }

        $bios = Get-VMBios -VMName $name

        # NumLock
        if ($null -ne $num_lock) {
            $currentNumLock = [bool]$bios.NumLockEnabled
            if ($currentNumLock -ne $num_lock) {
                if (-not $module.CheckMode) {
                    if ($num_lock) {
                        Set-VMBios -VMName $name -EnableNumLock
                    }
                    else {
                        Set-VMBios -VMName $name -DisableNumLock
                    }
                }
                $changed = $true
            }
        }

        # StartupOrder
        if ($null -ne $startup_order) {
            $currentOrder = @($bios.StartupOrder | ForEach-Object { $_.ToString() })
            $reqOrder = @($startup_order)

            foreach ($item in $currentOrder) {
                if ($reqOrder -notcontains $item) {
                    $reqOrder += $item
                }
            }

            if (($currentOrder -join ",") -ne ($reqOrder -join ",")) {
                if (-not $module.CheckMode) {
                    Set-VMBios -VMName $name -StartupOrder $reqOrder
                }
                $changed = $true
            }
        }

        $bios = Get-VMBios -VMName $name
        $module.Result.num_lock = [bool]$bios.NumLockEnabled
        $module.Result.startup_order = @($bios.StartupOrder | ForEach-Object { $_.ToString() })

        if ($module.CheckMode) {
            if ($null -ne $num_lock) {
                $module.Result.num_lock = $num_lock
            }
            if ($null -ne $startup_order) {
                $module.Result.startup_order = $reqOrder
            }
        }
    }
    else {
        # Generation 2
        if ($null -ne $num_lock -or $null -ne $startup_order) {
            $module.FailJson("num_lock and startup_order are only supported on Generation 1 Virtual Machines.")
        }

        $fw = Get-VMFirmware -VMName $name

        # Secure Boot
        if ($null -ne $secure_boot) {
            $currentSecureBoot = ($fw.SecureBoot.ToString() -eq "On")
            if ($currentSecureBoot -ne $secure_boot) {
                if (-not $module.CheckMode) {
                    if ($secure_boot) {
                        Set-VMFirmware -VMName $name -EnableSecureBoot On
                    }
                    else {
                        Set-VMFirmware -VMName $name -EnableSecureBoot Off
                    }
                }
                $changed = $true
            }
        }

        # Secure Boot Template
        if ($null -ne $secure_boot_template) {
            $currentTemplate = $fw.SecureBootTemplate
            if ($currentTemplate -ne $secure_boot_template) {
                if (-not $module.CheckMode) {
                    Set-VMFirmware -VMName $name -SecureBootTemplate $secure_boot_template
                }
                $changed = $true
            }
        }

        $fw = Get-VMFirmware -VMName $name
        $module.Result.secure_boot = ($fw.SecureBoot.ToString() -eq "On")
        $module.Result.secure_boot_template = $fw.SecureBootTemplate

        if ($module.CheckMode) {
            if ($null -ne $secure_boot) {
                $module.Result.secure_boot = $secure_boot
            }
            if ($null -ne $secure_boot_template) {
                $module.Result.secure_boot_template = $secure_boot_template
            }
        }
    }

    $module.Result.changed = $changed

    $module.ExitJson()
}
catch {
    $module.FailJson("Failed to configure VM boot settings: $($_.Exception.Message)")
}
