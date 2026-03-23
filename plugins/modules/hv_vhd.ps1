#!powershell

# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.hyperv.plugins.module_utils.HyperV

$spec = @{
    options = @{
        path = @{ type = "str"; required = $true }
        state = @{ type = "str"; default = "present"; choices = @("present", "absent", "mounted", "dismounted") }
        size_bytes = @{ type = "raw" }
        vhd_type = @{ type = "str"; default = "Dynamic"; choices = @("Dynamic", "Fixed", "Differencing") }
        parent_path = @{ type = "str" }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$path = $module.Params.path
$state = $module.Params.state
$size_bytes = $module.Params.size_bytes
$vhd_type = $module.Params.vhd_type
$parent_path = $module.Params.parent_path

if ($null -ne $size_bytes) {
    $size_bytes = Convert-ToByte -SizeString $size_bytes
}

$module.Result.path = $path
$module.Result.state = ""

try {
    # Check if VHD exists
    $vhd = Get-VHD -Path $path -ErrorAction SilentlyContinue
    $vhdExists = ($null -ne $vhd)

    switch ($state) {
        "present" {
            if (-not $vhdExists) {
                if ($null -eq $size_bytes -and $vhd_type -ne "Differencing") {
                    $module.FailJson("size_bytes is required to create a new VHD.")
                }
                if ($vhd_type -eq "Differencing" -and $null -eq $parent_path) {
                    $module.FailJson("parent_path is required to create a Differencing VHD.")
                }

                $module.Result.changed = $true
                $module.Result.state = "present"
                if ($null -ne $size_bytes) { $module.Result.size_bytes = $size_bytes }
                $module.Result.vhd_type = $vhd_type
                $module.Result.attached = $false

                if ($module.CheckMode) {
                    $module.ExitJson()
                }

                $cmdParams = @{
                    Path = $path
                }
                if ($vhd_type -eq "Dynamic") { $cmdParams.Dynamic = $true }
                elseif ($vhd_type -eq "Fixed") { $cmdParams.Fixed = $true }
                elseif ($vhd_type -eq "Differencing") {
                    $cmdParams.Differencing = $true
                    $cmdParams.ParentPath = $parent_path
                }

                if ($null -ne $size_bytes) { $cmdParams.SizeBytes = $size_bytes }

                $vhd = New-VHD @cmdParams -PassThru
                $module.Result.size_bytes = [long]$vhd.Size
                $module.Result.attached = [bool]$vhd.Attached
            }
            else {
                $changed = $false
                if ($null -ne $size_bytes) {
                    $currentSize = [long]$vhd.Size
                    if ($currentSize -lt $size_bytes) {
                        $changed = $true
                        if (-not $module.CheckMode) {
                            $vhd = Resize-VHD -Path $path -SizeBytes $size_bytes -PassThru
                        }
                    }
                    elseif ($currentSize -gt $size_bytes) {
                        $module.FailJson("Cannot shrink a VHD file. Current size ($currentSize) is greater than requested size ($size_bytes).")
                    }
                }

                $module.Result.changed = $changed
                $module.Result.state = "present"
                $module.Result.size_bytes = if ($module.CheckMode -and $changed) { $size_bytes } else { [long]$vhd.Size }
                $module.Result.vhd_type = $vhd.VhdType.ToString()
                $module.Result.attached = [bool]$vhd.Attached
            }
        }
        "absent" {
            if (-not $vhdExists) {
                $module.Result.state = "absent"
                $module.ExitJson()
            }

            if ($vhd.Attached) {
                $module.FailJson("Cannot delete VHD '$path' because it is currently mounted/attached. Dismount it first.")
            }

            $module.Result.changed = $true
            $module.Result.state = "absent"

            if ($module.CheckMode) {
                $module.ExitJson()
            }

            Remove-Item -LiteralPath $path -Force
        }
        "mounted" {
            if (-not $vhdExists) {
                $module.FailJson("VHD '$path' not found. Cannot mount.")
            }

            if ($vhd.Attached) {
                $module.Result.state = "mounted"
                $module.Result.size_bytes = [long]$vhd.Size
                $module.Result.vhd_type = $vhd.VhdType.ToString()
                $module.Result.attached = $true
                $module.ExitJson()
            }

            $module.Result.changed = $true
            $module.Result.state = "mounted"
            $module.Result.size_bytes = [long]$vhd.Size
            $module.Result.vhd_type = $vhd.VhdType.ToString()
            $module.Result.attached = $true

            if ($module.CheckMode) {
                $module.ExitJson()
            }

            Mount-VHD -Path $path | Out-Null
        }
        "dismounted" {
            if (-not $vhdExists) {
                $module.FailJson("VHD '$path' not found. Cannot dismount.")
            }

            if (-not $vhd.Attached) {
                $module.Result.state = "dismounted"
                $module.Result.size_bytes = [long]$vhd.Size
                $module.Result.vhd_type = $vhd.VhdType.ToString()
                $module.Result.attached = $false
                $module.ExitJson()
            }

            $module.Result.changed = $true
            $module.Result.state = "dismounted"
            $module.Result.size_bytes = [long]$vhd.Size
            $module.Result.vhd_type = $vhd.VhdType.ToString()
            $module.Result.attached = $false

            if ($module.CheckMode) {
                $module.ExitJson()
            }

            Dismount-VHD -Path $path | Out-Null
        }
    }

    $module.ExitJson()
}
catch {
    $module.FailJson("Failed to manage VHD: $($_.Exception.Message)")
}
