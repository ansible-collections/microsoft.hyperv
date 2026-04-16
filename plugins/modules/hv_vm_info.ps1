#!powershell

# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.hyperv.plugins.module_utils.HyperV

$spec = @{
    options = @{
        name = @{ type = "str"; aliases = @("vm_name") }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$name = $module.Params.name
$module.Result.vms = @()

$propertyMap = @(
    @{ Param = "name"; Property = "Name"; Type = "string" }
    @{ Param = "state"; Property = "State"; Type = "enum" }
    @{ Param = "status"; Property = "Status"; Type = "enum" }
    @{ Param = "generation"; Property = "Generation"; Type = "int" }
    @{ Param = "MemoryStartup"; Property = "MemoryStartup"; Type = "long" }
    @{ Param = "ProcessorCount"; Property = "ProcessorCount"; Type = "int" }
    @{ Param = "ConfigurationLocation"; Property = "ConfigurationLocation"; Type = "string" }
    @{ Param = "Path"; Property = "Path"; Type = "string" }
)

try {
    if ($name) {
        $vms = Get-VM -Name $name -ErrorAction SilentlyContinue
    }
    else {
        $vms = Get-VM -ErrorAction SilentlyContinue
    }

    if (-not $vms) {
        $module.ExitJson()
    }

    $vmlist = @()
    foreach ($vm in @($vms)) {
        $vmDict = @{}
        Set-HyperVResultFromMap -PropertyMap $propertyMap -CurrentObject $vm -ModuleResult $vmDict

        # Add special fields
        $vmDict.id = $vm.Id.ToString()
        $vmDict.uptime_seconds = [math]::Round($vm.Uptime.TotalSeconds)

        $vmlist += $vmDict
    }

    $module.Result.vms = $vmlist
    $module.ExitJson()
}
catch {
    $module.FailJson("Failed to gather VM info: $($_.Exception.Message)")
}
