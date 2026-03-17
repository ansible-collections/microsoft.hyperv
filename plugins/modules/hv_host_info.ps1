#!powershell

# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$result = @{
    changed = $false
    os = @{}
    memory = @{}
    processors = @()
    hyperv = @{}
    virtual_switches = @()
}

try {
    # 1. OS and Memory Information
    $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
    if ($osInfo) {
        $result.os.caption = $osInfo.Caption
        $result.os.version = $osInfo.Version

        $uptime = (Get-Date) - $osInfo.LastBootUpTime
        $result.os.uptime_seconds = [math]::Round($uptime.TotalSeconds)
        $result.os.last_boot_up_time = $osInfo.LastBootUpTime.ToString("o")

        $result.memory.total_bytes = [long]$osInfo.TotalVisibleMemorySize * 1KB
        $result.memory.free_bytes = [long]$osInfo.FreePhysicalMemory * 1KB
    }

    # 2. Processor Information
    $processors = Get-CimInstance -ClassName Win32_Processor -ErrorAction SilentlyContinue
    foreach ($cpu in $processors) {
        $result.processors += @{
            name = $cpu.Name
            cores = $cpu.NumberOfCores
            logical_processors = $cpu.NumberOfLogicalProcessors
        }
    }

    # 3. Hyper-V Host Configuration
    $vmHost = Get-VMHost -ErrorAction SilentlyContinue
    if ($vmHost) {
        $result.hyperv.name = $vmHost.Name
        $result.hyperv.logical_processor_count = $vmHost.LogicalProcessorCount
        $result.hyperv.memory_capacity_bytes = $vmHost.MemoryCapacity
        $result.hyperv.virtual_machine_path = $vmHost.VirtualMachinePath
        $result.hyperv.virtual_hard_disk_path = $vmHost.VirtualHardDiskPath
        $result.hyperv.supported_vm_versions = $vmHost.SupportedVmVersions
    }

    # 4. Virtual Switches
    $switches = Get-VMSwitch -ErrorAction SilentlyContinue
    if ($switches) {
        foreach ($vSwitch in @($switches)) {
            $switchDict = @{
                name = $vSwitch.Name
                id = $vSwitch.Id.ToString()
                switch_type = $vSwitch.SwitchType.ToString()
                net_adapter_interface_description = $vSwitch.NetAdapterInterfaceDescription
            }
            $result.virtual_switches += $switchDict
        }
    }

    $module.Result.host_info = $result
    $module.ExitJson()
}
catch {
    $module.FailJson("Failed to gather Hyper-V host info: $($_.Exception.Message)")
}
