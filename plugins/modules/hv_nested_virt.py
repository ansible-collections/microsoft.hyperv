# -*- coding: utf-8 -*-
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: hv_nested_virt
short_description: Enable or disable nested virtualization for Hyper-V VMs
description:
  - Configure a virtual machine to support nested virtualization.
  - This module exposes virtualization extensions to the guest processor and enables MAC address spoofing on the network adapter.
  - These settings are required for a VM to run its own Hyper-V hypervisor.
  - The VM must be in the 'Off' state to modify the processor virtualization extensions.
options:
  vm_name:
    description:
      - The name of the virtual machine.
    type: str
    required: true
    aliases: [ name ]
  state:
    description:
      - The desired state of nested virtualization.
      - C(enabled) ensures virtualization extensions are exposed and MAC spoofing is on.
      - C(disabled) ensures virtualization extensions are hidden and MAC spoofing is off.
    type: str
    choices: [ enabled, disabled ]
    default: enabled
author:
  - Ansible Cloud Team (@ansible)
'''

EXAMPLES = r'''
- name: Enable nested virtualization for a lab VM
  microsoft.hyperv.hv_nested_virt:
    vm_name: Lab-Host-01
    state: enabled

- name: Disable nested virtualization
  microsoft.hyperv.hv_nested_virt:
    vm_name: Lab-Host-01
    state: disabled
'''

RETURN = r'''
vm_name:
    description: Name of the virtual machine.
    returned: always
    type: str
    sample: Lab-Host-01
state:
    description: The final state of nested virtualization configuration.
    returned: always
    type: str
    sample: enabled
'''
