# -*- coding: utf-8 -*-
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: hv_vm_group
short_description: Manage Hyper-V Virtual Machine Groups
description:
  - Create, remove, and manage members of Hyper-V Virtual Machine Groups.
  - VM Groups are used to organize virtual machines for collective operations and to define placement rules like anti-affinity.
  - Supports both C(VMCollectionType) (groups of VMs) and C(ManagementCollectionType) (groups of other groups).
options:
  name:
    description:
      - The name of the VM group.
    type: str
    required: true
  group_type:
    description:
      - The type of the group.
      - C(VMCollectionType) is for groups containing virtual machines.
      - C(ManagementCollectionType) is for groups containing other VM groups (nested groups).
    type: str
    choices: [ VMCollectionType, ManagementCollectionType ]
    default: VMCollectionType
  vm_members:
    description:
      - A list of virtual machine names to include in the group.
      - Only applicable for C(group_type=VMCollectionType).
    type: list
    elements: str
  group_members:
    description:
      - A list of VM group names to include as nested members.
      - Only applicable for C(group_type=ManagementCollectionType).
    type: list
    elements: str
  state:
    description:
      - The desired state of the VM group.
      - C(present) ensures the group exists and has the specified members.
      - C(absent) ensures the group is removed.
    type: str
    choices: [ present, absent ]
    default: present
author:
  - Ansible Cloud Team (@ansible)
'''

EXAMPLES = r'''
- name: Create a VM group for SQL servers
  microsoft.hyperv.hv_vm_group:
    name: SQL-Cluster-Group
    group_type: VMCollectionType
    vm_members:
      - SQL01
      - SQL02

- name: Create a management group containing other groups
  microsoft.hyperv.hv_vm_group:
    name: All-Production-Apps
    group_type: ManagementCollectionType
    group_members:
      - SQL-Cluster-Group
      - Web-Farm-Group

- name: Remove a VM group
  microsoft.hyperv.hv_vm_group:
    name: Legacy-Group
    state: absent
'''

RETURN = r'''
name:
    description: Name of the VM group.
    returned: always
    type: str
    sample: SQL-Cluster-Group
group_type:
    description: Type of the group.
    returned: always
    type: str
    sample: VMCollectionType
vm_members:
    description: List of virtual machine names in the group.
    returned: when group_type is VMCollectionType
    type: list
    elements: str
    sample: ["SQL01", "SQL02"]
group_members:
    description: List of nested VM group names in the group.
    returned: when group_type is ManagementCollectionType
    type: list
    elements: str
    sample: ["SQL-Cluster-Group"]
'''
