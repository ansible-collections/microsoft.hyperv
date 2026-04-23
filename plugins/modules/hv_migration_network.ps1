#!powershell

# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.hyperv.plugins.module_utils.HyperV

$spec = @{
    options = @{
        subnet = @{ type = "str"; required = $true }
        priority = @{ type = "int" }
        state = @{ type = "str"; default = "present"; choices = @("present", "absent") }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$subnet = $module.Params.subnet
$state = $module.Params.state

$module.Result.subnet = $subnet

# Property Map for existing network configuration updates
$propertyMap = @(
    @{ Param = "priority"; Property = "Priority"; Type = "int" }
)

try {
    # Get the specific migration network by Subnet
    # VMMigrationNetwork uses the Subnet string as the unique identifier
    $network = Get-VMMigrationNetwork -Subnet $subnet -ErrorAction SilentlyContinue
    $networkExists = ($null -ne $network)

    switch ($state) {
        "present" {
            if (-not $networkExists) {
                # Needs to be created
                $changed = $true
                $module.Result.changed = $true

                if ($module.CheckMode) {
                    if ($null -ne $module.Params.priority) {
                        $module.Result.priority = $module.Params.priority
                    }
                    $module.ExitJson()
                }

                $addParams = @{
                    Subnet = $subnet
                    ErrorAction = "Stop"
                }
                if ($null -ne $module.Params.priority) {
                    $addParams.Priority = $module.Params.priority
                }

                Add-VMMigrationNetwork @addParams | Out-Null

                # Refresh object to return final state
                $network = Get-VMMigrationNetwork -Subnet $subnet -ErrorAction Stop
                Set-HyperVResultFromMap -PropertyMap $propertyMap -CurrentObject $network -ModuleResult $module.Result
            }
            else {
                # Network exists, check for property updates
                $changed = Test-HyperVPropertiesChanged -PropertyMap $propertyMap -CurrentObject $network -AnsibleParams $module.Params
                $module.Result.changed = $changed

                if ($module.CheckMode) {
                    Set-HyperVResultFromMap -PropertyMap $propertyMap -CurrentObject $network -ModuleResult $module.Result
                    if ($changed -and $null -ne $module.Params.priority) {
                        $module.Result.priority = $module.Params.priority
                    }
                    $module.ExitJson()
                }

                if ($changed) {
                    $setParams = Get-HyperVParametersFromMap -PropertyMap $propertyMap -AnsibleParams $module.Params
                    # Set-VMMigrationNetwork uses Subnet to target, but allows NewSubnet or NewPriority.
                    # We map Ansible 'priority' to 'NewPriority' for the Set command.
                    $mappedSetParams = @{
                        Subnet = $subnet
                        ErrorAction = "Stop"
                    }
                    if ($setParams.ContainsKey("Priority")) {
                        $mappedSetParams.NewPriority = $setParams.Priority
                    }

                    Set-VMMigrationNetwork @mappedSetParams | Out-Null

                    # Refresh
                    $network = Get-VMMigrationNetwork -Subnet $subnet -ErrorAction Stop
                }

                Set-HyperVResultFromMap -PropertyMap $propertyMap -CurrentObject $network -ModuleResult $module.Result
            }
        }
        "absent" {
            if (-not $networkExists) {
                $module.Result.changed = $false
                $module.ExitJson()
            }

            $module.Result.changed = $true
            if ($module.CheckMode) {
                $module.ExitJson()
            }

            Remove-VMMigrationNetwork -Subnet $subnet -ErrorAction Stop | Out-Null
        }
    }

    $module.ExitJson()
}
catch {
    $module.FailJson("Failed to manage Migration Network '$subnet': $($_.Exception.Message)")
}
