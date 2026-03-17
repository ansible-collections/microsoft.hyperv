# -*- coding: utf-8 -*-
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: hv_vm
short_description: Manage Hyper-V Virtual Machines
description:
  - Create, remove, and manage the base configuration of virtual machines on a Hyper-V host.
  - Wraps New-VM and Remove-VM cmdlets.
  - Supports Generation 1 and Generation 2 VMs.
options:
  name:
    description:
      - The name of the virtual machine.
    type: str
    required: true
    aliases: [ vm_name ]
  state:
    description:
      - The desired state of the VM.
      - C(present) ensures the VM exists.
      - C(absent) ensures the VM is removed.
    type: str
    choices: [ present, absent ]
    default: present
  generation:
    description:
      - The generation of the virtual machine (1 or 2).
      - Only used when creating a new VM.
    type: int
    choices: [ 1, 2 ]
    default: 1
  memory_startup_bytes:
    description:
      - The amount of memory to assign to the virtual machine at startup.
      - Accepts an integer in bytes or a string like "4GB", "1024MB".
      - Only used when creating a new VM.
    type: raw
  boot_device:
    description:
      - The device the VM should boot from.
      - Maps to the BootDevice parameter in New-VM.
    type: str
    choices: [ CD, Floppy, IDE, LegacyNetworkAdapter, NetworkAdapter, VHD ]
author:
  - Ansible Cloud Team (@ansible)
'''

EXAMPLES = r'''
- name: Create a Gen2 VM with 4GB RAM
  microsoft.hyperv.hv_vm:
    name: Web01
    state: present
    generation: 2
    memory_startup_bytes: 4GB

- name: Remove a VM
  microsoft.hyperv.hv_vm:
    name: Web01
    state: absent
'''

RETURN = r'''
name:
    description: Name of the virtual machine.
    returned: always
    type: str
    sample: Web01
state:
    description: The final state of the virtual machine (present or absent).
    returned: always
    type: str
    sample: present
'''
