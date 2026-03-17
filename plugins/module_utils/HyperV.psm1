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

Export-ModuleMember -Function Convert-ToByte
