# -*- coding: utf-8 -*-
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: hv_shielded_vm
short_description: Manage shielded virtual machines and Key Protectors
description:
  - Configure security settings and Key Protectors for shielded virtual machines.
  - This module allows enabling or disabling VM shielding and setting the encryption state of the VM.
  - Enabling shielding requires a valid base64 encoded Key Protector.
  - The VM must be in the 'Off' state to modify security settings.
options:
  vm_name:
    description:
      - The name of the virtual machine.
    type: str
    required: true
    aliases: [ name ]
  key_protector:
    description:
      - The base64 encoded Key Protector to apply to the VM.
      - Required when C(state) is C(enabled) and no Key Protector is currently set.
    type: str
  shield_security_policy:
    description:
      - Whether to enable the shielded security policy.
      - If C(true), the VM is protected against fabric administrator access.
    type: bool
  encryption_state:
    description:
      - The encryption state for the virtual machine.
      - C(encrypted) ensures the VM is encrypted.
      - C(supported) ensures the VM supports encryption but is not necessarily shielded.
    type: str
    choices: [ encrypted, supported ]
  state:
    description:
      - The desired state of VM shielding.
      - C(enabled) ensures shielding is active (requires Key Protector).
      - C(disabled) removes shielding and Key Protectors.
    type: str
    choices: [ enabled, disabled ]
    default: enabled
author:
  - Ansible Cloud Team (@ansible)
'''

EXAMPLES = r'''
- name: Enable shielding for a secure VM
  microsoft.hyperv.hv_shielded_vm:
    vm_name: Secure-App-01
    key_protector: "{{ base64_key_protector }}"
    shield_security_policy: true
    encryption_state: encrypted
    state: enabled

- name: Set security state to supported (encryption allowed but not enforced)
  microsoft.hyperv.hv_shielded_vm:
    vm_name: App-Server-01
    encryption_state: supported
'''

RETURN = r'''
vm_name:
    description: Name of the virtual machine.
    returned: always
    type: str
    sample: Secure-App-01
state:
    description: Final state of VM shielding.
    returned: always
    type: str
    sample: enabled
'''
