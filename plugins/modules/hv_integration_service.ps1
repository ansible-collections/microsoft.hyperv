#!powershell

# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.hyperv.plugins.module_utils.HyperV

$spec = @{
    options = @{
        vm_name = @{ type = "str"; required = $true; aliases = @("name") }
        service_name = @{ type = "str"; required = $true }
        state = @{ type = "str"; default = "enabled"; choices = @("enabled", "disabled") }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$vm_name = $module.Params.vm_name
$service_name = $module.Params.service_name
$state = $module.Params.state

$module.Result.vm_name = $vm_name
$module.Result.service_name = $service_name

# Property Map for Integration Service configuration
$propertyMap = @(
    @{ Param = "state"; Property = "Enabled"; Type = "bool" }
)

try {
    $vm = Get-VM -Name $vm_name -ErrorAction SilentlyContinue
    if (-not $vm) {
        $module.FailJson("Virtual Machine '$vm_name' not found.")
    }

    $service = Get-VMIntegrationService -VMName $vm_name -Name $service_name -ErrorAction SilentlyContinue
    if (-not $service) {
        $module.FailJson("Integration Service '$service_name' not found on VM '$vm_name'.")
    }

    # Convert the requested string state ("enabled"/"disabled") to a boolean for the standard utility
    $ansibleParams = $module.Params.Clone()
    $ansibleParams.state = ($state -eq "enabled")

    $changed = Test-HyperVPropertiesChanged -PropertyMap $propertyMap -CurrentObject $service -AnsibleParams $ansibleParams

    $module.Result.changed = $changed

    if ($module.CheckMode) {
        if ($changed) {
            $module.Result.state = $state
        }
        else {
            $module.Result.state = if ($service.Enabled) { "enabled" } else { "disabled" }
        }
        $module.ExitJson()
    }

    if ($changed) {
        if ($state -eq "enabled") {
            Enable-VMIntegrationService -VMName $vm_name -Name $service_name -ErrorAction Stop | Out-Null
        }
        else {
            Disable-VMIntegrationService -VMName $vm_name -Name $service_name -ErrorAction Stop | Out-Null
        }

        # Refresh object for final return
        $service = Get-VMIntegrationService -VMName $vm_name -Name $service_name
    }

    $module.Result.state = if ($service.Enabled) { "enabled" } else { "disabled" }

    $module.ExitJson()
}
catch {
    $module.FailJson("Failed to manage Integration Service '$service_name' on VM '$vm_name': $($_.Exception.Message)")
}
