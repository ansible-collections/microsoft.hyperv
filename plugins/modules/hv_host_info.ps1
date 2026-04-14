#!powershell

# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.hyperv.plugins.module_utils.HyperV

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

# Property Maps
$osMap = @(
    @{ Param = "caption"; Property = "Caption"; Type = "string" }
    @{ Param = "version"; Property = "Version"; Type = "string" }
)

$hvHostMap = @(
    @{ Param = "name"; Property = "Name"; Type = "string" }
    @{ Param = "logical_processor_count"; Property = "LogicalProcessorCount"; Type = "int" }
    @{ Param = "memory_capacity_bytes"; Property = "MemoryCapacity"; Type = "long" }
    @{ Param = "virtual_machine_path"; Property = "VirtualMachinePath"; Type = "string" }
    @{ Param = "virtual_hard_disk_path"; Property = "VirtualHardDiskPath"; Type = "string" }
    @{ Param = "supported_vm_versions"; Property = "SupportedVmVersions"; Type = "list" }
)

$vswitchMap = @(
    @{ Param = "name"; Property = "Name"; Type = "string" }
    @{ Param = "switch_type"; Property = "SwitchType"; Type = "enum" }
    @{ Param = "net_adapter_interface_description"; Property = "NetAdapterInterfaceDescription"; Type = "string" }
)

try {
    # 1. OS and Memory Information
    $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
    if ($osInfo) {
        Set-HyperVResultFromMap -PropertyMap $osMap -CurrentObject $osInfo -ModuleResult $result.os

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
        Set-HyperVResultFromMap -PropertyMap $hvHostMap -CurrentObject $vmHost -ModuleResult $result.hyperv
    }

    # 4. Virtual Switches
    $switches = @(Get-VMSwitch -ErrorAction SilentlyContinue)
    foreach ($vSwitch in $switches) {
        $switchDict = @{ id = $vSwitch.Id.ToString() }
        Set-HyperVResultFromMap -PropertyMap $vswitchMap -CurrentObject $vSwitch -ModuleResult $switchDict
        $result.virtual_switches += $switchDict
    }

    $module.Result.host_info = $result
    $module.ExitJson()
}
catch {
    $module.FailJson("Failed to gather Hyper-V host info: $($_.Exception.Message)")
}
