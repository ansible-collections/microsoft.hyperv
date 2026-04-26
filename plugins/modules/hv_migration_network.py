# -*- coding: utf-8 -*-
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: hv_migration_network
short_description: Manage Hyper-V Migration Networks
description:
  - Define and prioritize which network subnets are allowed to carry Live Migration traffic on a Hyper-V host.
  - This is critical for performance isolation, ensuring that heavy migration traffic does not saturate management or VM data networks.
options:
  subnet:
    description:
      - The IPv4 or IPv6 subnet to manage for migration traffic (e.g., C(10.0.0.0/24) or C(192.168.1.50/32)).
      - This acts as the unique identifier for the migration network rule.
    type: str
    required: true
  priority:
    description:
      - The priority of the migration network. Lower numbers indicate higher priority.
      - Hyper-V will attempt to route migration traffic over networks with lower priority numbers first.
      - Only applicable when C(state=present).
    type: int
  state:
    description:
      - The desired state of the migration network rule.
      - C(present) ensures the subnet is added and its priority is correctly configured.
      - C(absent) ensures the subnet is removed from the list of allowed migration networks.
    type: str
    choices: [ present, absent ]
    default: present
author:
  - Ansible Cloud Team (@ansible)
'''

EXAMPLES = r'''
- name: Add a dedicated migration network with highest priority
  microsoft.hyperv.hv_migration_network:
    subnet: "192.168.100.0/24"
    priority: 1
    state: present

- name: Update the priority of an existing migration network
  microsoft.hyperv.hv_migration_network:
    subnet: "10.0.0.0/8"
    priority: 10
    state: present

- name: Remove a subnet from allowed migration networks
  microsoft.hyperv.hv_migration_network:
    subnet: "172.16.0.0/16"
    state: absent
'''

RETURN = r'''
subnet:
    description: The specified subnet.
    returned: always
    type: str
    sample: "192.168.100.0/24"
priority:
    description: The priority assigned to the subnet.
    returned: when state is present
    type: int
    sample: 1
'''
