#!powershell

# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.hyperv.plugins.module_utils.HyperV

$spec = @{
    options = @{
        name = @{ type = "str"; required = $true; aliases = @("vm_name") }
        timeout = @{ type = "int"; default = 300 }
        sleep_interval = @{ type = "int"; default = 5 }
        wait_for_ip = @{ type = "bool"; default = $true }
        expected_ip = @{ type = "str" }
        wait_for_heartbeat = @{ type = "bool"; default = $true }
        adapter_name = @{ type = "str" }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$name = $module.Params.name
$timeout = $module.Params.timeout
$sleep_interval = $module.Params.sleep_interval
$wait_for_ip = $module.Params.wait_for_ip
$expected_ip = $module.Params.expected_ip
$wait_for_heartbeat = $module.Params.wait_for_heartbeat
$adapter_name = $module.Params.adapter_name

$module.Result.name = $name
$module.Result.ip_addresses = @()
$module.Result.heartbeat = ""
$module.Result.state = ""

# Mapping for the final result
$resultMap = @(
    @{ Param = "heartbeat"; Property = "Heartbeat"; Type = "enum" }
    @{ Param = "state"; Property = "State"; Type = "enum" }
)

try {
    $startTime = Get-Date

    while ($true) {
        $vm = Get-VM -Name $name -ErrorAction SilentlyContinue
        if (-not $vm) {
            $module.FailJson("Virtual Machine '$name' not found.")
        }

        # Update Result info
        Set-HyperVResultFromMap -PropertyMap $resultMap -CurrentObject $vm -ModuleResult $module.Result

        # Get Adapters and IPs
        $adapterParams = @{ VMName = $name }
        if ($adapter_name) {
            $adapterParams.Name = $adapter_name
        }
        $adapters = @(Get-VMNetworkAdapter @adapterParams)

        $currentIps = @()
        foreach ($adapter in $adapters) {
            if ($adapter.IPAddresses) {
                $currentIps += @($adapter.IPAddresses)
            }
        }
        $module.Result.ip_addresses = $currentIps

        # Check conditions
        $heartbeatOk = if ($wait_for_heartbeat) {
            $vm.Heartbeat -eq "Ok"
        }
        else {
            $true
        }

        $ipOk = if ($wait_for_ip) {
            if ($expected_ip) {
                $matchFound = $false
                foreach ($ip in $currentIps) {
                    if (Test-IPInCidr -IP $ip -CIDR $expected_ip) {
                        $matchFound = $true
                        break
                    }
                }
                $matchFound
            }
            else {
                $currentIps.Count -gt 0
            }
        }
        else {
            $true
        }

        if ($heartbeatOk -and $ipOk) {
            break
        }

        # Check timeout
        $elapsed = (Get-Date) - $startTime
        if ($elapsed.TotalSeconds -ge $timeout) {
            $msg = "Timed out waiting for guest state after {0} seconds. Heartbeat: {1}. IPs: {2}" -f $timeout, $vm.Heartbeat, ($currentIps -join ",")
            $module.FailJson($msg)
        }

        if ($module.CheckMode) {
            $module.Result.changed = $false
            $module.ExitJson()
        }

        Start-Sleep -Seconds $sleep_interval
    }

    $module.ExitJson()
}
catch {
    $module.FailJson("Failed to wait for guest state: $($_.Exception.Message)")
}
