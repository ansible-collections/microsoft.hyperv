# -*- coding: utf-8 -*-
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: hv_vm_state
short_description: Manage Hyper-V Virtual Machine power states
description:
  - Manage the power state of virtual machines on a Hyper-V host.
  - Supports starting, stopping, restarting, pausing, resuming, and saving VMs.
  - Consolidates power management and restart operations.
options:
  name:
    description:
      - The name of the virtual machine to manage.
    type: str
    required: true
    aliases: [ vm_name ]
  state:
    description:
      - The desired power state of the VM.
      - C(running) ensures the VM is started.
      - C(stopped) ensures the VM is shut down.
      - C(restarted) will trigger a restart of the VM.
      - C(paused) will suspend the VM execution.
      - C(saved) will save the VM state to disk.
    type: str
    choices: [ running, stopped, restarted, paused, saved ]
    required: true
  force:
    description:
      - If C(true), forces the operation (e.g., Turn Off instead of Shut Down).
    type: bool
    default: false
  wait:
    description:
      - If C(true), waits for the state transition to complete.
    type: bool
    default: true
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
- name: Start a VM
  microsoft.hyperv.hv_vm_state:
    name: WebServer01
    state: running
    ansible_host: "{{ ansible_host }}"
    ansible_user: "{{ ansible_user }}"
    ansible_password: "{{ ansible_password }}"

- name: Forcefully stop a VM
  microsoft.hyperv.hv_vm_state:
    name: Database01
    state: stopped
    force: true
    ansible_host: "{{ ansible_host }}"
    ansible_user: "{{ ansible_user }}"
    ansible_password: "{{ ansible_password }}"

- name: Restart a VM
  microsoft.hyperv.hv_vm_state:
    name: AppServer01
    state: restarted
    ansible_host: "{{ ansible_host }}"
    ansible_user: "{{ ansible_user }}"
    ansible_password: "{{ ansible_password }}"
'''

RETURN = r'''
name:
    description: Name of the virtual machine.
    returned: always
    type: str
    sample: WebServer01
state:
    description: The new state of the virtual machine.
    returned: always
    type: str
    sample: Running
'''

from ansible.module_utils.basic import AnsibleModule
from ansible_collections.microsoft.hyperv.plugins.module_utils.hyperv_connection import HyperVConnection
from ansible_collections.microsoft.hyperv.plugins.module_utils.hyperv_powershell import PowerShellBuilder
from ansible_collections.microsoft.hyperv.plugins.module_utils.hyperv_core import HyperVCore


def run_module():
    module_args = dict(
        name=dict(type='str', required=True, aliases=['vm_name']),
        state=dict(type='str', required=True, choices=['running', 'stopped', 'restarted', 'paused', 'saved']),
        force=dict(type='bool', default=False),
        wait=dict(type='bool', default=True),
        ansible_host=dict(type='str', required=True),
        ansible_user=dict(type='str', required=True),
        ansible_password=dict(type='str', required=True, no_log=True),
        ansible_port=dict(type='int', default=5985),
    )

    module = AnsibleModule(
        argument_spec=module_args,
        supports_check_mode=True
    )

    name = module.params.get('name')
    state = module.params.get('state')
    force = module.params.get('force')

    result = dict(
        changed=False,
        name=name,
        state=''
    )

    connection = HyperVConnection(module)
    core = HyperVCore(connection)

    # 1. Check current state
    vm = core.get_vm(name)
    if not vm:
        module.fail_json(msg="Virtual Machine '{0}' not found.".format(name))

    current_state = vm['State']
    result['state'] = current_state

    # Mapping Ansible states to Hyper-V states
    # Running, Off, Paused, Saved
    target_map = {
        'running': 'Running',
        'stopped': 'Off',
        'paused': 'Paused',
        'saved': 'Saved',
        'restarted': 'Restart'  # Special case
    }

    target_hv_state = target_map[state]

    # 2. Determine if change is needed
    if state != 'restarted' and current_state == target_hv_state:
        module.exit_json(**result)

    if module.check_mode:
        result['changed'] = True
        result['state'] = target_hv_state if state != 'restarted' else 'Running'
        module.exit_json(**result)

    # 3. Perform action
    cmd = ""
    if state == 'running':
        if current_state == 'Paused':
            cmd = "Resume-VM -Name '{0}'".format(name)
        else:
            cmd = "Start-VM -Name '{0}'".format(name)
    elif state == 'stopped':
        if force:
            cmd = "Stop-VM -Name '{0}' -TurnOff".format(name)
        else:
            cmd = "Stop-VM -Name '{0}'".format(name)
    elif state == 'restarted':
        if force:
            # Force restart usually means Restart-VM -Force
            cmd = "Restart-VM -Name '{0}' -Force".format(name)
        else:
            cmd = "Restart-VM -Name '{0}'".format(name)
    elif state == 'paused':
        cmd = "Suspend-VM -Name '{0}'".format(name)
    elif state == 'saved':
        cmd = "Save-VM -Name '{0}'".format(name)

    # Execute
    stdout, stderr, rc = connection.execute_script(PowerShellBuilder.wrap_with_json_output(cmd))

    if rc != 0:
        module.fail_json(msg="Failed to change VM state: {0}".format(stderr), stdout=stdout)

    result['changed'] = True

    # Refresh state
    new_vm = core.get_vm(name)
    if new_vm:
        result['state'] = new_vm['State']

    module.exit_json(**result)


if __name__ == '__main__':
    run_module()
