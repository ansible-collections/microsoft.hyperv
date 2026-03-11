# -*- coding: utf-8 -*-
# Copyright (c) 2026, Ansible Cloud Team
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type


class PowerShellBuilder:
    """
    Utility class to build PowerShell scripts safely and parse their output.
    """

    @staticmethod
    def build_command(cmdlet, params=None):
        """
        Builds a PowerShell command string from a cmdlet and a dictionary of parameters.
        """
        if not params:
            return cmdlet

        cmd_parts = [cmdlet]
        for key, value in params.items():
            if value is None:
                continue

            # Format the parameter name
            param_name = "-{0}".format(key)

            # Format the value
            if isinstance(value, bool):
                # For switch parameters, we only add the flag if true.
                # If explicit boolean is needed, use $true / $false
                if value:
                    cmd_parts.append("{0} $true".format(param_name))
                else:
                    cmd_parts.append("{0} $false".format(param_name))
            elif isinstance(value, int):
                cmd_parts.append("{0} {1}".format(param_name, value))
            elif isinstance(value, list):
                # Comma separated list of strings
                formatted_list = ",".join(["'{0}'".format(str(v)) for v in value])
                cmd_parts.append("{0} {1}".format(param_name, formatted_list))
            else:
                # String escaping
                escaped_val = str(value).replace("'", "''")
                cmd_parts.append("{0} '{1}'".format(param_name, escaped_val))

        return " ".join(cmd_parts)

    @staticmethod
    def wrap_with_json_output(script_body):
        """
        Wraps a PowerShell script to ensure output is returned as standard JSON
        and errors are caught properly.
        """
        wrapper = """
$ErrorActionPreference = 'Stop'
try {{
    $Result = & {{
        {0}
    }}
    if ($null -ne $Result) {{
        $Result | ConvertTo-Json -Depth 10 -Compress
    }} else {{
        # Return an empty JSON object to indicate success but no output
        '{{}}'
    }}
}} catch {{
    $ErrorObj = @{{
        ExceptionMessage = $_.Exception.Message
        FullyQualifiedErrorId = $_.FullyQualifiedErrorId
        ScriptStackTrace = $_.ScriptStackTrace
    }}
    Write-Error ($ErrorObj | ConvertTo-Json -Compress)
}}
""".format(script_body)
        return wrapper
