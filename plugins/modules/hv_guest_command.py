# -*- coding: utf-8 -*-
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: hv_guest_command
short_description: Execute PowerShell scripts directly inside a Hyper-V Guest
description:
  - Executes a PowerShell script block inside a Hyper-V virtual machine's Guest OS.
  - This module uses PowerShell Direct (VMBus) to communicate with the guest.
  - This completely bypasses the network stack, making it ideal for air-gapped VMs or initial network configuration.
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
  script:
    description:
      - The PowerShell script block to execute inside the guest.
    type: str
    required: true
author:
  - Ansible Cloud Team (@ansible)
'''

EXAMPLES = r'''
- name: Run a simple ipconfig command inside the guest
  microsoft.hyperv.hv_guest_command:
    vm_name: Web01
    guest_credential:
      username: Administrator
      password: "SuperSecretPassword"
    script: "ipconfig /all"
  register: guest_output

- name: Create a directory inside the guest
  microsoft.hyperv.hv_guest_command:
    vm_name: Web01
    guest_credential:
      username: Administrator
      password: "SuperSecretPassword"
    script: |
      if (-not (Test-Path C:\Temp)) {
          New-Item -ItemType Directory -Path C:\Temp
      }
'''

RETURN = r'''
vm_name:
    description: The name of the virtual machine targeted.
    returned: always
    type: str
    sample: Web01
stdout:
    description: Standard output from the executed script block.
    returned: success
    type: str
    sample: "Windows IP Configuration"
stderr:
    description: Standard error output from the executed script block.
    returned: success
    type: str
'''
