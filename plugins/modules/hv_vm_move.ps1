#!powershell

# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.hyperv.plugins.module_utils.HyperV

$spec = @{
    options = @{
        name = @{ type = "str"; required = $true; aliases = @("vm_name") }
        destination_host = @{ type = "str" }
        destination_storage_path = @{ type = "str" }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$name = $module.Params.name
$destHost = $module.Params.destination_host
$destPath = $module.Params.destination_storage_path

$module.Result.name = $name

# Property Map for return results (mapped from VM object properties or situational logic)
$propertyMap = @(
    @{ Param = "destination_host"; Property = "ComputerName"; Type = "string" }
    @{ Param = "destination_storage_path"; Property = "ConfigurationLocation"; Type = "string" }
)

try {
    $vm = Get-VM -Name $name -ErrorAction SilentlyContinue
    if (-not $vm) {
        $module.FailJson("Virtual Machine '$name' not found.")
    }

    $changed = $false

    if ($null -ne $destHost) {
        # Host-to-Host Migration
        $currentHost = $env:COMPUTERNAME
        if ($currentHost -eq $destHost) {
            Set-HyperVResultFromMap -PropertyMap $propertyMap -CurrentObject $vm -ModuleResult $module.Result
        }
        else {
            $changed = $true
            $module.Result.changed = $true

            if ($module.CheckMode) {
                $module.Result.destination_host = $destHost
                if ($null -ne $destPath) { $module.Result.destination_storage_path = $destPath }
                $module.ExitJson()
            }

            $moveParams = @{
                VM = $vm
                DestinationHost = $destHost
                ErrorAction = "Stop"
            }

            if ($null -ne $destPath) {
                $moveParams.IncludeStorage = $true
                $moveParams.DestinationStoragePath = $destPath
            }

            Move-VM @moveParams
            $module.Result.destination_host = $destHost
            if ($null -ne $destPath) { $module.Result.destination_storage_path = $destPath }
        }
    }
    elseif ($null -ne $destPath) {
        # Storage-Only Migration

        $currentPath = $vm.ConfigurationLocation
        $normCurrent = $currentPath.TrimEnd('\')
        $normDest = $destPath.TrimEnd('\')

        if ($normCurrent.StartsWith($normDest, [System.StringComparison]::InvariantCultureIgnoreCase)) {
            Set-HyperVResultFromMap -PropertyMap $propertyMap -CurrentObject $vm -ModuleResult $module.Result
        }
        else {
            $changed = $true
            $module.Result.changed = $true

            if ($module.CheckMode) {
                $module.Result.destination_storage_path = $destPath
                $module.Result.destination_host = $env:COMPUTERNAME
                $module.ExitJson()
            }

            if (-not (Test-Path -LiteralPath $destPath)) {
                New-Item -ItemType Directory -Path $destPath -Force -ErrorAction Stop | Out-Null
            }

            $moveParams = @{
                VM = $vm
                DestinationStoragePath = $destPath
                ErrorAction = "Stop"
            }
            if ($retainVhd) { $moveParams.RetainVhdCopiesOnSource = $true }

            Move-VMStorage @moveParams

            $vm = Get-VM -Name $name
            Set-HyperVResultFromMap -PropertyMap $propertyMap -CurrentObject $vm -ModuleResult $module.Result
        }
    }
    else {
        $module.FailJson("You must specify either 'destination_host' or 'destination_storage_path'.")
    }

    $module.ExitJson()
}
catch {
    $module.FailJson("Failed to move VM: $($_.Exception.Message)")
}
