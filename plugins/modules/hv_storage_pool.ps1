#!powershell

# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.hyperv.plugins.module_utils.HyperV

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

# Property Map for change detection
# Note: Paths are managed via Add/Remove-VMStoragePath, so not directly in Set-VMResourcePool
$propertyMap = @(
    @{ Param = "parent_name"; Property = "ParentName"; Type = "list" }
    @{ Param = "paths"; Property = "Paths"; Type = "list" }
)

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
                if ($null -ne $paths) {

                    $newParams.Paths = $paths

                }
                if ($null -ne $parentName) {

                    $newParams.ParentName = $parentName

                }

                New-VMResourcePool @newParams | Out-Null
            }
            else {
                # Pool exists, check for changes
                $changed = Test-HyperVPropertiesChanged -PropertyMap $propertyMap -CurrentObject $pool -AnsibleParams $module.Params

                $module.Result.changed = $changed
                if ($module.CheckMode) {
                    Set-HyperVResultFromMap -PropertyMap $propertyMap -CurrentObject $pool -ModuleResult $module.Result
                    # Override paths for check mode display
                    if ($null -ne $paths) {

                        $module.Result.paths = $paths

                    }
                    $module.ExitJson()
                }

                if ($changed) {
                    if ($null -ne $parentName -and $pool.ParentName -notcontains $parentName) {
                        Set-VMResourcePool -Name $name -ResourcePoolType $poolType -ParentName $parentName | Out-Null
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

            $finalPool = Get-VMResourcePool -Name $name -ResourcePoolType $poolType
            Set-HyperVResultFromMap -PropertyMap $propertyMap -CurrentObject $finalPool -ModuleResult $module.Result
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
