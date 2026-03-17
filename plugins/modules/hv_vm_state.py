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
    type: str
    choices: [ running, stopped, restarted, paused, saved ]
    required: true
  force:
    description:
      - If C(true), forces the operation (e.g., Turn Off instead of Shut Down).
    type: bool
    default: false
author:
  - Ansible Cloud Team (@ansible)
'''

EXAMPLES = r'''
- name: Start a VM
  microsoft.hyperv.hv_vm_state:
    name: WebServer01
    state: running

- name: Forcefully stop a VM
  microsoft.hyperv.hv_vm_state:
    name: Database01
    state: stopped
    force: true
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
