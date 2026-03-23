# -*- coding: utf-8 -*-
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: hv_storage_pool
short_description: Manage Hyper-V Storage Resource Pools
description:
  - Create, manage, and remove storage resource pools on a Hyper-V host.
  - Supports VHD, ISO, and VFD pool types.
  - Resource pools are used for tracking and quota management across different departments or tenants.
options:
  name:
    description:
      - The name of the storage resource pool.
    type: str
    required: true
  type:
    description:
      - The type of the storage resource pool.
    type: str
    choices: [ VHD, ISO, VFD ]
    default: VHD
  paths:
    description:
      - A list of directory paths that are associated with the resource pool.
    type: list
    elements: str
  parent_name:
    description:
      - The name of the parent resource pool.
      - Defaults to C(Primordial).
    type: str
    default: Primordial
  state:
    description:
      - The desired state of the resource pool.
      - C(present) ensures the pool exists and is configured with the specified paths.
      - C(absent) ensures the pool is removed.
    type: str
    choices: [ present, absent ]
    default: present
author:
  - Ansible Cloud Team (@ansible)
'''

EXAMPLES = r'''
- name: Create an ISO resource pool for the HR department
  microsoft.hyperv.hv_storage_pool:
    name: HR_ISOs
    type: ISO
    paths:
      - "C:\\Storage\\HR\\ISOs"
    state: present

- name: Create a VHD resource pool with multiple paths
  microsoft.hyperv.hv_storage_pool:
    name: Production_VHDs
    type: VHD
    paths:
      - "C:\\Storage\\VHDs\\App01"
      - "C:\\Storage\\VHDs\\App02"

- name: Remove a storage pool
  microsoft.hyperv.hv_storage_pool:
    name: HR_ISOs
    type: ISO
    state: absent
'''

RETURN = r'''
name:
    description: Name of the resource pool.
    returned: always
    type: str
    sample: HR_ISOs
type:
    description: Type of the resource pool.
    returned: always
    type: str
    sample: ISO
paths:
    description: List of paths associated with the pool.
    returned: when state is present
    type: list
    elements: str
    sample: ["C:\\Storage\\HR\\ISOs"]
'''
