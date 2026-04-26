# -*- coding: utf-8 -*-
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: hv_vm_move
short_description: Manage Hyper-V Virtual Machine Live Migration and Storage Migration
description:
  - Move a virtual machine or its storage to a new location.
  - Supports Host-to-Host Live Migration (Shared Nothing or SMB).
  - Supports Storage-Only Migration (moving VM files to a new directory on the same host while running).
options:
  name:
    description:
      - The name of the virtual machine to move.
    type: str
    required: true
    aliases: [ vm_name ]
  destination_host:
    description:
      - The target Hyper-V host to move the VM to.
      - If omitted, the module performs a Storage-Only Migration on the current host.
    type: str
  destination_storage_path:
    description:
      - The target directory path where the VM files (config, snapshots, paging, and VHDs) will be moved.
      - If C(destination_host) is specified but this is omitted, the VM is moved but its files stay where they are (requires shared storage).
    type: str
author:
  - Ansible Cloud Team (@ansible)
'''

EXAMPLES = r'''
- name: Storage Migration - Move VM files to a new local drive
  microsoft.hyperv.hv_vm_move:
    name: WebServer01
    destination_storage_path: "D:\\VirtualMachines\\WebServer01"

- name: Live Migration - Move VM to a different host (Shared Storage)
  microsoft.hyperv.hv_vm_move:
    name: WebServer01
    destination_host: "HV-NODE-02"

- name: Shared Nothing Live Migration - Move VM and its storage to a new host
  microsoft.hyperv.hv_vm_move:
    name: WebServer01
    destination_host: "HV-NODE-02"
    destination_storage_path: "C:\\ClusterStorage\\Volume1\\WebServer01"
'''

RETURN = r'''
name:
    description: Name of the virtual machine.
    returned: always
    type: str
    sample: WebServer01
destination_host:
    description: The target host the VM was moved to (if applicable).
    returned: always
    type: str
    sample: "HV-NODE-02"
destination_storage_path:
    description: The target path the VM storage was moved to (if applicable).
    returned: always
    type: str
    sample: "D:\\VirtualMachines\\WebServer01"
'''
