#!powershell

# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.hyperv.plugins.module_utils.HyperV

$spec = @{
    options = @{
        name = @{ type = "str"; required = $true }
        state = @{ type = "str"; default = "present"; choices = @("present", "absent") }
        switch_type = @{ type = "str"; choices = @("external", "internal", "private") }
        net_adapter_names = @{ type = "list"; elements = "str" }
        allow_management_os = @{ type = "bool" }
        enable_embedded_teaming = @{ type = "bool" }
        minimum_bandwidth_mode = @{ type = "str"; choices = @("None", "Absolute", "Weight", "Default") }
        default_flow_minimum_bandwidth_absolute = @{ type = "raw" }
        default_flow_minimum_bandwidth_weight = @{ type = "int" }
        notes = @{ type = "str" }
        extensions = @{ type = "list"; elements = "dict" }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$name = $module.Params.name
$state = $module.Params.state
$switch_type = $module.Params.switch_type
$net_adapter_names = $module.Params.net_adapter_names
$allow_management_os = $module.Params.allow_management_os
$enable_embedded_teaming = $module.Params.enable_embedded_teaming
$minimum_bandwidth_mode = $module.Params.minimum_bandwidth_mode
$default_flow_minimum_bandwidth_absolute = $module.Params.default_flow_minimum_bandwidth_absolute
$notes = $module.Params.notes
$extensions = $module.Params.extensions

if ($null -ne $default_flow_minimum_bandwidth_absolute) {
    $default_flow_minimum_bandwidth_absolute = Convert-ToByte -SizeString $default_flow_minimum_bandwidth_absolute
}

$module.Result.name = $name
$module.Result.state = $state

# Define the mapping between Ansible params and Hyper-V properties
$propertyMap = @(
    @{ Param = "notes"; Property = "Notes"; Type = "string" }
    @{ Param = "allow_management_os"; Property = "AllowManagementOS"; Type = "bool"; SwitchType = "External" }
    @{ Param = "minimum_bandwidth_mode"; Property = "MinimumBandwidthMode"; Type = "enum" }
    @{ Param = "default_flow_minimum_bandwidth_absolute"; Property = "DefaultFlowMinimumBandwidthAbsolute"; Type = "long" }
    @{ Param = "default_flow_minimum_bandwidth_weight"; Property = "DefaultFlowMinimumBandwidthWeight"; Type = "int" }
    @{ Param = "enable_embedded_teaming"; Property = "EmbeddedTeamingEnabled"; Type = "bool"; SwitchType = "External" }
    @{ Param = "net_adapter_names"; Property = "NetAdapterInterfaceDescriptions"; Type = "list"; SwitchType = "External" }
)

try {
    $vswitch = Get-VMSwitch -Name $name -ErrorAction SilentlyContinue

    if ($state -eq "absent") {
        if ($null -eq $vswitch) {
            $module.ExitJson()
        }

        $module.Result.changed = $true
        if ($module.CheckMode) {
            $module.ExitJson()
        }

        Remove-VMSwitch -Name $name -Force
        $module.ExitJson()
    }

    $changed = $false
    $creation_required = ($null -eq $vswitch)

    if ($creation_required) {
        $changed = $true
    }
    else {
        if ($null -ne $switch_type -and $vswitch.SwitchType.ToString().ToLower() -ne $switch_type.ToLower()) {
            $module.FailJson("Cannot change the switch_type of an existing virtual switch. Current type: $($vswitch.SwitchType)")
        }

        # Check for changes using propertyMap
        foreach ($map in $propertyMap) {
            $paramValue = $module.Params.($map.Param)
            if ($null -eq $paramValue) { continue }

            # Safety: Only process properties supported by this SwitchType
            if ($null -ne $map.SwitchType -and $vswitch.SwitchType.ToString() -ne $map.SwitchType) {
                continue
            }

            $currentValue = $vswitch.($map.Property)
            $isDifferent = $false

            switch ($map.Type) {
                "enum" { $isDifferent = ($currentValue.ToString() -ne $paramValue) }
                "string" { $isDifferent = ([string]$currentValue -ne [string]$paramValue) }
                "list" {
                    $currList = if ($currentValue) { @($currentValue | Sort-Object) } else { @() }
                    $desList = @($paramValue | Sort-Object)
                    $isDifferent = (($currList -join ",") -ne ($desList -join ","))
                }
                default { $isDifferent = ($currentValue -ne $paramValue) }
            }

            if ($isDifferent) {
                $changed = $true
                break
            }
        }

        if ($null -ne $extensions) {
            $current_extensions = @(Get-VMSwitchExtension -VMSwitchName $name)
            foreach ($ext_spec in $extensions) {
                $ext_name = $ext_spec.name
                $ext_state = $ext_spec.state
                $ext_obj = $current_extensions | Where-Object { $_.Name -eq $ext_name -or $_.Id -eq $ext_name }

                if ($null -eq $ext_obj) {
                    $module.FailJson("Extension '$ext_name' not found on switch '$name'.")
                }

                if ($ext_state -eq "enabled" -and -not $ext_obj.Enabled) {
                    $changed = $true
                }
                elseif ($ext_state -eq "disabled" -and $ext_obj.Enabled) {
                    $changed = $true
                }
            }
        }
    }

    $module.Result.changed = $changed

    if ($module.CheckMode) {
        if ($creation_required) {
            $module.Result.switch_type = $switch_type
        }
        else {
            $module.Result.switch_type = $vswitch.SwitchType.ToString()
        }
        $module.ExitJson()
    }

    if ($changed) {
        if ($creation_required) {
            $new_params = @{
                Name = $name
            }

            if ($null -ne $notes) {
                $new_params.Notes = $notes
            }

            if ($null -ne $minimum_bandwidth_mode) {
                $new_params.MinimumBandwidthMode = $minimum_bandwidth_mode
            }

            switch ($switch_type) {
                "external" {
                    if ($null -eq $net_adapter_names) {
                        $module.FailJson("Parameter 'net_adapter_names' is required for external switches.")
                    }
                    $new_params.NetAdapterName = $net_adapter_names
                    if ($null -ne $allow_management_os) {
                        $new_params.AllowManagementOS = $allow_management_os
                    }
                    if ($null -ne $enable_embedded_teaming) {
                        $new_params.EnableEmbeddedTeaming = $enable_embedded_teaming
                    }
                }
                "internal" {
                    $new_params.SwitchType = "Internal"
                }
                "private" {
                    $new_params.SwitchType = "Private"
                }
            }

            New-VMSwitch @new_params | Out-Null
            $vswitch = Get-VMSwitch -Name $name
        }
        else {
            $set_params = @{
                VMSwitch = $vswitch
            }

            # Build update parameters using propertyMap
            foreach ($map in $propertyMap) {
                $paramValue = $module.Params.($map.Param)
                if ($null -eq $paramValue) { continue }

                # Safety: Only apply properties supported by this SwitchType
                if ($null -ne $map.SwitchType -and $vswitch.SwitchType.ToString() -ne $map.SwitchType) {
                    continue
                }

                # Set-VMSwitch parameter naming matches our map.Property or a specific override
                $paramName = if ($map.Param -eq "net_adapter_names") { "NetAdapterName" } else { $map.Property }
                $set_params.($paramName) = $paramValue
            }

            if ($set_params.Count -gt 1) {
                Set-VMSwitch @set_params | Out-Null
            }
        }

        if ($null -ne $extensions) {
            $current_extensions = @(Get-VMSwitchExtension -VMSwitchName $name)
            foreach ($ext_spec in $extensions) {
                $ext_name = $ext_spec.name
                $ext_state = $ext_spec.state
                $ext_obj = $current_extensions | Where-Object { $_.Name -eq $ext_name -or $_.Id -eq $ext_name }

                if ($ext_state -eq "enabled" -and -not $ext_obj.Enabled) {
                    Enable-VMSwitchExtension -VMSwitchName $name -Name $ext_name | Out-Null
                }
                elseif ($ext_state -eq "disabled" -and $ext_obj.Enabled) {
                    Disable-VMSwitchExtension -VMSwitchName $name -Name $ext_name | Out-Null
                }
            }
        }
    }

    # Final result mapping
    $final_vswitch = Get-VMSwitch -Name $name -ErrorAction SilentlyContinue
    if ($null -ne $final_vswitch) {
        $module.Result.switch_type = "$($final_vswitch.SwitchType)"
        $module.Result.notes = [string]$final_vswitch.Notes
        $module.Result.allow_management_os = [bool]$final_vswitch.AllowManagementOS

        # Map enum to string explicitly to avoid empty strings for value 0
        $bw_mode = switch ([int]$final_vswitch.MinimumBandwidthMode) {
            0 { "None" }
            1 { "Absolute" }
            2 { "Weight" }
            3 { "Default" }
            default { $final_vswitch.MinimumBandwidthMode.ToString() }
        }
        $module.Result.minimum_bandwidth_mode = $bw_mode
    }

    $module.ExitJson()
}
catch {
    $module.FailJson("Failed to manage virtual switch: $($_.Exception.Message)")
}
