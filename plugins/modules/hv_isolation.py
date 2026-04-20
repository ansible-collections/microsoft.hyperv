# -*- coding: utf-8 -*-
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: hv_isolation
short_description: Manage Hyper-V Network Adapter Isolation (SDN)
description:
  - Configure multi-tenant network isolation settings on a Hyper-V Virtual Machine Network Adapter.
  - Supports Software Defined Networking (SDN) isolation modes like VXLAN/NVGRE (NativeVirtualSubnet, ExternalVirtualSubnet) or VLAN.
  - Allows setting the Virtual Subnet ID (VSID) or Default Isolation ID.
options:
  vm_name:
    description:
      - The name of the virtual machine.
    type: str
    required: true
    aliases: [ name ]
  adapter_name:
    description:
      - The name of the virtual network adapter to configure.
    type: str
    required: true
  isolation_mode:
    description:
      - The isolation mode for the network adapter.
      - C(None) disables isolation.
      - C(NativeVirtualSubnet) and C(ExternalVirtualSubnet) are used for VXLAN/NVGRE multi-tenant isolation.
      - C(Vlan) uses traditional VLAN isolation.
    type: str
    choices: [ "None", "NativeVirtualSubnet", "ExternalVirtualSubnet", "Vlan" ]
  default_isolation_id:
    description:
      - The Default Isolation ID or Virtual Subnet ID (VSID).
      - Set to C(0) to disable or reset.
    type: int
    aliases: [ vsid ]
  multi_tenant_stack:
    description:
      - Whether the multi-tenant stack is enabled on the adapter.
    type: str
    choices: [ "On", "Off" ]
  allow_untagged_traffic:
    description:
      - Specifies whether untagged traffic is allowed.
    type: str
    choices: [ "On", "Off" ]
author:
  - Ansible Cloud Team (@ansible)
'''

EXAMPLES = r'''
- name: Configure VXLAN isolation with VSID 5000
  microsoft.hyperv.hv_isolation:
    vm_name: Tenant01-Web
    adapter_name: "Network Adapter"
    isolation_mode: NativeVirtualSubnet
    vsid: 5000
    multi_tenant_stack: true

- name: Disable isolation
  microsoft.hyperv.hv_isolation:
    vm_name: Tenant01-Web
    adapter_name: "Network Adapter"
    isolation_mode: "None"
    vsid: 0
    multi_tenant_stack: false
'''

RETURN = r'''
vm_name:
    description: Name of the virtual machine.
    returned: always
    type: str
    sample: Tenant01-Web
adapter_name:
    description: Name of the virtual network adapter.
    returned: always
    type: str
    sample: "Network Adapter"
isolation_mode:
    description: The current isolation mode.
    returned: always
    type: str
    sample: NativeVirtualSubnet
default_isolation_id:
    description: The current Virtual Subnet ID (VSID).
    returned: always
    type: int
    sample: 5000
multi_tenant_stack:
    description: Status of the multi-tenant stack.
    returned: always
    type: bool
    sample: true
'''
