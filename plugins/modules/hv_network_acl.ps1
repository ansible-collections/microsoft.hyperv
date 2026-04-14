#!powershell

# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.hyperv.plugins.module_utils.HyperV

$spec = @{
    options = @{
        vm_name = @{ type = "str"; required = $true }
        adapter_name = @{ type = "str"; required = $true }
        state = @{ type = "str"; default = "present"; choices = @("present", "absent") }
        acl_type = @{ type = "str"; default = "standard"; choices = @("standard", "extended") }
        action = @{ type = "str"; choices = @("allow", "deny", "meter") }
        direction = @{ type = "str"; choices = @("inbound", "outbound", "both") }
        local_ip_address = @{ type = "str" }
        remote_ip_address = @{ type = "str" }
        local_mac_address = @{ type = "str" }
        remote_mac_address = @{ type = "str" }
        local_port = @{ type = "str" }
        remote_port = @{ type = "str" }
        protocol = @{ type = "str" }
        weight = @{ type = "int" }
        stateful = @{ type = "bool" }
        idle_session_timeout = @{ type = "int" }
        isolation_id = @{ type = "int" }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$vm_name = $module.Params.vm_name
$adapter_name = $module.Params.adapter_name
$state = $module.Params.state
$acl_type = $module.Params.acl_type
$action = $module.Params.action
$direction = $module.Params.direction
$weight = $module.Params.weight

$module.Result.acl_type = $acl_type
$module.Result.state = $state

# Helpers to normalize ANY
function Convert-AclString {
    param([string]$Value)
    if ([string]::IsNullOrEmpty($Value)) {
        return "ANY"
    }
    if ($Value.ToUpper() -eq "ANY") {
        return "ANY"
    }
    return $Value
}

try {
    # Ensure VM exists
    $vm = Get-VM -Name $vm_name -ErrorAction SilentlyContinue
    if (-not $vm) {
        $module.FailJson("Virtual Machine '$vm_name' not found.")
    }

    # Ensure Adapter exists
    $adapter = Get-VMNetworkAdapter -VMName $vm_name -Name $adapter_name -ErrorAction SilentlyContinue
    if (-not $adapter) {
        $module.FailJson("Network Adapter '$adapter_name' not found on VM '$vm_name'.")
    }

    # Map String Direction/Action to Int for exact comparison
    $dirMap = @{ "inbound" = 1; "outbound" = 2; "both" = 3 }
    $actMap = @{ "allow" = 1; "deny" = 2; "meter" = 3 }

    $reqDir = if ($direction) {
        $dirMap[$direction.ToLower()]
    }
    else {
        $null
    }
    $reqAct = if ($action) {
        $actMap[$action.ToLower()]
    }
    else {
        $null
    }

    # Property Maps
    $stdPropertyMap = @(
        @{ Param = "local_ip_address"; Property = "LocalAddress"; Type = "acl_string"; CmdletParam = "LocalIPAddress" }
        @{ Param = "remote_ip_address"; Property = "RemoteAddress"; Type = "acl_string"; CmdletParam = "RemoteIPAddress" }
        @{ Param = "local_mac_address"; Property = "LocalAddress"; Type = "acl_string"; CmdletParam = "LocalMacAddress" }
        @{ Param = "remote_mac_address"; Property = "RemoteAddress"; Type = "acl_string"; CmdletParam = "RemoteMacAddress" }
    )

    $extPropertyMap = @(
        @{ Param = "local_ip_address"; Property = "LocalIPAddress"; Type = "acl_string" }
        @{ Param = "remote_ip_address"; Property = "RemoteIPAddress"; Type = "acl_string" }
        @{ Param = "local_port"; Property = "LocalPort"; Type = "acl_string" }
        @{ Param = "remote_port"; Property = "RemotePort"; Type = "acl_string" }
        @{ Param = "protocol"; Property = "Protocol"; Type = "acl_string" }
        @{ Param = "stateful"; Property = "Stateful"; Type = "bool" }
        @{ Param = "idle_session_timeout"; Property = "IdleSessionTimeout"; Type = "int" }
        @{ Param = "isolation_id"; Property = "IsolationID"; Type = "int" }
    )

    if ($acl_type -eq "standard") {
        if ($action -eq "meter" -and $state -eq "present" -and
            $null -eq $module.Params.remote_ip_address -and $null -eq $module.Params.local_ip_address -and
            $null -eq $module.Params.remote_mac_address -and $null -eq $module.Params.local_mac_address) {
            $module.FailJson("Standard ACLs with action 'meter' require at least one IP or MAC parameter.")
        }

        $currentAcls = @(Get-VMNetworkAdapterAcl -VMNetworkAdapter $adapter)
        $targetAcl = $null

        $n_locIP = Convert-AclString $module.Params.local_ip_address
        $n_remIP = Convert-AclString $module.Params.remote_ip_address

        foreach ($c in $currentAcls) {
            if ([int]$c.Direction -eq $reqDir -and
                [int]$c.Action -eq $reqAct -and
                (Convert-AclString $c.LocalAddress) -eq $n_locIP -and
                (Convert-AclString $c.RemoteAddress) -eq $n_remIP) {
                $targetAcl = $c
                break
            }
        }

        if ($state -eq "present") {
            if ($null -eq $targetAcl) {
                $module.Result.changed = $true
                if (-not $module.CheckMode) {
                    $addParams = @{
                        VMNetworkAdapter = $adapter
                        Direction = $direction
                        Action = $action
                    }
                    $addParams += Get-HyperVParametersFromMap -PropertyMap $stdPropertyMap -AnsibleParams $module.Params

                    Add-VMNetworkAdapterAcl @addParams | Out-Null
                    $currentAcls = @(Get-VMNetworkAdapterAcl -VMNetworkAdapter $adapter)
                    $targetAcl = $currentAcls | Where-Object {
                        [int]$_.Direction -eq $reqDir -and [int]$_.Action -eq $reqAct -and
                        (Convert-AclString $_.LocalAddress) -eq $n_locIP -and
                        (Convert-AclString $_.RemoteAddress) -eq $n_remIP
                    }
                }
            }
            $module.Result.action = $action
            $module.Result.direction = $direction
        }
        else {
            if ($null -ne $targetAcl) {
                $module.Result.changed = $true
                if (-not $module.CheckMode) {
                    $removeParams = @{
                        VMNetworkAdapter = $adapter
                        Action = $action
                        Direction = $direction
                    }
                    $removeParams += Get-HyperVParametersFromMap -PropertyMap $stdPropertyMap -AnsibleParams $module.Params

                    Remove-VMNetworkAdapterAcl @removeParams | Out-Null
                }
            }
        }
    }
    elseif ($acl_type -eq "extended") {
        if ($action -eq "meter" -and $state -eq "present") {
            $module.FailJson("Extended ACLs do not support 'meter' action.")
        }
        if ($direction -eq "both" -and $state -eq "present") {
            $module.FailJson("Extended ACLs do not support 'both' direction.")
        }
        if ($null -eq $weight -and $state -eq "present") {
            $module.FailJson("Extended ACLs require the 'weight' parameter when state is present.")
        }
        if ($null -eq $weight -and $state -eq "absent") {
            $module.FailJson("Extended ACLs require the 'weight' parameter for removal when state is absent.")
        }
        if ($null -eq $direction -and $state -eq "absent") {
            $module.FailJson("Extended ACLs require the 'direction' parameter for removal when state is absent.")
        }

        $currentAcls = @(Get-VMNetworkAdapterExtendedAcl -VMNetworkAdapter $adapter)
        $targetAcl = $null
        foreach ($c in $currentAcls) {
            if ([int]$c.Direction -eq $reqDir -and $c.Weight -eq $weight) {
                $targetAcl = $c
                break
            }
        }

        if ($state -eq "present") {
            $needsUpdate = $false
            if ($null -eq $targetAcl) {
                $needsUpdate = $true
            }
            else {
                if ([int]$targetAcl.Action -ne $reqAct) {
                    $needsUpdate = $true
                }
                if (-not $needsUpdate) {
                    $needsUpdate = Test-HyperVPropertiesChanged -PropertyMap $extPropertyMap -CurrentObject $targetAcl -AnsibleParams $module.Params
                }
            }

            if ($needsUpdate) {
                $module.Result.changed = $true
                if (-not $module.CheckMode) {
                    if ($null -ne $targetAcl) {
                        Remove-VMNetworkAdapterExtendedAcl -VMNetworkAdapter $adapter -Direction $direction -Weight $weight | Out-Null
                    }

                    $addParams = @{
                        VMNetworkAdapter = $adapter
                        Direction = $direction
                        Action = $action
                        Weight = $weight
                    }
                    $addParams += Get-HyperVParametersFromMap -PropertyMap $extPropertyMap -AnsibleParams $module.Params
                    Add-VMNetworkAdapterExtendedAcl @addParams | Out-Null

                    $adapterAcls = Get-VMNetworkAdapterExtendedAcl -VMNetworkAdapter $adapter
                    $targetAcl = $adapterAcls | Where-Object { [int]$_.Direction -eq $reqDir -and $_.Weight -eq $weight }
                }
            }

            if ($targetAcl) {
                Set-HyperVResultFromMap -PropertyMap $extPropertyMap -CurrentObject $targetAcl -ModuleResult $module.Result
                $module.Result.action = $targetAcl.Action.ToString()
                $module.Result.direction = $targetAcl.Direction.ToString()
                $module.Result.weight = $targetAcl.Weight
            }
            elseif ($module.CheckMode) {
                # Fill check mode result from params
                $module.Result.action = $action
                $module.Result.direction = $direction
                $module.Result.weight = $weight
                foreach ($map in $extPropertyMap) {
                    $paramValue = $module.Params.($map.Param)
                    if ($null -ne $paramValue) {
                        $module.Result.($map.Param) = $paramValue
                    }
                }
            }
        }
        else {
            if ($null -ne $targetAcl) {
                $module.Result.changed = $true
                if (-not $module.CheckMode) {
                    Remove-VMNetworkAdapterExtendedAcl -VMNetworkAdapter $adapter -Direction $direction -Weight $weight | Out-Null
                }
            }
        }
    }

    $module.ExitJson()
}
catch {
    $module.FailJson("Failed to manage network ACL: $($_.Exception.Message)")
}
