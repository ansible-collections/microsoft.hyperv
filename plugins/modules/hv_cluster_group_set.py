# -*- coding: utf-8 -*-
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: hv_cluster_group_set
short_description: Manage Hyper-V Cluster Group Sets (Anti-Affinity)
description:
  - Create and manage Cluster Group Sets in a Hyper-V Failover Cluster.
  - Cluster Group Sets are primarily used to define strict dependencies or Anti-Affinity rules
    (ensuring high-availability by keeping redundant VMs on separate physical nodes).
options:
  name:
    description:
      - The name of the Cluster Group Set.
    type: str
    required: true
  groups:
    description:
      - A list of Virtual Machine names or Cluster Role names to include in this set.
    type: list
    elements: str
  provider:
    description:
      - The name of the provider set.
      - Use this to create a dependency where this set depends on the C(provider) set.
      - Can be used to establish Anti-Affinity rules.
    type: str
  state:
    description:
      - The desired state of the cluster group set.
      - C(present) ensures the set exists, contains the specified groups, and has the correct dependencies.
      - C(absent) ensures the set is removed from the cluster.
    type: str
    choices: [ present, absent ]
    default: present
author:
  - Ansible Cloud Team (@ansible)
'''

EXAMPLES = r'''
- name: Create an Anti-Affinity Group Set for SQL Servers
  microsoft.hyperv.hv_cluster_group_set:
    name: SQL-AntiAffinity-Set
    groups:
      - SQLVM01
      - SQLVM02
    state: present

- name: Create a dependency where App tier waits for DB tier
  microsoft.hyperv.hv_cluster_group_set:
    name: App-Tier-Set
    groups:
      - AppVM01
      - AppVM02
    provider: DB-Tier-Set
    state: present
'''

RETURN = r'''
name:
    description: Name of the Cluster Group Set.
    returned: always
    type: str
    sample: SQL-AntiAffinity-Set
groups:
    description: List of groups/VMs contained in the set.
    returned: when state is present
    type: list
    elements: str
    sample: ["SQLVM01", "SQLVM02"]
provider:
    description: The name of the provider set this set depends on.
    returned: when state is present and configured
    type: str
    sample: DB-Tier-Set
'''
