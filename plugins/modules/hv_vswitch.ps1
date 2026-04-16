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
    @{ Param = "switch_type"; Property = "SwitchType"; Type = "enum" }
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
        if ($null -eq $switch_type) {
            $module.FailJson("Parameter 'switch_type' is required when creating a new virtual switch.")
        }
        $changed = $true
    }
    else {
        $vType = $vswitch.SwitchType.ToString().ToLower()
        if ($null -ne $switch_type -and
            $vType -ne $switch_type.ToLower()) {
            $msg = "Cannot change switch_type. Current: $($vswitch.SwitchType)"
            $module.FailJson($msg)
        }

        $changed = Test-HyperVPropertiesChanged -PropertyMap $propertyMap -CurrentObject $vswitch `
            -AnsibleParams $module.Params -SwitchType $vswitch.SwitchType.ToString()

        if (-not $changed -and $null -ne $extensions) {
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
                    break
                }
                elseif ($ext_state -eq "disabled" -and $ext_obj.Enabled) {
                    $changed = $true
                    break
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
            Set-HyperVResultFromMap -PropertyMap $propertyMap -CurrentObject $vswitch -ModuleResult $module.Result
            # Override with desired state
            foreach ($map in $propertyMap) {
                $paramValue = $module.Params.($map.Param)
                if ($null -ne $paramValue) {
                    $module.Result.($map.Param) = $paramValue
                }
            }
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
            $set_params += Get-HyperVParametersFromMap -PropertyMap $propertyMap -AnsibleParams $module.Params -SwitchType $vswitch.SwitchType.ToString()

            # Special case for net_adapter_names mapping to NetAdapterName parameter
            if ($set_params.ContainsKey("NetAdapterInterfaceDescriptions")) {
                $set_params.NetAdapterName = $set_params.NetAdapterInterfaceDescriptions
                $set_params.Remove("NetAdapterInterfaceDescriptions")
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
        Set-HyperVResultFromMap -PropertyMap $propertyMap -CurrentObject $final_vswitch -ModuleResult $module.Result

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
