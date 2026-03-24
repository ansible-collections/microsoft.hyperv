#!powershell

# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
    options = @{
        name = @{ type = "str"; required = $true }
        type = @{ type = "str"; default = "VHD"; choices = @("VHD", "ISO", "VFD") }
        paths = @{ type = "list"; elements = "str" }
        parent_name = @{ type = "str"; default = "Primordial" }
        state = @{ type = "str"; default = "present"; choices = @("present", "absent") }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$name = $module.Params.name
$poolType = $module.Params.type
$paths = $module.Params.paths
$parentName = $module.Params.parent_name
$state = $module.Params.state

$module.Result.name = $name
$module.Result.type = $poolType

try {
    # Check if pool exists
    $pool = Get-VMResourcePool -Name $name -ResourcePoolType $poolType -ErrorAction SilentlyContinue
    $poolExists = ($null -ne $pool)

    switch ($state) {
        "present" {
            $changed = $false
            if (-not $poolExists) {
                $changed = $true
                $module.Result.changed = $true
                $module.Result.paths = $paths

                if ($module.CheckMode) {
                    $module.ExitJson()
                }

                $newParams = @{
                    Name = $name
                    ResourcePoolType = $poolType
                }
                if ($null -ne $paths) { $newParams.Paths = $paths }
                if ($null -ne $parentName) { $newParams.ParentName = $parentName }

                New-VMResourcePool @newParams | Out-Null
            }
            else {
                # Pool exists, check for changes (Paths and ParentName)
                $setParams = @{
                    Name = $name
                    ResourcePoolType = $poolType
                }

                if ($null -ne $paths) {
                    $currentPaths = @($pool.Paths | Sort-Object)
                    $desiredPaths = @($paths | Sort-Object)
                    if (($currentPaths -join ",") -ne ($desiredPaths -join ",")) {
                        $setParams.Paths = $paths
                        $changed = $true
                    }
                }

                # ParentName is an array in the object, but usually has one element
                if ($null -ne $parentName -and $pool.ParentName -notcontains $parentName) {
                    $setParams.ParentName = $parentName
                    $changed = $true
                }

                $module.Result.changed = $changed
                if ($module.CheckMode) {
                    $module.Result.paths = if ($null -ne $paths) { $paths } else { $pool.Paths }
                    $module.ExitJson()
                }

                if ($changed) {
                    if ($null -ne $setParams.ParentName) {
                        Set-VMResourcePool @setParams | Out-Null
                    }

                    if ($null -ne $paths) {
                        $currentPaths = @($pool.Paths)
                        $desiredPaths = @($paths)

                        foreach ($dPath in $desiredPaths) {
                            if ($currentPaths -notcontains $dPath) {
                                Add-VMStoragePath -ResourcePoolName $name -ResourcePoolType $poolType -Path $dPath | Out-Null
                            }
                        }

                        foreach ($cPath in $currentPaths) {
                            if ($desiredPaths -notcontains $cPath) {
                                Remove-VMStoragePath -ResourcePoolName $name -ResourcePoolType $poolType -Path $cPath | Out-Null
                            }
                        }
                    }
                }
            }

            # Refresh for return data
            $finalPool = Get-VMResourcePool -Name $name -ResourcePoolType $poolType
            $module.Result.paths = @($finalPool.Paths)
        }
        "absent" {
            if (-not $poolExists) {
                $module.Result.changed = $false
                $module.ExitJson()
            }

            $module.Result.changed = $true
            if ($module.CheckMode) {
                $module.ExitJson()
            }

            Remove-VMResourcePool -Name $name -ResourcePoolType $poolType | Out-Null
        }
    }

    $module.ExitJson()
}
catch {
    $module.FailJson("Failed to manage VM resource pool: $($_.Exception.Message)")
}
