# -*- coding: utf-8 -*-
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: hv_vm_info
short_description: Gather information about Hyper-V Virtual Machines
description:
  - Gathers facts and information about one or all Virtual Machines on a Hyper-V host.
  - Returns structured data including state, uptime, ID, and generation.
options:
  name:
    description:
      - The name of the specific Virtual Machine to query.
      - If omitted, gathers information about all VMs on the host.
    type: str
    aliases: [ vm_name ]
  ansible_host:
    description: Hostname or IP of the Hyper-V host.
    type: str
    required: true
  ansible_user:
    description: Username for the Hyper-V host.
    type: str
    required: true
  ansible_password:
    description: Password for the Hyper-V host.
    type: str
    required: true
  ansible_port:
    description: WinRM port.
    type: int
    default: 5985
author:
  - Ansible Cloud Team (@ansible)
'''

EXAMPLES = r'''
- name: Gather facts about all VMs
  microsoft.hyperv.hv_vm_info:
    ansible_host: "{{ ansible_host }}"
    ansible_user: "{{ ansible_user }}"
    ansible_password: "{{ ansible_password }}"

- name: Gather facts about a specific VM
  microsoft.hyperv.hv_vm_info:
    name: WebServer01
    ansible_host: "{{ ansible_host }}"
    ansible_user: "{{ ansible_user }}"
    ansible_password: "{{ ansible_password }}"
'''

RETURN = r'''
vms:
    description: A list of dictionaries containing VM information.
    returned: always
    type: list
    elements: dict
    sample: [
        {
            "name": "WebServer01",
            "state": "Running",
            "status": "OperatingNormally",
            "uptime_seconds": 3600,
            "id": "12345678-1234-1234-1234-1234567890ab",
            "generation": 2
        }
    ]
'''

from ansible.module_utils.basic import AnsibleModule
from ansible_collections.microsoft.hyperv.plugins.module_utils.hyperv_connection import HyperVConnection
from ansible_collections.microsoft.hyperv.plugins.module_utils.hyperv_powershell import PowerShellBuilder


def run_module():
    module_args = dict(
        name=dict(type='str', aliases=['vm_name']),
        ansible_host=dict(type='str', required=True),
        ansible_user=dict(type='str', required=True),
        ansible_password=dict(type='str', required=True, no_log=True),
        ansible_port=dict(type='int', default=5985),
    )

    module = AnsibleModule(
        argument_spec=module_args,
        supports_check_mode=True
    )

    result = dict(
        changed=False,
        vms=[]
    )

    name = module.params.get('name')

    connection = HyperVConnection(module)
    ps_builder = PowerShellBuilder()

    # Build the script
    script_lines = []
    if name:
        # Use single quotes and escape any internal single quotes
        escaped_name = name.replace("'", "''")
        script_lines.append("$vms = Get-VM -Name '{0}' -ErrorAction SilentlyContinue".format(escaped_name))
    else:
        script_lines.append("$vms = Get-VM -ErrorAction SilentlyContinue")

    script_lines.append("""
    if (-not $vms) {
        return @()
    }
    $vmlist = @()
    foreach ($vm in @($vms)) {
        $vmlist += @{
            name = $vm.Name
            state = $vm.State.ToString()
            status = $vm.Status.ToString()
            uptime_seconds = [math]::Round($vm.Uptime.TotalSeconds)
            id = $vm.Id.ToString()
            generation = $vm.Generation
        }
    }
    return $vmlist
    """)

    script = "\n".join(script_lines)
    wrapped_script = ps_builder.wrap_with_json_output(script)

    stdout, stderr, rc = connection.execute_script(wrapped_script)

    if rc != 0:
        module.fail_json(msg="Failed to gather VM info: {0}".format(stderr), stdout=stdout)

    if stdout:
        import json
        try:
            parsed = json.loads(stdout)
            # PowerShell might return a single dict instead of list if there's only 1 result
            if isinstance(parsed, dict):
                # Check if it's the empty dict we return when $Result is $null
                if not parsed:
                    result['vms'] = []
                else:
                    result['vms'] = [parsed]
            elif isinstance(parsed, list):
                result['vms'] = parsed
            else:
                result['vms'] = []
        except Exception as e:
            module.fail_json(msg="Failed to parse JSON output: {0}".format(str(e)), stdout=stdout)

    module.exit_json(**result)


if __name__ == '__main__':
    run_module()
