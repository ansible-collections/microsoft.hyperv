#!powershell

# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.hyperv.plugins.module_utils.HyperV

$spec = @{
    options = @{
        vm_name = @{ type = "str"; required = $true; aliases = @("name") }
        number = @{ type = "int"; required = $true; choices = @(1, 2) }
        path = @{ type = "str" }
        debugger_mode = @{ type = "str"; choices = @("On", "Off") }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$vm_name = $module.Params.vm_name
$number = $module.Params.number

$module.Result.vm_name = $vm_name
$module.Result.number = $number

# Property Map for COM Port configuration
$propertyMap = @(
    @{ Param = "path"; Property = "Path"; Type = "string" }
    @{ Param = "debugger_mode"; Property = "DebuggerMode"; Type = "enum" }
)

try {
    $vm = Get-VM -Name $vm_name -ErrorAction SilentlyContinue
    if (-not $vm) {
        $module.FailJson("Virtual Machine '$vm_name' not found.")
    }

    $comPort = Get-VMComPort -VMName $vm_name -Number $number -ErrorAction SilentlyContinue
    if (-not $comPort) {
        $module.FailJson("COM Port $number not found on VM '$vm_name'.")
    }

    # Use utility function to detect changes
    $changed = Test-HyperVPropertiesChanged -PropertyMap $propertyMap -CurrentObject $comPort -AnsibleParams $module.Params
    $module.Result.changed = $changed

    if ($module.CheckMode) {
        # Forecast results using utility
        Set-HyperVResultFromMap -PropertyMap $propertyMap -CurrentObject $comPort -ModuleResult $module.Result
        # Override with requested values if changed
        if ($null -ne $module.Params.path) { $module.Result.path = $module.Params.path }
        if ($null -ne $module.Params.debugger_mode) { $module.Result.debugger_mode = $module.Params.debugger_mode }
        $module.ExitJson()
    }

    if ($changed) {
        # Build parameters using utility
        $setParams = Get-HyperVParametersFromMap -PropertyMap $propertyMap -AnsibleParams $module.Params
        $setParams.VMComPort = $comPort

        Set-VMComPort @setParams -ErrorAction Stop | Out-Null

        # Refresh object for final return
        $comPort = Get-VMComPort -VMName $vm_name -Number $number
    }

    # Populate final result using utility
    Set-HyperVResultFromMap -PropertyMap $propertyMap -CurrentObject $comPort -ModuleResult $module.Result

    $module.ExitJson()
}
catch {
    $module.FailJson("Failed to configure COM Port $number on VM '$vm_name': $($_.Exception.Message)")
}
