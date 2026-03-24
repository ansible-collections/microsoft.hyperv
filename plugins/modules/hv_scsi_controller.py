# -*- coding: utf-8 -*-
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: hv_scsi_controller
short_description: Manage Hyper-V Virtual Machine SCSI Controllers
description:
  - Manage the number of synthetic SCSI controllers attached to a Hyper-V Virtual Machine.
  - Hyper-V VMs support a maximum of 4 SCSI controllers, each capable of hosting up to 64 virtual drives.
  - Gen2 VMs require at least one SCSI controller for their boot drive.
options:
  vm_name:
    description:
      - The name of the virtual machine to manage SCSI controllers for.
    type: str
    required: true
  count:
    description:
      - The exact number of SCSI controllers the virtual machine should have.
      - Accepts an integer between 0 and 4.
      - If the current count is lower, new controllers are added automatically.
      - If the current count is higher, the controllers with the highest numbers are safely removed (provided no drives are attached to them).
    type: int
    required: true
author:
  - Ansible Cloud Team (@ansible)
'''

EXAMPLES = r'''
- name: Ensure a VM has exactly 2 SCSI controllers for separate data drive paths
  microsoft.hyperv.hv_scsi_controller:
    vm_name: DatabaseVM
    count: 2

- name: Remove all SCSI controllers from a Gen1 VM
  microsoft.hyperv.hv_scsi_controller:
    vm_name: LegacyAppVM
    count: 0
'''

RETURN = r'''
vm_name:
    description: Name of the virtual machine.
    returned: always
    type: str
    sample: DatabaseVM
count:
    description: The final number of SCSI controllers attached to the VM.
    returned: always
    type: int
    sample: 2
controllers:
    description: A list of objects representing the current SCSI controllers.
    returned: always
    type: list
    elements: dict
    sample: [
        {
            "id": "Microsoft:2C4C617F-4B2B-45F4-A01D-5E24296063F2\\b70d4af0-6b66-4171-b8ea-05187747e923\\0",
            "controller_number": 0
        },
        {
            "id": "Microsoft:2C4C617F-4B2B-45F4-A01D-5E24296063F2\\b70d4af0-6b66-4171-b8ea-05187747e923\\1",
            "controller_number": 1
        }
    ]
'''
