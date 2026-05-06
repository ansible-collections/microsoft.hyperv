#!powershell

# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.hyperv.plugins.module_utils.HyperV

$spec = @{
    options = @{
        vm_name = @{ type = "str"; required = $true; aliases = @("name") }
        guest_credential = @{ type = "dict"; required = $true; options = @{
                username = @{ type = "str"; required = $true }
                password = @{ type = "str"; required = $true; no_log = $true }
            }
        }
        script = @{ type = "str"; required = $true }
    }
    supports_check_mode = $false
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$vm_name = $module.Params.vm_name
$credDict = $module.Params.guest_credential
$script = $module.Params.script

$module.Result.vm_name = $vm_name

$cred = Get-HyperVGuestCredential -Module $module -VMName $vm_name -CredDict $credDict

$scriptBlock = [scriptblock]::Create($script)

try {
    # Execute over VMBus synchronously
    $outStr = ""
    $errStr = ""

    $result = Invoke-Command -VMName $vm_name -Credential $cred -ScriptBlock $scriptBlock -ErrorVariable errList

    if ($result) {
        $outStr = ($result | Out-String).Trim()
    }
    if ($errList) {
        $errStr = ($errList | Out-String).Trim()
    }

    $module.Result.stdout = $outStr
    $module.Result.stderr = $errStr

    $module.Result.changed = $true
}
catch [System.Management.Automation.Remoting.PSRemotingTransportException], [System.Management.Automation.Remoting.PSRemotingDataStructureException] {
    $transportErrorMsg = $_.Exception.Message

    # Critical Fix: Purge the problematic error record from the global error array
    # This prevents Ansible.Basic from encountering a parsing crash when examining the error stack.
    if ($global:Error -contains $_) {
        $global:Error.Remove($_)
    }

    $friendlyMsg = "PowerShell Direct VMBus connection failed. The VM likely has no Operating System installed, " +
    "or Hyper-V Integration Services are not functioning. Technical Details: $transportErrorMsg"
    $module.FailJson($friendlyMsg)
}
catch {
    $module.FailJson("Failed to execute script via PowerShell Direct: $($_.Exception.Message)")
}

$module.ExitJson()
