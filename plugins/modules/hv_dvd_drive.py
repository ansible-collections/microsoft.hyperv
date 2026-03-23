# -*- coding: utf-8 -*-
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: hv_dvd_drive
short_description: Manage Hyper-V Virtual Machine DVD Drives and ISO Mounting
description:
  - Add or remove virtual DVD drives on a Hyper-V Virtual Machine.
  - Mount ISO images to virtual DVD drives for OS installation or software deployment.
  - Eject media from existing virtual DVD drives.
options:
  vm_name:
    description:
      - The name of the virtual machine to manage the DVD drive for.
    type: str
    required: true
  controller_number:
    description:
      - The index of the controller to which the DVD drive is or will be attached.
      - For Generation 1 VMs, this is typically an IDE controller.
      - For Generation 2 VMs, this is typically a SCSI controller.
    type: int
  controller_location:
    description:
      - The specific slot location on the controller.
    type: int
  path:
    description:
      - The full path to the ISO file to mount.
      - Required when C(state=mounted).
      - If omitted when C(state=present), a blank DVD drive is created or left as-is.
    type: str
  state:
    description:
      - The desired state of the DVD drive.
      - C(present) ensures the DVD drive exists. If C(path) is specified, it will mount the ISO.
      - C(absent) ensures the DVD drive is removed entirely from the VM.
      - C(mounted) ensures the DVD drive exists and the specified ISO C(path) is mounted.
      - C(ejected) ensures the DVD drive exists but contains no ISO media.
    type: str
    choices: [ present, absent, mounted, ejected ]
    default: present
author:
  - Ansible Cloud Team (@ansible)
'''

EXAMPLES = r'''
- name: Add a blank DVD drive to controller 0, location 1
  microsoft.hyperv.hv_dvd_drive:
    vm_name: WebServer01
    controller_number: 0
    controller_location: 1
    state: present

- name: Mount an installation ISO to an existing drive (or create it)
  microsoft.hyperv.hv_dvd_drive:
    vm_name: NewServer01
    controller_number: 0
    controller_location: 1
    path: "\\\\FileServer\\ISOs\\WindowsServer2025.iso"
    state: mounted

- name: Eject the ISO media from the drive
  microsoft.hyperv.hv_dvd_drive:
    vm_name: NewServer01
    controller_number: 0
    controller_location: 1
    state: ejected

- name: Remove the DVD drive entirely
  microsoft.hyperv.hv_dvd_drive:
    vm_name: NewServer01
    controller_number: 0
    controller_location: 1
    state: absent
'''

RETURN = r'''
vm_name:
    description: Name of the virtual machine.
    returned: always
    type: str
    sample: WebServer01
state:
    description: The final state of the DVD drive configuration.
    returned: always
    type: str
    sample: mounted
path:
    description: The full path to the currently mounted ISO file, if any.
    returned: when state is present, mounted, or ejected
    type: str
    sample: "C:\\ISOs\\WindowsServer2025.iso"
controller_number:
    description: The index of the controller the drive is attached to.
    returned: when state is present, mounted, or ejected
    type: int
    sample: 0
controller_location:
    description: The slot location on the controller.
    returned: when state is present, mounted, or ejected
    type: int
    sample: 1
'''
