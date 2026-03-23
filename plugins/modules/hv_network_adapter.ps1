#!powershell

# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.hyperv.plugins.module_utils.HyperV

$spec = @{
    options = @{
        vm_name = @{ type = "str"; required = $true }
        name = @{ type = "str"; default = "Network Adapter" }
        state = @{ type = "str"; default = "present"; choices = @("present", "absent") }
        switch_name = @{ type = "str" }
        vlan_mode = @{ type = "str"; choices = @("Access", "Trunk", "Untagged") }
        vlan_id = @{ type = "int" }
        native_vlan_id = @{ type = "int" }
        allowed_vlan_id_list = @{ type = "list"; elements = "int" }
        mac_address = @{ type = "str" }
        dynamic_mac_address = @{ type = "bool" }
        mac_address_spoofing = @{ type = "bool" }
        maximum_bandwidth = @{ type = "raw" }
        minimum_bandwidth_absolute = @{ type = "raw" }
        minimum_bandwidth_weight = @{ type = "int" }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$vm_name = $module.Params.vm_name
$name = $module.Params.name
$state = $module.Params.state
$switch_name = $module.Params.switch_name
$vlan_mode = $module.Params.vlan_mode
$vlan_id = $module.Params.vlan_id
$native_vlan_id = $module.Params.native_vlan_id
$allowed_vlan_id_list = $module.Params.allowed_vlan_id_list
$mac_address = $module.Params.mac_address
$dynamic_mac_address = $module.Params.dynamic_mac_address
$mac_address_spoofing = $module.Params.mac_address_spoofing
$maximum_bandwidth = $module.Params.maximum_bandwidth
$minimum_bandwidth_absolute = $module.Params.minimum_bandwidth_absolute
$minimum_bandwidth_weight = $module.Params.minimum_bandwidth_weight

# QoS conversion function (bps/Mbps/Gbps)
Function Convert-ToBandwidth {
    param($val)
    if ($val -isnot [string]) { return [long]$val }
    $str = $val.ToUpper().Trim()
    if ($str.EndsWith("GBPS")) { return [long]$str.Replace("GBPS", "") * 1GB }
    if ($str.EndsWith("MBPS")) { return [long]$str.Replace("MBPS", "") * 1MB }
    if ($str.EndsWith("KBPS")) { return [long]$str.Replace("KBPS", "") * 1KB }
    if ($str.EndsWith("BPS")) { return [long]$str.Replace("BPS", "") }
    return [long]$str
}

if ($null -ne $maximum_bandwidth) { $maximum_bandwidth = Convert-ToBandwidth $maximum_bandwidth }
if ($null -ne $minimum_bandwidth_absolute) { $minimum_bandwidth_absolute = Convert-ToBandwidth $minimum_bandwidth_absolute }

$module.Result.vm_name = $vm_name
$module.Result.name = $name

try {
    $vm = Get-VM -Name $vm_name -ErrorAction SilentlyContinue
    if (-not $vm) {
        $module.FailJson("Virtual Machine '$vm_name' not found.")
    }

    $adapter = Get-VMNetworkAdapter -VMName $vm_name -Name $name -ErrorAction SilentlyContinue

    switch ($state) {
        "present" {
            $changed = $false
            $addRequired = ($null -eq $adapter)

            if ($addRequired) {
                $changed = $true
            }
            else {
                # Check for changes in existing adapter
                if ($null -ne $switch_name -and $adapter.SwitchName -ne $switch_name) { $changed = $true }

                if ($null -ne $mac_address) {
                    $cleanMac = $mac_address.Replace(":", "").Replace("-", "").Replace(".", "")
                    if ($adapter.MacAddress -ne $cleanMac) { $changed = $true }
                }
                if ($null -ne $dynamic_mac_address -and [bool]$adapter.DynamicMacAddressEnabled -ne $dynamic_mac_address) {
                    $changed = $true
                }
                if ($null -ne $mac_address_spoofing) {
                    $currentSpoof = ($adapter.MacAddressSpoofing.ToString() -eq "On")
                    if ($currentSpoof -ne $mac_address_spoofing) { $changed = $true }
                }

                # Bandwidth Settings
                $bw = $adapter.BandwidthSetting
                if ($null -ne $maximum_bandwidth -and $bw.MaximumBandwidth -ne $maximum_bandwidth) { $changed = $true }
                if ($null -ne $minimum_bandwidth_absolute -and $bw.MinimumBandwidthAbsolute -ne $minimum_bandwidth_absolute) { $changed = $true }
                if ($null -ne $minimum_bandwidth_weight -and $bw.MinimumBandwidthWeight -ne $minimum_bandwidth_weight) { $changed = $true }

                # Check VLAN changes
                $vs = $adapter.VlanSetting
                if ($null -ne $vlan_mode) {
                    if ($vs.OperationMode.ToString() -ne $vlan_mode) { $changed = $true }
                    if ($vlan_mode -eq "Access" -and $vs.AccessVlanId -ne $vlan_id) { $changed = $true }
                    if ($vlan_mode -eq "Trunk") {
                        if ($vs.NativeVlanId -ne $native_vlan_id) { $changed = $true }
                        # Compare VLAN lists
                        $currentList = @()
                        if ($vs.AllowedVlanIdList) { $currentList = @($vs.AllowedVlanIdList | Sort-Object) }
                        $desiredList = @($allowed_vlan_id_list | Sort-Object)
                        if (($currentList -join ",") -ne ($desiredList -join ",")) { $changed = $true }
                    }
                }
            }

            $module.Result.changed = $changed

            if ($module.CheckMode) {
                if ($null -ne $switch_name) { $module.Result.switch_name = $switch_name }
                if ($null -ne $mac_address) { $module.Result.mac_address = $mac_address.Replace(":", "").Replace("-", "").Replace(".", "") }
                $module.ExitJson()
            }

            if ($changed) {
                if ($addRequired) {
                    $addParams = @{ VMName = $vm_name; Name = $name }
                    if ($null -ne $switch_name) { $addParams.SwitchName = $switch_name }
                    if ($null -ne $mac_address) { $addParams.StaticMacAddress = $mac_address }
                    if ($null -ne $dynamic_mac_address -and $dynamic_mac_address) { $addParams.DynamicMacAddress = $true }

                    $adapter = Add-VMNetworkAdapter @addParams -Passthru
                }

                # Apply Set-VMNetworkAdapter properties
                $setParams = @{ VMNetworkAdapter = $adapter }
                if ($null -ne $mac_address) { $setParams.StaticMacAddress = $mac_address }
                if ($null -ne $dynamic_mac_address) {
                    if ($dynamic_mac_address) { $setParams.DynamicMacAddress = $true }
                    else { $setParams.StaticMacAddress = $adapter.MacAddress }
                }
                if ($null -ne $mac_address_spoofing) {
                    if ($mac_address_spoofing) { $setParams.MacAddressSpoofing = "On" }
                    else { $setParams.MacAddressSpoofing = "Off" }
                }
                if ($null -ne $maximum_bandwidth) { $setParams.MaximumBandwidth = $maximum_bandwidth }
                if ($null -ne $minimum_bandwidth_absolute) { $setParams.MinimumBandwidthAbsolute = $minimum_bandwidth_absolute }
                if ($null -ne $minimum_bandwidth_weight) { $setParams.MinimumBandwidthWeight = $minimum_bandwidth_weight }

                if ($setParams.Count -gt 1) { Set-VMNetworkAdapter @setParams }

                # Handle Switch connection separately
                if ($null -ne $switch_name) {
                    if ($adapter.SwitchName -ne $switch_name) {
                        Connect-VMNetworkAdapter -VMNetworkAdapter $adapter -SwitchName $switch_name
                    }
                }

                # Apply VLAN settings
                if ($null -ne $vlan_mode) {
                    $vlanSetParams = @{ VMNetworkAdapter = $adapter }
                    if ($vlan_mode -eq "Access") { $vlanSetParams.Access = $true; $vlanSetParams.VlanId = $vlan_id }
                    elseif ($vlan_mode -eq "Trunk") {
                        $vlanSetParams.Trunk = $true
                        $vlanSetParams.NativeVlanId = $native_vlan_id
                        $vlanSetParams.AllowedVlanIdList = $allowed_vlan_id_list
                    }
                    elseif ($vlan_mode -eq "Untagged") { $vlanSetParams.Untagged = $true }

                    Set-VMNetworkAdapterVlan @vlanSetParams
                }

                $adapter = Get-VMNetworkAdapter -VMName $vm_name -Name $name
            }

            if ($adapter) {
                $module.Result.switch_name = $adapter.SwitchName
                $module.Result.mac_address = $adapter.MacAddress
            }
        }
        "absent" {
            if (-not $adapter) {
                $module.Result.changed = $false
                $module.ExitJson()
            }

            $module.Result.changed = $true
            if ($module.CheckMode) {
                $module.ExitJson()
            }

            Remove-VMNetworkAdapter -VMNetworkAdapter $adapter | Out-Null
        }
    }

    $module.ExitJson()
}
catch {
    $module.FailJson("Failed to manage VM network adapter: $($_.Exception.Message)")
}
