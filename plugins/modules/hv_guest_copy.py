# -*- coding: utf-8 -*-
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: hv_guest_copy
short_description: Transfer files to and from a Hyper-V Guest
description:
  - Transfers files or directories between the Hyper-V host and a virtual machine's Guest OS.
  - This module uses PowerShell Direct (VMBus) to communicate with the guest.
  - This completely bypasses the network stack, making it ideal for air-gapped VMs.
  - When copying single files, the module calculates SHA256 hashes on both the host and guest to ensure true idempotency.
options:
  vm_name:
    description:
      - The name of the virtual machine.
    type: str
    required: true
    aliases: [ name ]
  guest_credential:
    description:
      - Dictionary containing the username and password for the Guest OS.
      - Required to authenticate over the VMBus.
    type: dict
    required: true
    suboptions:
      username:
        description: Guest OS username.
        type: str
        required: true
      password:
        description: Guest OS password.
        type: str
        required: true
  action:
    description:
      - The transfer direction.
      - C(copy_in) copies from the Hyper-V host into the Guest OS.
      - C(copy_out) copies from the Guest OS out to the Hyper-V host.
    type: str
    choices: [ copy_in, copy_out ]
    required: true
  src:
    description:
      - The source path.
      - If action is C(copy_in), this is the path on the Hyper-V host.
      - If action is C(copy_out), this is the path inside the Guest OS.
    type: str
    required: true
  dest:
    description:
      - The destination path.
      - If action is C(copy_in), this is the path inside the Guest OS.
      - If action is C(copy_out), this is the path on the Hyper-V host.
    type: str
    required: true
author:
  - Ansible Cloud Team (@ansible)
'''

EXAMPLES = r'''
- name: Copy a setup file into the guest
  microsoft.hyperv.hv_guest_copy:
    vm_name: Web01
    guest_credential:
      username: Administrator
      password: "SuperSecretPassword"
    action: copy_in
    src: C:\ISOs\setup.exe
    dest: C:\Temp\setup.exe

- name: Retrieve a log file from the guest
  microsoft.hyperv.hv_guest_copy:
    vm_name: Web01
    guest_credential:
      username: Administrator
      password: "SuperSecretPassword"
    action: copy_out
    src: C:\Windows\Logs\Setup.log
    dest: C:\HostLogs\Web01_Setup.log
'''

RETURN = r'''
vm_name:
    description: The name of the virtual machine targeted.
    returned: always
    type: str
    sample: Web01
action:
    description: The copy action performed.
    returned: always
    type: str
    sample: copy_in
'''
