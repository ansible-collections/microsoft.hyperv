#!powershell

# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
    options = @{
        name = @{ type = "str"; aliases = @("vm_name") }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$name = $module.Params.name

$module.Result.vms = @()

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
        $vmDict = @{
            name = $vm.Name
            state = $vm.State.ToString()
            status = $vm.Status.ToString()
            uptime_seconds = [math]::Round($vm.Uptime.TotalSeconds)
            id = $vm.Id.ToString()
            generation = $vm.Generation
            MemoryStartup = $vm.MemoryStartup
            ProcessorCount = $vm.ProcessorCount
            ConfigurationLocation = $vm.ConfigurationLocation
            Path = $vm.Path
        }
        $vmlist += $vmDict
    }

    $module.Result.vms = $vmlist
    $module.ExitJson()
}
catch {
    $module.FailJson("Failed to gather VM info: $($_.Exception.Message)")
}
