# -*- coding: utf-8 -*-
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: hv_checkpoint
short_description: Manage Hyper-V Virtual Machine Checkpoints (Snapshots)
description:
  - Create, remove, and revert to Hyper-V checkpoints (snapshots).
  - Provides a safety net for rollback before applying risky configurations.
options:
  vm_name:
    description:
      - The name of the virtual machine to manage checkpoints for.
    type: str
    required: true
  name:
    description:
      - The name of the checkpoint.
    type: str
    required: true
  state:
    description:
      - The desired state of the checkpoint.
      - C(present) ensures the checkpoint exists.
      - C(absent) ensures the checkpoint is removed.
      - C(reverted) reverts the VM to the specified checkpoint.
    type: str
    choices: [ present, absent, reverted ]
    default: present
author:
  - Ansible Cloud Team (@ansible)
'''

EXAMPLES = r'''
- name: Create a Pre-Patch checkpoint
  microsoft.hyperv.hv_checkpoint:
    vm_name: SQLServer01
    name: Pre-Patch
    state: present

- name: Revert to the Pre-Patch checkpoint
  microsoft.hyperv.hv_checkpoint:
    vm_name: SQLServer01
    name: Pre-Patch
    state: reverted

- name: Remove the Pre-Patch checkpoint
  microsoft.hyperv.hv_checkpoint:
    vm_name: SQLServer01
    name: Pre-Patch
    state: absent
'''

RETURN = r'''
name:
    description: Name of the checkpoint.
    returned: always
    type: str
    sample: Pre-Patch
vm_name:
    description: Name of the virtual machine.
    returned: always
    type: str
    sample: SQLServer01
state:
    description: The final state of the checkpoint.
    returned: always
    type: str
    sample: present
checkpoint:
    description: Detailed metadata about the checkpoint.
    returned: when state is present or reverted
    type: dict
    contains:
        id:
            description: Unique identifier of the checkpoint.
            type: str
            sample: 12345678-1234-1234-1234-1234567890ab
        creation_time:
            description: The timestamp when the checkpoint was created.
            type: str
            sample: "2026-03-17T12:00:00.0000000Z"
        parent_id:
            description: The unique identifier of the parent checkpoint.
            type: str
            sample: 00000000-0000-0000-0000-000000000000
'''
