# -*- coding: utf-8 -*-
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: hv_hard_disk
short_description: Manage Hyper-V Virtual Machine Hard Disk Drives
description:
  - Attach or detach virtual hard disk (VHDX/VHD) files to a virtual machine's IDE or SCSI controller.
  - Allows specifying the exact controller type, number, and location (slot).
options:
  vm_name:
    description:
      - The name of the virtual machine to manage the hard disk drive for.
    type: str
    required: true
  path:
    description:
      - The full path to the virtual hard disk file (.vhdx or .vhd) to attach or detach.
    type: str
    required: true
  state:
    description:
      - The desired state of the hard disk drive attachment.
      - C(present) ensures the disk is attached to the VM.
      - C(absent) ensures the disk is detached from the VM.
    type: str
    choices: [ present, absent ]
    default: present
  controller_type:
    description:
      - The type of controller to attach the disk to.
      - Generation 1 VMs support C(IDE) and C(SCSI).
      - Generation 2 VMs support C(SCSI) and C(PMEM).
    type: str
    choices: [ IDE, SCSI, PMEM ]
  controller_number:
    description:
      - The index of the controller to attach the disk to.
    type: int
  controller_location:
    description:
      - The slot location on the controller to attach the disk to.
    type: int
author:
  - Ansible Cloud Team (@ansible)
'''

EXAMPLES = r'''
- name: Attach a data disk to a VM's SCSI controller
  microsoft.hyperv.hv_hard_disk:
    vm_name: WebServer01
    path: "C:\\Hyper-V\\VHDs\\DataDisk01.vhdx"
    controller_type: SCSI
    state: present

- name: Detach a specific disk from a VM
  microsoft.hyperv.hv_hard_disk:
    vm_name: WebServer01
    path: "C:\\Hyper-V\\VHDs\\DataDisk01.vhdx"
    state: absent
'''

RETURN = r'''
vm_name:
    description: Name of the virtual machine.
    returned: always
    type: str
    sample: WebServer01
path:
    description: The full path of the virtual hard disk.
    returned: always
    type: str
    sample: "C:\\Hyper-V\\VHDs\\DataDisk01.vhdx"
state:
    description: The final state of the hard disk attachment.
    returned: always
    type: str
    sample: present
controller_type:
    description: The type of controller the disk is attached to.
    returned: when state is present
    type: str
    sample: SCSI
controller_number:
    description: The index of the controller.
    returned: when state is present
    type: int
    sample: 0
controller_location:
    description: The slot location on the controller.
    returned: when state is present
    type: int
    sample: 1
'''
