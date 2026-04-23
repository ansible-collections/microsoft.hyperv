#!powershell

# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.hyperv.plugins.module_utils.HyperV

$spec = @{
    options = @{
        vm_name = @{ type = "str"; required = $true; aliases = @("name") }
        adapter_name = @{ type = "str"; required = $true }
        isolation_mode = @{ type = "str"; choices = @("None", "NativeVirtualSubnet", "ExternalVirtualSubnet", "Vlan") }
        default_isolation_id = @{ type = "int"; aliases = @("vsid") }
        multi_tenant_stack = @{ type = "str"; choices = @("On", "Off") }
        allow_untagged_traffic = @{ type = "str"; choices = @("On", "Off") }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$vm_name = $module.Params.vm_name
$adapter_name = $module.Params.adapter_name

$module.Result.vm_name = $vm_name
$module.Result.adapter_name = $adapter_name

# Property Map for Isolation configuration
# We use 'string' for multi_tenant_stack and allow_untagged_traffic because
# the HyperV.psm1 utility handles 'bool' via [bool] conversion which flips On(0)/Off(1) incorrectly.
$propertyMap = @(
    @{ Param = "isolation_mode"; Property = "IsolationMode"; Type = "enum" }
    @{ Param = "default_isolation_id"; Property = "DefaultIsolationID"; Type = "int" }
    @{ Param = "multi_tenant_stack"; Property = "MultiTenantStack"; Type = "string" }
    @{ Param = "allow_untagged_traffic"; Property = "AllowUntaggedTraffic"; Type = "string" }
)

try {
    $vm = Get-VM -Name $vm_name -ErrorAction SilentlyContinue
    if (-not $vm) {
        $module.FailJson("Virtual Machine '$vm_name' not found.")
    }

    $adapters = Get-VMNetworkAdapter -VMName $vm_name -Name $adapter_name -ErrorAction Stop
    if (-not $adapters) {
        $module.FailJson("Network Adapter '$adapter_name' not found on VM '$vm_name'.")
    }

    if ($adapters.Count -gt 1) {
        $module.FailJson("Multiple network adapters with name '$adapter_name' found on VM '$vm_name'. Please ensure adapter names are unique.")
    }

    $adapter = $adapters[0]

    $isolation = Get-VMNetworkAdapterIsolation -VMNetworkAdapter $adapter -ErrorAction Stop
    if (-not $isolation) {
        $module.FailJson("Failed to retrieve isolation settings for adapter '$adapter_name'.")
    }

    # Use utility function to detect changes
    $changed = Test-HyperVPropertiesChanged -PropertyMap $propertyMap -CurrentObject $isolation -AnsibleParams $module.Params
    $module.Result.changed = $changed

    if ($module.CheckMode) {
        # Forecast results using utility
        Set-HyperVResultFromMap -PropertyMap $propertyMap -CurrentObject $isolation -ModuleResult $module.Result

        # Override with requested values if provided, ensuring they are strings
        if ($null -ne $module.Params.isolation_mode) { $module.Result.isolation_mode = $module.Params.isolation_mode }
        if ($null -ne $module.Params.default_isolation_id) { $module.Result.default_isolation_id = $module.Params.default_isolation_id }
        if ($null -ne $module.Params.multi_tenant_stack) { $module.Result.multi_tenant_stack = $module.Params.multi_tenant_stack }
        if ($null -ne $module.Params.allow_untagged_traffic) { $module.Result.allow_untagged_traffic = $module.Params.allow_untagged_traffic }

        $module.ExitJson()
    }

    if ($changed) {
        # Build parameters using utility
        $setParams = Get-HyperVParametersFromMap -PropertyMap $propertyMap -AnsibleParams $module.Params
        $setParams.VMNetworkAdapter = $adapter

        Set-VMNetworkAdapterIsolation @setParams -ErrorAction Stop | Out-Null

        # Refresh object for final return
        $isolation = Get-VMNetworkAdapterIsolation -VMNetworkAdapter $adapter
    }

    # Populate final result using utility
    Set-HyperVResultFromMap -PropertyMap $propertyMap -CurrentObject $isolation -ModuleResult $module.Result

    $module.ExitJson()
}
catch {
    $module.FailJson("Failed to configure Isolation settings for adapter '$adapter_name' on VM '$vm_name': $($_.Exception.Message)")
}
