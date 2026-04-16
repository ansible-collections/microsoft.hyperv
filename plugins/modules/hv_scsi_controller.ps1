#!powershell

# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.hyperv.plugins.module_utils.HyperV

$spec = @{
    options = @{
        vm_name = @{ type = "str"; required = $true }
        count = @{ type = "int"; required = $true }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$vm_name = $module.Params.vm_name
$count = $module.Params.count

$module.Result.vm_name = $vm_name
$module.Result.count = $count
$module.Result.controllers = @()

if ($count -lt 0 -or $count -gt 4) {
    $module.FailJson("Invalid count: $count. Hyper-V VMs support a maximum of 4 SCSI controllers (0-4).")
}

$propertyMap = @(
    @{ Param = "id"; Property = "Id"; Type = "string" }
    @{ Param = "controller_number"; Property = "ControllerNumber"; Type = "int" }
)

try {
    $vm = Get-VM -Name $vm_name -ErrorAction SilentlyContinue
    if (-not $vm) {
        $module.FailJson("Virtual Machine '$vm_name' not found.")
    }

    $currentControllers = @(Get-VMScsiController -VMName $vm_name -ErrorAction SilentlyContinue)
    $currentCount = $currentControllers.Count

    if ($currentCount -eq $count) {
        # Nothing to do, just map existing controllers to result
        foreach ($ctrl in $currentControllers) {
            $ctrlDict = @{}
            Set-HyperVResultFromMap -PropertyMap $propertyMap -CurrentObject $ctrl -ModuleResult $ctrlDict
            $module.Result.controllers += $ctrlDict
        }
        $module.ExitJson()
    }

    $module.Result.changed = $true
    if ($module.CheckMode) {
        $module.ExitJson()
    }

    if ($currentCount -lt $count) {
        # Add controllers
        $difference = $count - $currentCount
        for ($i = 0; $i -lt $difference; $i++) {
            Add-VMScsiController -VMName $vm_name | Out-Null
        }
    }
    elseif ($currentCount -gt $count) {
        # Remove controllers from highest number down
        $difference = $currentCount - $count
        $sortedControllers = $currentControllers | Sort-Object -Property ControllerNumber -Descending

        for ($i = 0; $i -lt $difference; $i++) {
            $ctrlToRemove = $sortedControllers[$i]
            Remove-VMScsiController -VMScsiController $ctrlToRemove | Out-Null
        }
    }

    # Refresh controllers to build return object
    $finalControllers = @(Get-VMScsiController -VMName $vm_name -ErrorAction SilentlyContinue)
    foreach ($ctrl in $finalControllers) {
        $ctrlDict = @{}
        Set-HyperVResultFromMap -PropertyMap $propertyMap -CurrentObject $ctrl -ModuleResult $ctrlDict
        $module.Result.controllers += $ctrlDict
    }

    $module.ExitJson()
}
catch {
    $module.FailJson("Failed to manage VM SCSI controllers: $($_.Exception.Message)")
}
