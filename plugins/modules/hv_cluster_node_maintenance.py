# -*- coding: utf-8 -*-
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: hv_cluster_node_maintenance
short_description: Manage Hyper-V Cluster Node Maintenance Mode
description:
  - Suspend (Pause) or Resume a cluster node in a Hyper-V Failover Cluster.
  - When suspending, the module can orchestrate the "Drain" process to gracefully live-migrate all highly
    available roles (like VMs) to other nodes, ensuring zero-downtime maintenance or patching.
  - When resuming, the module can trigger a "Failback" to automatically move roles back to the node.
options:
  node_name:
    description:
      - The name of the cluster node to manage.
    type: str
    required: true
    aliases: [ name ]
  state:
    description:
      - The desired maintenance state of the cluster node.
      - C(maintenance) ensures the node is suspended/paused.
      - C(active) ensures the node is resumed and operational.
    type: str
    choices: [ maintenance, active ]
    default: maintenance
  drain:
    description:
      - If C(true) and C(state=maintenance), the module will drain all clustered roles off the node during suspension.
      - Corresponds to the C(-Drain) parameter in PowerShell.
    type: bool
    default: true
  target_node:
    description:
      - When C(drain) is C(true), explicitly specify the destination node to move the roles to.
      - If omitted, the cluster automatically determines the best destination for each role.
    type: str
  wait:
    description:
      - If C(true), the module will wait for the drain operation to complete before returning.
    type: bool
    default: true
  failback:
    description:
      - If C(true) and C(state=active), the module will attempt to fail roles back to this node upon resuming.
    type: str
    choices: [ "On", "Off" ]
author:
  - Ansible Cloud Team (@ansible)
'''

EXAMPLES = r'''
- name: Place a node in maintenance mode and drain all VMs
  microsoft.hyperv.hv_cluster_node_maintenance:
    node_name: HV-Node01
    state: maintenance
    drain: true
    wait: true

- name: Resume the node and failback roles
  microsoft.hyperv.hv_cluster_node_maintenance:
    node_name: HV-Node01
    state: active
    failback: "On"
'''

RETURN = r'''
node_name:
    description: Name of the cluster node.
    returned: always
    type: str
    sample: HV-Node01
state:
    description: The final state of the node. Returns C(maintenance) or C(active).
    returned: always
    type: str
    sample: maintenance
'''
