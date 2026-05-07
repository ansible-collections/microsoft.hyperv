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
        state = @{ type = "str"; default = "present"; choices = @("present", "absent") }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$name = $module.Params.name
$pool_type = $module.Params.pool_type
$state = $module.Params.state

$module.Result.name = $name
$module.Result.pool_type = $pool_type

try {
    # Check current status
    $pool = Get-VMResourcePool -Name $name -ResourcePoolType $pool_type -ErrorAction Ignore

    switch ($state) {
        "present" {
            if (-not $pool) {
                $module.Result.changed = $true
                if (-not $module.CheckMode) {
                    New-VMResourcePool -Name $name -ResourcePoolType $pool_type -ErrorAction Stop | Out-Null
                }
            }
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
