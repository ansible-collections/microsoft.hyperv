# -*- coding: utf-8 -*-
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: hv_vm_boot
short_description: Configure Virtual Machine boot and firmware settings
description:
  - Manage boot order, BIOS, and firmware settings for Hyper-V Virtual Machines.
  - Supports Generation 1 (BIOS) and Generation 2 (UEFI/Firmware) VMs.
  - Configure Secure Boot, NumLock state, and device boot sequence.
options:
  name:
    description:
      - The name of the virtual machine.
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
      - The boot order sequence of the devices for Generation 1 VMs.
      - Incomplete lists will automatically have the remaining existing devices appended.
      - Supported on Generation 1 Virtual Machines only.
    type: list
    elements: str
    choices: [ CD, Floppy, IDE, LegacyNetworkAdapter, NetworkAdapter, VHD ]
  boot_order:
    description:
      - The boot order sequence of the devices for Generation 2 VMs.
      - Accepts a list of device types - C(Network), C(DVD), C(SCSI), C(File).
      - You can target specific SCSI controllers using the format C(SCSI:<ControllerNumber>:<ControllerLocation>) (e.g., C(SCSI:0:0)).
      - Any standard device (Network, DVD, SCSI) NOT listed will be removed from the boot order.
      - If specific SCSI controllers are targeted, any unlisted SCSI devices will be removed.
      - OS-injected bootloaders (e.g., Linux GRUB C(File) entries) will automatically be preserved at the top of the
        boot order unless C(File) is explicitly listed in your sequence, in which case it follows your exact ordering.
      - Supported on Generation 2 Virtual Machines only.
    type: list
    elements: str
author:
  - Ansible Cloud Team (@ansible)
'''

EXAMPLES = r'''
- name: Configure Secure Boot and Boot Order for a Gen2 VM
  microsoft.hyperv.hv_vm_boot:
    name: Gen2VM
    secure_boot: true
    boot_order:
      - SCSI
      - DVD
      - Network

- name: Set Startup Order and NumLock for a Gen1 VM
  microsoft.hyperv.hv_vm_boot:
    name: Gen1LegacyVM
    num_lock: true
    startup_order:
      - VHD
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
    sample: ["VHD", "CD", "IDE", "LegacyNetworkAdapter"]
boot_order:
    description: The final Boot Order sequence of device types (Gen2 only).
    returned: success
    type: list
    elements: str
    sample: ["SCSI", "DVD", "Network"]
'''
