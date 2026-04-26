# -*- coding: utf-8 -*-
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: hv_vm_tag
short_description: Manage Hyper-V Virtual Machine Metadata Tags
description:
  - Manage key-value metadata tags for a Hyper-V Virtual Machine.
  - Since Hyper-V does not have a native tagging engine, this module serializes and stores tags as formatted key-value pairs within the VM's C(Notes) field.
  - This allows Ansible dynamic inventories to group and filter Hyper-V VMs based on custom metadata (e.g., Environment, Role, Owner).
options:
  vm_name:
    description:
      - The name of the virtual machine to tag.
    type: str
    required: true
    aliases: [ name ]
  tags:
    description:
      - A dictionary of key-value pairs representing the tags to apply.
      - Keys and values should be strings.
    type: dict
    required: true
  state:
    description:
      - The desired state of the tags.
      - C(present) ensures the specified tags are added or updated. Existing tags not specified in the dictionary are left untouched.
      - C(absent) ensures the specified tags are removed from the VM.
      - C(exact) ensures the VM has EXACTLY the tags specified. Any existing tags not in the dictionary will be removed.
    type: str
    choices: [ present, absent, exact ]
    default: present
author:
  - Ansible Cloud Team (@ansible)
'''

EXAMPLES = r'''
- name: Add or update Environment and Role tags (leaves other tags untouched)
  microsoft.hyperv.hv_vm_tag:
    vm_name: WebServer01
    state: present
    tags:
      Environment: Production
      Role: WebServer

- name: Enforce exact tags (removes any tag not listed here)
  microsoft.hyperv.hv_vm_tag:
    vm_name: WebServer01
    state: exact
    tags:
      Environment: Production
      Owner: DevOpsTeam

- name: Remove a specific tag
  microsoft.hyperv.hv_vm_tag:
    vm_name: WebServer01
    state: absent
    tags:
      Role: WebServer
'''

RETURN = r'''
vm_name:
    description: Name of the virtual machine.
    returned: always
    type: str
    sample: WebServer01
tags:
    description: The complete dictionary of tags currently applied to the VM after the module execution.
    returned: always
    type: dict
    sample: { "Environment": "Production", "Owner": "DevOpsTeam" }
'''
