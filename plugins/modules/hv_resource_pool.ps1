#!powershell

# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
    options = @{
        name = @{ type = "str"; required = $true }
        pool_type = @{
            type = "str"
            required = $true
            choices = @("Processor", "Memory", "Ethernet", "VHD", "ISO", "VFD", "FibreChannelConnection", "PciExpress")
        }
        parent_name = @{ type = "str" }
        paths = @{ type = "list"; elements = "str" }
        state = @{ type = "str"; default = "present"; choices = @("present", "absent") }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$name = $module.Params.name
$pool_type = $module.Params.pool_type
$parent_name = $module.Params.parent_name
$paths = $module.Params.paths
$state = $module.Params.state

$module.Result.name = $name
$module.Result.pool_type = $pool_type

try {
    # Check current status
    $pool = Get-VMResourcePool -Name $name -ResourcePoolType $pool_type -ErrorAction Ignore

    switch ($state) {
        "present" {
            $isChanged = $false
            if (-not $pool) {
                $isChanged = $true
                if (-not $module.CheckMode) {
                    $newParams = @{ Name = $name; ResourcePoolType = $pool_type; ErrorAction = "Stop" }
                    if ($null -ne $parent_name) { $newParams.ParentName = $parent_name }
                    if ($null -ne $paths) { $newParams.Paths = $paths }
                    New-VMResourcePool @newParams | Out-Null
                }
            }
            else {
                # Pool exists, verify properties
                if ($null -ne $parent_name -and $pool.ParentName -ne $parent_name) {
                    $isChanged = $true
                    if (-not $module.CheckMode) {
                        Set-VMResourcePool -Name $name -ResourcePoolType $pool_type -ParentName $parent_name -ErrorAction Stop
                    }
                }
                if ($null -ne $paths) {
                    $currentPaths = $pool.Paths | Sort-Object
                    $desiredPaths = $paths | Sort-Object
                    if (($currentPaths -join '|') -ne ($desiredPaths -join '|')) {
                        $isChanged = $true
                        if (-not $module.CheckMode) {
                            Set-VMResourcePool -Name $name -ResourcePoolType $pool_type -Paths $paths -ErrorAction Stop
                        }
                    }
                }
            }
            $module.Result.changed = $isChanged
            $module.Result.state = "present"
        }
        "absent" {
            if ($pool) {
                $module.Result.changed = $true
                if (-not $module.CheckMode) {
                    Remove-VMResourcePool -Name $name -ResourcePoolType $pool_type -ErrorAction Stop
                }
            }
            $module.Result.state = "absent"
        }
    }

    $module.ExitJson()
}
catch {
    $global:Error.Clear(); $module.FailJson("Failed to manage resource pool: $($_.Exception.Message)")
}
