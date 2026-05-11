#!powershell

# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
    options = @{
        vm_name = @{ type = "str"; required = $true; aliases = @("name") }
        key_protector = @{ type = "str"; no_log = $true }
        shield_security_policy = @{ type = "bool" }
        encryption_state = @{ type = "str"; choices = @("encrypted", "supported") }
        state = @{ type = "str"; default = "enabled"; choices = @("enabled", "disabled") }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$vm_name = $module.Params.vm_name
$key_protector = $module.Params.key_protector
$shield_security_policy = $module.Params.shield_security_policy
$encryption_state = $module.Params.encryption_state
$state = $module.Params.state

$module.Result.vm_name = $vm_name
$module.Result.state = $state

try {
    # Check VM existence
    $vmObjs = @(Get-VM -Name $vm_name -ErrorAction Ignore)
    if ($vmObjs.Count -eq 0) {
        $global:Error.Clear(); $module.FailJson("Virtual Machine '$vm_name' not found.")
    }
    if ($vmObjs.Count -gt 1) {
        $global:Error.Clear(); $module.FailJson("Ambiguous VM name: Multiple Virtual Machines found with name '$vm_name'. Please ensure VM names are unique.")
    }
    $vm = $vmObjs[0]

    # Detect supported parameters to handle OS version differences (e.g. Server 2025)
    $cmd = Get-Command Set-VMSecurity
    $supportedParams = $cmd.Parameters.Keys

    # Fetch current security state
    $sec = Get-VMSecurity -VMName $vm_name -ErrorAction Stop
    $currentShielded = $sec.Shielded

    $currentEncryption = "None"
    if ($supportedParams -contains "EncryptState") {
        $currentEncryption = if ($null -ne $sec.EncryptState) { $sec.EncryptState.ToString() } else { "None" }
    }

    $currentEncryptTraffic = $null
    if ($supportedParams -contains "EncryptStateAndVmMigrationTraffic") {
        $currentEncryptTraffic = $sec.EncryptStateAndVmMigrationTraffic
    }

    # Fetch current Key Protector (Raw)
    $currentKP = Get-VMKeyProtector -VMName $vm_name -ErrorAction SilentlyContinue

    $changed = $false

    # 1. Handle State (Shielding)
    $desiredShielded = if ($null -ne $shield_security_policy) { $shield_security_policy } else { ($state -eq "enabled") }

    if ($state -eq "enabled") {
        if ($supportedParams -contains "Shielded") {
            if ($currentShielded -ne $desiredShielded) {
                if ($vm.State -ne 'Off') {
                    $global:Error.Clear()
                    $module.FailJson("The Virtual Machine '$vm_name' must be in the 'Off' state to modify security settings.")
                }
                $changed = $true
            }
        }

        # 2. Handle Encryption State
        if ($null -ne $encryption_state) {
            $desiredEncChanged = $false

            if ($supportedParams -contains "EncryptStateAndVmMigrationTraffic") {
                $desiredTraffic = ($encryption_state -eq "encrypted")
                if ($currentEncryptTraffic -ne $desiredTraffic) { $desiredEncChanged = $true }
            }
            elseif ($supportedParams -contains "EncryptState") {
                $desiredEncryption = if ($encryption_state -eq "encrypted") { "Encrypted" } else { "Supported" }
                if ($currentEncryption -ne $desiredEncryption) { $desiredEncChanged = $true }
            }

            if ($desiredEncChanged) {
                if ($vm.State -ne 'Off') {
                    $global:Error.Clear()
                    $module.FailJson("The Virtual Machine '$vm_name' must be in the " +
                        "'Off' state to modify security settings.")
                }
                $changed = $true
            }
        }

        # Handle Key Protector
        $kpBytes = $null
        if ($null -ne $key_protector) {
            $kpBytes = [System.Convert]::FromBase64String($key_protector)
            # Idempotency check for KP is hard with raw bytes.
            # We'll compare if possible or just assume change if provided and different from current state requirements.
            if (-not $currentKP) { $changed = $true }
        }

        if ($changed -and -not $module.CheckMode) {
            # 1. Apply Key Protector first if provided
            if ($null -ne $kpBytes) {
                Set-VMKeyProtector -VMName $vm_name -NewKeyProtector $kpBytes -ErrorAction Stop
            }

            # 2. Set Security Policy
            $secParams = @{ VMName = $vm_name }

            if ($supportedParams -contains "Shielded") {
                $secParams.Shielded = $desiredShielded
            }

            if ($null -ne $encryption_state) {
                if ($supportedParams -contains "EncryptState") {
                    $secParams.EncryptState = if ($encryption_state -eq "encrypted") { "Encrypted" } else { "Supported" }
                }
                elseif ($supportedParams -contains "EncryptStateAndVmMigrationTraffic") {
                    $secParams.EncryptStateAndVmMigrationTraffic = ($encryption_state -eq "encrypted")
                }
            }

            Set-VMSecurity @secParams -ErrorAction Stop
        }
    }
    elseif ($state -eq "disabled") {
        $needsDisable = $false
        if ($supportedParams -contains "Shielded" -and $currentShielded) { $needsDisable = $true }
        if ($supportedParams -contains "EncryptState" -and $currentEncryption -ne "None") { $needsDisable = $true }
        if ($supportedParams -contains "EncryptStateAndVmMigrationTraffic" -and $currentEncryptTraffic) { $needsDisable = $true }
        if ($currentKP) { $needsDisable = $true }

        if ($needsDisable) {
            if ($vm.State -ne 'Off') {
                $global:Error.Clear()
                $module.FailJson("The Virtual Machine '$vm_name' must be in the 'Off' state to modify security settings.")
            }
            $changed = $true
            if (-not $module.CheckMode) {
                $secParams = @{ VMName = $vm_name }
                if ($supportedParams -contains "Shielded") { $secParams.Shielded = $false }
                if ($supportedParams -contains "EncryptState") { $secParams.EncryptState = "None" }
                if ($supportedParams -contains "EncryptStateAndVmMigrationTraffic") { $secParams.EncryptStateAndVmMigrationTraffic = $false }
                Set-VMSecurity @secParams -ErrorAction Stop
            }
        }
    }

    $module.Result.changed = $changed
    $module.ExitJson()
}
catch {
    $module.FailJson("Failed to configure shielded VM: $($_.Exception.Message)")
}
