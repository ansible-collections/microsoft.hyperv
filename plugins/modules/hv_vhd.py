# -*- coding: utf-8 -*-
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: hv_vhd
short_description: Manage Hyper-V Virtual Hard Disk (VHD/VHDX) files
description:
  - Create, resize, and remove Virtual Hard Disk (VHD/VHDX) files on a Hyper-V host.
  - Mount and dismount VHD/VHDX files to the host file system for offline patching or file injection.
options:
  path:
    description:
      - The absolute path to the virtual hard disk file (.vhdx or .vhd).
    type: str
    required: true
  state:
    description:
      - The desired state of the virtual hard disk file.
      - C(present) ensures the VHD exists and is sized correctly.
      - C(absent) ensures the VHD file is deleted from the host.
      - C(mounted) ensures the VHD is attached to the host operating system.
      - C(dismounted) ensures the VHD is detached from the host operating system.
    type: str
    choices: [ present, absent, mounted, dismounted ]
    default: present
  size_bytes:
    description:
      - The maximum size of the virtual hard disk.
      - Required when creating a new VHD (C(state=present)).
      - Can be used to resize an existing VHD (expansion only).
      - Accepts an integer in bytes or a string like "10GB" or "512MB".
    type: raw
  vhd_type:
    description:
      - The type of virtual hard disk to create.
      - Only applied when creating a new VHD.
    type: str
    choices: [ Dynamic, Fixed, Differencing ]
    default: Dynamic
  parent_path:
    description:
      - The path to the parent VHD file.
      - Required only when creating a C(Differencing) disk.
    type: str
author:
  - Ansible Cloud Team (@ansible)
'''

EXAMPLES = r'''
- name: Create a 50GB Dynamic VHDX file
  microsoft.hyperv.hv_vhd:
    path: "C:\\Hyper-V\\VHDs\\DataDisk.vhdx"
    state: present
    size_bytes: "50GB"
    vhd_type: Dynamic

- name: Mount a VHDX to the host for offline patching
  microsoft.hyperv.hv_vhd:
    path: "C:\\Hyper-V\\VHDs\\GoldenImage.vhdx"
    state: mounted

- name: Dismount a VHDX from the host
  microsoft.hyperv.hv_vhd:
    path: "C:\\Hyper-V\\VHDs\\GoldenImage.vhdx"
    state: dismounted

- name: Delete a VHDX file
  microsoft.hyperv.hv_vhd:
    path: "C:\\Hyper-V\\VHDs\\OldDisk.vhdx"
    state: absent
'''

RETURN = r'''
path:
    description: The full path to the virtual hard disk.
    returned: always
    type: str
    sample: "C:\\Hyper-V\\VHDs\\DataDisk.vhdx"
state:
    description: The final state of the virtual hard disk.
    returned: always
    type: str
    sample: present
size_bytes:
    description: The current size of the virtual hard disk, in bytes.
    returned: when state is present, mounted, or dismounted
    type: int
    sample: 53687091200
vhd_type:
    description: The type of the virtual hard disk.
    returned: when state is present, mounted, or dismounted
    type: str
    sample: Dynamic
attached:
    description: Indicates whether the virtual hard disk is currently mounted to the host.
    returned: when state is present, mounted, or dismounted
    type: bool
    sample: false
'''
