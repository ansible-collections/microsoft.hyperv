# -*- coding: utf-8 -*-
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: hv_vm_boot
short_description: Manage boot configuration for Hyper-V Virtual Machines
description:
  - Manage Boot settings for Generation 1 (BIOS) and Generation 2 (Firmware) Virtual Machines.
  - Controls Secure Boot, Secure Boot Templates, NumLock state, and Startup Device Order.
  - Automatically identifies VM Generation and routes requests to Set-VMBios or Set-VMFirmware.
options:
  name:
    description:
      - The name of the virtual machine to configure.
    type: str
    required: true
    aliases: [ vm_name ]
  secure_boot:
    description:
      - Enable or disable Secure Boot.
      - Supported on Generation 2 Virtual Machines only.
    type: bool
  secure_boot_template:
    description:
      - The certificate template for Secure Boot.
      - Supported on Generation 2 Virtual Machines only.
    type: str
    choices: [ MicrosoftWindows, MicrosoftUEFICertificateAuthority, OpenSourceShieldedVM ]
  num_lock:
    description:
      - Enable or disable NumLock at VM startup.
      - Supported on Generation 1 Virtual Machines only.
    type: bool
  startup_order:
    description:
      - The boot order sequence of the devices.
      - Incomplete lists will automatically have the remaining existing devices appended.
      - Supported on Generation 1 Virtual Machines only.
    type: list
    elements: str
    choices: [ CD, Floppy, IDE, LegacyNetworkAdapter ]
author:
  - Ansible Cloud Team (@ansible)
'''

EXAMPLES = r'''
- name: Configure Secure Boot for a Linux Generation 2 VM
  microsoft.hyperv.hv_vm_boot:
    name: Gen2LinuxVM
    secure_boot: true
    secure_boot_template: MicrosoftUEFICertificateAuthority

- name: Set Startup Order and NumLock for a Generation 1 VM
  microsoft.hyperv.hv_vm_boot:
    name: Gen1LegacyVM
    num_lock: true
    startup_order:
      - CD
      - IDE
'''

RETURN = r'''
name:
    description: Name of the virtual machine.
    returned: always
    type: str
    sample: WebServer01
generation:
    description: The generation of the virtual machine.
    returned: always
    type: int
    sample: 2
secure_boot:
    description: The final Secure Boot state (Gen2 only).
    returned: success
    type: bool
    sample: true
secure_boot_template:
    description: The final Secure Boot Template (Gen2 only).
    returned: success
    type: str
    sample: MicrosoftWindows
num_lock:
    description: The final NumLock state (Gen1 only).
    returned: success
    type: bool
    sample: false
startup_order:
    description: The final Startup Order sequence (Gen1 only).
    returned: success
    type: list
    elements: str
    sample: ["CD", "IDE", "LegacyNetworkAdapter", "Floppy"]
'''
