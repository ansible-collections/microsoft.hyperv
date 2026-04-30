# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#Requires -Module Ansible.ModuleUtils.Legacy

<#
.SYNOPSIS
Converts a string with size suffixes (KB, MB, GB, TB) to its byte equivalent as a [long].

.DESCRIPTION
Takes a string such as '512MB' or '4GB' and calculates the exact number of bytes.
If a raw integer or string integer is provided without a suffix, it is cast directly to a [long].

.PARAMETER SizeString
The string or integer to convert.
#>
Function Convert-ToByte {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $SizeString
    )

    process {
        if ($SizeString -isnot [string]) {
            return [long]$SizeString
        }

        $memStr = $SizeString.ToUpper().Trim()

        if ($memStr.EndsWith("TB")) {
            return [long]$memStr.Replace("TB", "") * 1TB
        }
        elseif ($memStr.EndsWith("GB")) {
            return [long]$memStr.Replace("GB", "") * 1GB
        }
        elseif ($memStr.EndsWith("MB")) {
            return [long]$memStr.Replace("MB", "") * 1MB
        }
        elseif ($memStr.EndsWith("KB")) {
            return [long]$memStr.Replace("KB", "") * 1KB
        }
        elseif ($memStr.EndsWith("B")) {
            return [long]$memStr.Replace("B", "")
        }
        else {
            return [long]$memStr
        }
    }
}

<#
.SYNOPSIS
Builds a hash table of parameters for Hyper-V cmdlets based on a provided mapping and Ansible inputs.

.DESCRIPTION
Iterates through a predefined property map, checks if the corresponding Ansible parameter
was provided (is not null), and adds it to an output hash table using the correct Hyper-V property name.

.PARAMETER PropertyMap
An array of hashtables. Each hashtable must contain 'Param' (the Ansible parameter name)
and 'Property' (the Hyper-V cmdlet parameter name).
.PARAMETER AnsibleParams
The $module.Params object containing the user's playbook inputs.
.PARAMETER SwitchType
Optional SwitchType string to filter properties that only apply to a specific switch type (e.g., 'External').
#>
Function Get-HyperVParametersFromMap {
    param (
        [Parameter(Mandatory = $true)]
        [array]$PropertyMap,

        [Parameter(Mandatory = $true)]
        $AnsibleParams,

        [string]$SwitchType
    )

    process {
        $outParams = @{}
        foreach ($map in $PropertyMap) {
            $paramValue = $AnsibleParams.($map.Param)
            if ($null -eq $paramValue) { continue }

            # Safety: Only process properties supported by this SwitchType if specified in the map
            if ($null -ne $map.SwitchType -and $null -ne $SwitchType -and $SwitchType -ne $map.SwitchType) {
                continue
            }

            $targetParam = if ($null -ne $map.CmdletParam) { $map.CmdletParam } else { $map.Property }
            $outParams.($targetParam) = $paramValue
        }
        return $outParams
    }
}

<#
.SYNOPSIS
Compares current Hyper-V object properties against desired Ansible parameters.

.DESCRIPTION
Returns $true if any property in the map differs between the current object and desired parameters.

.PARAMETER PropertyMap
The mapping definition.
.PARAMETER CurrentObject
The Hyper-V object (CimInstance, etc.)
.PARAMETER AnsibleParams
The $module.Params object.
.PARAMETER SwitchType
Optional current SwitchType to filter relevant properties.
#>
Function Test-HyperVPropertiesChanged {
    param (
        [Parameter(Mandatory = $true)]
        [array]$PropertyMap,

        [Parameter(Mandatory = $true)]
        $CurrentObject,

        [Parameter(Mandatory = $true)]
        $AnsibleParams,

        [string]$SwitchType
    )

    process {
        foreach ($map in $PropertyMap) {
            $paramValue = $AnsibleParams.($map.Param)
            if ($null -eq $paramValue) { continue }

            # Safety: Only process properties supported by this SwitchType
            if ($null -ne $map.SwitchType -and $null -ne $SwitchType -and $SwitchType -ne $map.SwitchType) {
                continue
            }

            $currentValue = $CurrentObject.($map.Property)
            $isDifferent = $false

            switch ($map.Type) {
                "enum" {
                    $curStr = if ($null -ne $currentValue) { $currentValue.ToString() } else { "" }
                    $isDifferent = ($curStr -ne $paramValue)
                }
                "string" { $isDifferent = ([string]$currentValue -ne [string]$paramValue) }
                "bool" { $isDifferent = ([bool]$currentValue -ne [bool]$paramValue) }
                "list" {
                    $currList = if ($currentValue) { @($currentValue | Sort-Object) } else { @() }
                    $desList = @($paramValue | Sort-Object)
                    $isDifferent = (($currList -join ",") -ne ($desList -join ","))
                }
                default { $isDifferent = ($currentValue -ne $paramValue) }
            }

            if ($isDifferent) { return $true }
        }
        return $false
    }
}

<#
.SYNOPSIS
Populates the Ansible Result object with properties from a Hyper-V object.

.DESCRIPTION
Maps Hyper-V properties back to the expected Ansible return fields.

.PARAMETER PropertyMap
The mapping definition.
.PARAMETER CurrentObject
The Hyper-V object.
.PARAMETER ModuleResult
The $module.Result object to populate.
#>
Function Set-HyperVResultFromMap {
    param (
        [Parameter(Mandatory = $true)]
        [array]$PropertyMap,

        [Parameter(Mandatory = $true)]
        $CurrentObject,

        [Parameter(Mandatory = $true)]
        $ModuleResult
    )

    process {
        foreach ($map in $PropertyMap) {
            $val = $CurrentObject.($map.Property)
            switch ($map.Type) {
                "enum" {
                    # If it's a numeric enum that might return empty for 0, use string cast
                    $ModuleResult.($map.Param) = if ($null -ne $val) { $val.ToString() } else { $null }
                }
                "bool" {
                    $ModuleResult.($map.Param) = [bool]$val
                }
                "string" {
                    if ([string]::IsNullOrEmpty($val)) {
                        $ModuleResult.($map.Param) = $null
                    }
                    else {
                        $ModuleResult.($map.Param) = [string]$val
                    }
                }
                "list" {
                    if ($null -ne $val) {
                        $ModuleResult.($map.Param) = @($val)
                    }
                    else {
                        $ModuleResult.($map.Param) = @()
                    }
                }
                default {
                    $ModuleResult.($map.Param) = $val
                }
            }
        }
    }
}

<#
.SYNOPSIS
Checks if an IP address belongs to a CIDR range.

.DESCRIPTION
Supports IPv4 and IPv6. Also handles shorthand CIDR notation like "10/8".

.PARAMETER IP
The IP address to check.
.PARAMETER CIDR
The CIDR range (e.g. "192.168.1.0/24" or "10/8").
#>
Function Test-IPInCidr {
    param (
        [Parameter(Mandatory = $true)]
        [string]$IP,

        [Parameter(Mandatory = $true)]
        [string]$CIDR
    )

    process {
        try {
            if ($CIDR -notmatch "/") {
                return $IP -eq $CIDR
            }

            $parts = $CIDR.Split('/')
            $networkStr = $parts[0]

            # Handle shorthand like "10/8" -> "10.0.0.0/8"
            if ($networkStr -notmatch "\.") {
                $networkStr = "$networkStr.0.0.0"
            }
            elseif ($networkStr.Split(".").Count -lt 4) {
                while ($networkStr.Split(".").Count -lt 4) { $networkStr += ".0" }
            }

            $network = [System.Net.IPAddress]::Parse($networkStr)
            $maskLength = [int]$parts[1]
            $targetIP = [System.Net.IPAddress]::Parse($IP)

            if ($network.AddressFamily -ne $targetIP.AddressFamily) { return $false }

            $networkBytes = $network.GetAddressBytes()
            $ipBytes = $targetIP.GetAddressBytes()

            $fullBytes = if ($network.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork) { 4 } else { 16 }

            for ($i = 0; $i -lt $fullBytes; $i++) {
                $remainingBits = $maskLength - ($i * 8)
                if ($remainingBits -ge 8) {
                    if ($networkBytes[$i] -ne $ipBytes[$i]) { return $false }
                }
                elseif ($remainingBits -gt 0) {
                    $mask = [byte](256 - [System.Math]::Pow(2, (8 - $remainingBits)))
                    if (($networkBytes[$i] -band $mask) -ne ($ipBytes[$i] -band $mask)) { return $false }
                    break
                }
                else {
                    break
                }
            }
            return $true
        }
        catch {
            return $false
        }
    }
}

<#
.SYNOPSIS
Parses the Hyper-V VM Notes field into structured Tags and raw Notes.

.DESCRIPTION
The VM Notes field is used by Ansible to store structured metadata (Tags).
This function splits the string into a dictionary of tags and a string of non-tag notes.
#>
Function ConvertFrom-VMNote {
    param (
        [Parameter(Mandatory = $true)]
        $VM
    )

    process {
        $TAG_PREFIX = "[AnsibleTag]"
        $parsedTags = @{}
        $nonTagNotes = @()
        $notesStr = $VM.Notes

        if ([string]::IsNullOrWhiteSpace($notesStr)) {
            return @{ Tags = $parsedTags; Notes = "" }
        }

        $lines = $notesStr -split "`r`n|`n"
        foreach ($line in $lines) {
            if ($line.StartsWith($TAG_PREFIX)) {
                $tagContent = $line.Substring($TAG_PREFIX.Length).Trim()
                $idx = $tagContent.IndexOf(":")
                if ($idx -gt 0) {
                    $key = $tagContent.Substring(0, $idx).Trim()
                    $value = $tagContent.Substring($idx + 1).Trim()
                    $parsedTags[$key] = $value
                }
            }
            else {
                $nonTagNotes += $line
            }
        }
        return @{ Tags = $parsedTags; Notes = ($nonTagNotes -join "`n").Trim() }
    }
}

<#
.SYNOPSIS
Serializes a NoteData object back into a string for the VM Notes field.

.DESCRIPTION
Combines raw notes and structured tags back into a single string.
Tags are sorted to ensure idempotency.
#>
Function ConvertTo-VMNote {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$NoteData
    )

    process {
        $TAG_PREFIX = "[AnsibleTag]"
        $lines = @()
        
        if ($null -ne $NoteData.Notes -and $NoteData.Notes -ne "") {
            $lines += $NoteData.Notes
        }

        if ($null -ne $NoteData.Tags) {
            $keys = @($NoteData.Tags.Keys | Sort-Object)
            foreach ($k in $keys) {
                $lines += "$TAG_PREFIX $($k): $($NoteData.Tags[$k])"
            }
        }

        return ($lines -join "`n")
    }
}

Export-ModuleMember -Function Convert-ToByte, Get-HyperVParametersFromMap, Test-HyperVPropertiesChanged, Set-HyperVResultFromMap, Test-IPInCidr, ConvertFrom-VMNote, ConvertTo-VMNote
