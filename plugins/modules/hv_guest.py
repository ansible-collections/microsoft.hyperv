# -*- coding: utf-8 -*-
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: hv_guest
short_description: Manage Hyper-V Guest OS via PowerShell Direct
description:
  - Execute commands and copy files directly into a Hyper-V virtual machine's Guest OS using PowerShell Direct (VMBus).
  - This allows management of isolated, air-gapped VMs without requiring any network connectivity to the guest.
  - Note that the guest OS must be running Windows 10/Windows Server 2016 or newer, and must be in a 'Running' state.
options:
  vm_name:
    description:
      - The name of the virtual machine to connect to.
    type: str
    required: true
    aliases: [ name ]
  guest_credential:
    description:
      - A dictionary containing the C(username) and C(password) for an administrator account inside the Guest OS.
    type: dict
    required: true
    suboptions:
      username:
        description: The guest username.
        type: str
        required: true
      password:
        description: The guest password.
        type: str
        required: true
  action:
    description:
      - The action to perform inside the guest.
      - C(run) executes a PowerShell script block.
      - C(copy_in) copies a file or directory from the Hyper-V Host into the Guest OS.
      - C(copy_out) copies a file or directory from the Guest OS out to the Hyper-V Host.
    type: str
    choices: [ run, copy_in, copy_out ]
    required: true
  script:
    description:
      - The PowerShell commands to execute when C(action=run).
    type: str
  src:
    description:
      - The source path for file operations.
      - For C(copy_in), this is the path on the Hyper-V Host.
      - For C(copy_out), this is the path inside the Guest OS.
    type: str
  dest:
    description:
      - The destination path for file operations.
      - For C(copy_in), this is the path inside the Guest OS.
      - For C(copy_out), this is the path on the Hyper-V Host.
    type: str
author:
  - Ansible Cloud Team (@ansible)
'''

EXAMPLES = r'''
- name: Execute a command inside an isolated VM
  microsoft.hyperv.hv_guest:
    vm_name: IsolatedWebServer
    guest_credential:
      username: Administrator
      password: "SuperSecretPassword123!"
    action: run
    script: "Restart-Service -Name W3SVC"

- name: Copy a configuration file into the guest
  microsoft.hyperv.hv_guest:
    vm_name: IsolatedWebServer
    guest_credential:
      username: Administrator
      password: "SuperSecretPassword123!"
    action: copy_in
    src: "C:\\HostShares\\web.config"
    dest: "C:\\inetpub\\wwwroot\\web.config"
'''

RETURN = r'''
vm_name:
    description: Name of the virtual machine.
    returned: always
    type: str
    sample: IsolatedWebServer
action:
    description: The action performed.
    returned: always
    type: str
    sample: run
stdout:
    description: Standard output from the executed script.
    returned: when action is run
    type: str
    sample: "Service restarted successfully."
stderr:
    description: Error output from the executed script.
    returned: when action is run and errors occurred
    type: str
'''
