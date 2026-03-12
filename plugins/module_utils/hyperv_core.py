# -*- coding: utf-8 -*-
# Copyright (c) 2026, Ansible Cloud Team
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

import json
from ansible_collections.microsoft.hyperv.plugins.module_utils.hyperv_powershell import PowerShellBuilder


class HyperVCore:
    """
    Core utilities for managing Virtual Machines using the HyperVConnection.
    """
    def __init__(self, connection):
        self.conn = connection
        self.ps_builder = PowerShellBuilder()

    def _execute_and_parse(self, script):
        """
        Executes a script and parses the JSON output.
        """
        wrapped_script = self.ps_builder.wrap_with_json_output(script)
        stdout, stderr, rc = self.conn.execute_script(wrapped_script)

        if rc != 0:
            # Try to parse the error as JSON if we wrapped it, else return raw
            try:
                error_obj = json.loads(stderr)
                error_msg = error_obj.get("ExceptionMessage", stderr)
            except ValueError:
                error_msg = stderr
            self.conn.module.fail_json(msg="PowerShell error: {0}".format(error_msg))

        if not stdout.strip():
            return None

        try:
            return json.loads(stdout)
        except ValueError as e:
            self.conn.module.fail_json(msg="Failed to parse PowerShell JSON output: {0}\nOutput: {1}".format(str(e), stdout))

    def get_vm(self, vm_name):
        """
        Retrieves a Virtual Machine object by name.
        Returns None if not found.
        """
        script = """
        $vm = Get-VM -Name '{0}' -ErrorAction SilentlyContinue
        if ($vm) {{
            @{{
                Name = $vm.Name
                State = $vm.State.ToString()
                Status = $vm.Status.ToString()
                Generation = $vm.Generation
                Id = $vm.Id.ToString()
            }}
        }}
        """.format(vm_name)
        return self._execute_and_parse(script)

    def wait_for_state(self, vm_name, expected_state, timeout=300):
        """
        Waits for a VM to reach a specific state.
        """
        # Implement wait logic here
        pass
