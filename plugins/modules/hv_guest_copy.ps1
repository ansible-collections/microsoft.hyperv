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
        action = @{ type = "str"; required = $true; choices = @("copy_in", "copy_out") }
        src = @{ type = "str"; required = $true }
        dest = @{ type = "str"; required = $true }
    }
    supports_check_mode = $false
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$vm_name = $module.Params.vm_name
$credDict = $module.Params.guest_credential
$action = $module.Params.action
$src = $module.Params.src
$dest = $module.Params.dest

$module.Result.vm_name = $vm_name
$module.Result.action = $action

$cred = Get-HyperVGuestCredential -Module $module -VMName $vm_name -CredDict $credDict

switch ($action) {
    "copy_in" {
        if (-not (Test-Path -LiteralPath $src)) {
            $global:Error.Clear(); $module.FailJson("Source path '$src' does not exist on the Hyper-V host.")
        }

        try {
            $session = New-PSSession -VMName $vm_name -Credential $cred -ErrorAction Stop

            # Check Idempotency for files. Directories will always return changed=$true.
            $isFile = (Test-Path -LiteralPath $src -PathType Leaf)
            if ($isFile) {
                $srcHash = (Get-FileHash -LiteralPath $src -Algorithm SHA256).Hash
                $destHash = Invoke-Command -Session $session -ScriptBlock {
                    $target = $Using:dest
                    if (Test-Path -LiteralPath $target -PathType Container) {
                        $target = Join-Path $target (Split-Path $Using:src -Leaf)
                    }
                    if (Test-Path -LiteralPath $target -PathType Leaf) {
                        return (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
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
            $global:Error.Clear(); $module.FailJson("Failed to copy file into VM: $($_.Exception.Message)")
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
            $global:Error.Clear(); $module.FailJson("Failed to copy file out of VM: $($_.Exception.Message)")
        }
        finally {
            if ($session) { Remove-PSSession -Session $session -ErrorAction SilentlyContinue }
        }
    }
}

$module.ExitJson()
