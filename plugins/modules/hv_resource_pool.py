# -*- coding: utf-8 -*-
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: hv_resource_pool
short_description: Manage Hyper-V resource pools
description:
  - Create, remove, and manage Hyper-V resource pools for processor, memory, ethernet, and storage.
  - Resource pools are used to group resources for metering, chargeback, or departmental isolation.
options:
  name:
    description:
      - The name of the resource pool.
    type: str
    required: true
  pool_type:
    description:
      - The type of resources managed by the pool.
    type: str
    required: true
    choices: [ Processor, Memory, Ethernet, VHD, ISO, VFD, FibreChannelConnection, PciExpress ]
  state:
    description:
      - The desired state of the resource pool.
      - C(present) ensures the pool exists.
      - C(absent) ensures the pool is removed.
    type: str
    choices: [ present, absent ]
    default: present
author:
  - Ansible Cloud Team (@ansible)
'''

EXAMPLES = r'''
- name: Create a processor resource pool for the Finance department
  microsoft.hyperv.hv_resource_pool:
    name: Finance_CPU_Pool
    pool_type: Processor
    state: present

- name: Remove an old ethernet resource pool
  microsoft.hyperv.hv_resource_pool:
    name: Legacy_Net_Pool
    pool_type: Ethernet
    state: absent
'''

RETURN = r'''
name:
    description: Name of the resource pool.
    returned: always
    type: str
    sample: Finance_CPU_Pool
pool_type:
    description: Type of the resource pool.
    returned: always
    type: str
    sample: Processor
state:
    description: Final state of the resource pool.
    returned: always
    type: str
    sample: present
'''
