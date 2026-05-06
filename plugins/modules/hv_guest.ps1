#!powershell

# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
    options = @{
        vm_name = @{ type = "str"; required = $true; aliases = @("name") }
        guest_credential = @{ type = "dict"; required = $true; options = @{
                username = @{ type = "str"; required = $true }
                password = @{ type = "str"; required = $true; no_log = $true }
            }
        }
        action = @{ type = "str"; required = $true; choices = @("run", "copy_in", "copy_out") }
        script = @{ type = "str" }
        src = @{ type = "str" }
        dest = @{ type = "str" }
    }
    supports_check_mode = $false
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$vm_name = $module.Params.vm_name
$credDict = $module.Params.guest_credential
$action = $module.Params.action
$script = $module.Params.script
$src = $module.Params.src
$dest = $module.Params.dest

$module.Result.vm_name = $vm_name
$module.Result.action = $action

# Validation
if ($action -eq "run" -and ($null -eq $script -or $script -eq "")) {
    $module.FailJson("The 'script' parameter is required when 'action' is 'run'.")
}
if (($action -eq "copy_in" -or $action -eq "copy_out") -and ($null -eq $src -or $src -eq "" -or $null -eq $dest -or $dest -eq "")) {
    $module.FailJson("Both 'src' and 'dest' parameters are required for copy operations.")
}

# Check VM State
$vmObjs = @(Get-VM -Name $vm_name -ErrorAction SilentlyContinue)
if ($vmObjs.Count -eq 0) {
    $module.FailJson("Virtual Machine '$vm_name' not found.")
}
if ($vmObjs.Count -gt 1) {
    $module.FailJson("Ambiguous VM name: Multiple Virtual Machines found with name '$vm_name'. Please ensure VM names are unique.")
}
$vm = $vmObjs[0]

if ($vm.State -ne "Running") {
    $module.FailJson("Virtual Machine '$vm_name' must be in the 'Running' state to use PowerShell Direct.")
}

# Construct Credential Object
$secPass = ConvertTo-SecureString $credDict.password -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($credDict.username, $secPass)

switch ($action) {
    "run" {
        $scriptBlock = [scriptblock]::Create($script)

        try {
            # Execute over VMBus synchronously
            $outStr = ""
            $errStr = ""

            $result = Invoke-Command -VMName $vm_name -Credential $cred -ScriptBlock $scriptBlock -ErrorVariable errList -ErrorAction Stop

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
    }

    "copy_in" {
        if (-not (Test-Path -LiteralPath $src)) {
            $module.FailJson("Source path '$src' does not exist on the Hyper-V host.")
        }

        try {
            $session = New-PSSession -VMName $vm_name -Credential $cred -ErrorAction Stop

            # Check Idempotency for files. Directories will always return changed=$true.
            $isFile = (Test-Path -LiteralPath $src -PathType Leaf)
            if ($isFile) {
                $srcHash = (Get-FileHash -LiteralPath $src -Algorithm SHA256).Hash
                $destHash = Invoke-Command -Session $session -ScriptBlock {
                    if (Test-Path -LiteralPath $Using:dest -PathType Leaf) {
                        return (Get-FileHash -LiteralPath $Using:dest -Algorithm SHA256).Hash
                    }
                    return $null
                }

                if ($srcHash -eq $destHash) {
                    $module.Result.changed = $false
                }
                else {
                    Copy-Item -LiteralPath $src -Destination $dest -ToSession $session -Recurse -Force -ErrorAction Stop
                    $module.Result.changed = $true
                }
            }
            else {
                # It's a directory
                Copy-Item -LiteralPath $src -Destination $dest -ToSession $session -Recurse -Force -ErrorAction Stop
                $module.Result.changed = $true
            }
        }
        catch [System.Management.Automation.Remoting.PSRemotingTransportException], [System.Management.Automation.Remoting.PSRemotingDataStructureException] {
            if ($global:Error -contains $_) { $global:Error.Remove($_) }
            $friendlyMsg = "PowerShell Direct VMBus connection failed. The VM likely has no Operating System installed, " +
            "or Hyper-V Integration Services are not functioning. Technical Details: $($_.Exception.Message)"
            $module.FailJson($friendlyMsg)
        }
        catch {
            $module.FailJson("Failed to copy file into VM: $($_.Exception.Message)")
        }
        finally {
            if ($session) { Remove-PSSession -Session $session -ErrorAction SilentlyContinue }
        }
    }

    "copy_out" {
        try {
            $session = New-PSSession -VMName $vm_name -Credential $cred -ErrorAction Stop

            # Check if file exists inside guest first
            $existsInGuest = Invoke-Command -Session $session -ScriptBlock { Test-Path -LiteralPath $Using:src }
            if (-not $existsInGuest) {
                $module.FailJson("Source path '$src' does not exist inside the Guest OS.")
            }

            # Check Idempotency for files. Directories will always return changed=$true.
            $isFile = Invoke-Command -Session $session -ScriptBlock { Test-Path -LiteralPath $Using:src -PathType Leaf }
            if ($isFile) {
                $srcHash = Invoke-Command -Session $session -ScriptBlock {
                    return (Get-FileHash -LiteralPath $Using:src -Algorithm SHA256).Hash
                }

                $destHash = if (Test-Path -LiteralPath $dest -PathType Leaf) { (Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash } else { $null }

                if ($null -ne $srcHash -and $srcHash -eq $destHash) {
                    $module.Result.changed = $false
                }
                else {
                    Copy-Item -LiteralPath $src -Destination $dest -FromSession $session -Recurse -Force -ErrorAction Stop
                    $module.Result.changed = $true
                }
            }
            else {
                # It's a directory
                Copy-Item -LiteralPath $src -Destination $dest -FromSession $session -Recurse -Force -ErrorAction Stop
                $module.Result.changed = $true
            }
        }
        catch [System.Management.Automation.Remoting.PSRemotingTransportException], [System.Management.Automation.Remoting.PSRemotingDataStructureException] {
            if ($global:Error -contains $_) { $global:Error.Remove($_) }
            $friendlyMsg = "PowerShell Direct VMBus connection failed. The VM likely has no Operating System installed, " +
            "or Hyper-V Integration Services are not functioning. Technical Details: $($_.Exception.Message)"
            $module.FailJson($friendlyMsg)
        }
        catch {
            $module.FailJson("Failed to copy file out of VM: $($_.Exception.Message)")
        }
        finally {
            if ($session) { Remove-PSSession -Session $session -ErrorAction SilentlyContinue }
        }
    }
}
