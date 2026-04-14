# -*- coding: utf-8 -*-
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: hv_network_acl
short_description: Manage Standard and Extended Network ACLs for Hyper-V VMs
description:
  - Add, remove, or update Standard and Extended Network Access Control Lists (ACLs) on a Hyper-V virtual network adapter.
  - Standard ACLs provide basic Layer 3 (IP/MAC) filtering.
  - Extended ACLs provide stateful Layer 4 (Port/Protocol) filtering with weighting.
options:
  vm_name:
    description:
      - The name of the virtual machine to apply the ACL to.
    type: str
    required: true
  adapter_name:
    description:
      - The name of the virtual network adapter on the VM.
    type: str
    required: true
  state:
    description:
      - The desired state of the ACL rule.
      - C(present) ensures the ACL is applied.
      - C(absent) ensures the ACL is removed.
    type: str
    choices: [ present, absent ]
    default: present
  acl_type:
    description:
      - The type of ACL to create.
      - Standard ACLs use C(Add-VMNetworkAdapterAcl).
      - Extended ACLs use C(Add-VMNetworkAdapterExtendedAcl).
    type: str
    choices: [ standard, extended ]
    default: standard
  action:
    description:
      - The action the ACL takes when traffic matches the rule.
      - C(allow) permits the traffic.
      - C(deny) blocks the traffic.
      - C(meter) (Standard only) counts the traffic without blocking it.
    type: str
    choices: [ allow, deny, meter ]
  direction:
    description:
      - The direction of the traffic the ACL applies to.
      - C(inbound) traffic coming into the VM.
      - C(outbound) traffic leaving the VM.
      - C(both) traffic in either direction (Standard only).
    type: str
    choices: [ inbound, outbound, both ]
  local_ip_address:
    description:
      - The local IP address (or subnet) for the rule. Use C(ANY) for all.
    type: str
  remote_ip_address:
    description:
      - The remote IP address (or subnet) for the rule. Use C(ANY) for all.
    type: str
  local_mac_address:
    description:
      - The local MAC address for the rule. Use C(ANY) for all. (Standard only).
    type: str
  remote_mac_address:
    description:
      - The remote MAC address for the rule. Use C(ANY) for all. (Standard only).
    type: str
  local_port:
    description:
      - The local port number or C(ANY). (Extended only).
    type: str
  remote_port:
    description:
      - The remote port number or C(ANY). (Extended only).
    type: str
  protocol:
    description:
      - The protocol for the rule (e.g., C(TCP), C(UDP), C(ANY)). (Extended only).
    type: str
  weight:
    description:
      - The weight (priority) of the extended ACL. Higher weights are evaluated first.
      - Required for Extended ACLs.
    type: int
  stateful:
    description:
      - Whether the extended ACL is stateful. (Extended only).
    type: bool
  idle_session_timeout:
    description:
      - The idle session timeout in seconds for a stateful rule. (Extended only).
    type: int
  isolation_id:
    description:
      - The isolation ID (VXLAN/NVGRE) the rule applies to. (Extended only).
    type: int
author:
  - Ansible Cloud Team (@ansible)
'''

EXAMPLES = r'''
- name: Block all inbound traffic from a specific IP (Standard)
  microsoft.hyperv.hv_network_acl:
    vm_name: WebServer01
    adapter_name: "Network Adapter"
    acl_type: standard
    direction: inbound
    action: deny
    remote_ip_address: "192.168.1.100"
    state: present

- name: Allow stateful inbound HTTPS traffic (Extended)
  microsoft.hyperv.hv_network_acl:
    vm_name: WebServer01
    adapter_name: "Network Adapter"
    acl_type: extended
    direction: inbound
    action: allow
    protocol: TCP
    local_port: "443"
    weight: 100
    stateful: true
    state: present

- name: Remove a specific extended ACL
  microsoft.hyperv.hv_network_acl:
    vm_name: WebServer01
    adapter_name: "Network Adapter"
    acl_type: extended
    direction: inbound
    weight: 100
    state: absent
'''

RETURN = r'''
state:
    description: The final state of the ACL.
    returned: always
    type: str
    sample: present
acl_type:
    description: The type of ACL configured.
    returned: always
    type: str
    sample: extended
action:
    description: The action configured for the rule.
    returned: success
    type: str
    sample: allow
direction:
    description: The traffic direction.
    returned: success
    type: str
    sample: inbound
weight:
    description: The rule priority weight (Extended only).
    returned: success
    type: int
    sample: 100
local_ip_address:
    description: The local IP address (or subnet) for the rule.
    returned: success
    type: str
    sample: "ANY"
remote_ip_address:
    description: The remote IP address (or subnet) for the rule.
    returned: success
    type: str
    sample: "192.168.1.100"
protocol:
    description: The protocol for the rule.
    returned: success
    type: str
    sample: "TCP"
local_port:
    description: The local port number.
    returned: success
    type: str
    sample: "ANY"
remote_port:
    description: The remote port number.
    returned: success
    type: str
    sample: "443"
'''
