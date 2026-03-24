# -*- coding: utf-8 -*-
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: hv_network_adapter
short_description: Manage Hyper-V Virtual Machine Network Adapters
description:
  - Add, remove, and manage Virtual Network Adapters on a Hyper-V Virtual Machine.
  - Supports configuring Virtual Switch connection, VLAN ID (Access/Trunk), MAC Address, and Bandwidth (QoS) limits.
options:
  vm_name:
    description:
      - The name of the virtual machine to manage the network adapter for.
    type: str
    required: true
  name:
    description:
      - The name of the virtual network adapter.
      - Defaults to C(Network Adapter) if only one adapter exists.
    type: str
    default: Network Adapter
  state:
    description:
      - The desired state of the network adapter.
      - C(present) ensures the adapter exists and is configured as specified.
      - C(absent) ensures the adapter is removed from the VM.
    type: str
    choices: [ present, absent ]
    default: present
  switch_name:
    description:
      - The name of the Virtual Switch to connect the adapter to.
    type: str
  vlan_mode:
    description:
      - The VLAN operation mode for the adapter.
      - C(Access) for a single VLAN ID.
      - C(Trunk) for multiple VLAN IDs.
      - C(Untagged) to disable VLAN tagging.
    type: str
    choices: [ Access, Trunk, Untagged ]
  vlan_id:
    description:
      - The VLAN ID to use when C(vlan_mode=Access).
    type: int
  native_vlan_id:
    description:
      - The native VLAN ID to use when C(vlan_mode=Trunk).
    type: int
  allowed_vlan_id_list:
    description:
      - The list of allowed VLAN IDs to use when C(vlan_mode=Trunk).
    type: list
    elements: int
  mac_address:
    description:
      - The static MAC address to assign to the adapter.
      - If provided, C(dynamic_mac_address) will be set to C(false).
    type: str
  dynamic_mac_address:
    description:
      - Specifies whether to use a dynamic MAC address.
    type: bool
  mac_address_spoofing:
    description:
      - Specifies whether to allow MAC address spoofing.
    type: bool
  maximum_bandwidth:
    description:
      - The maximum bandwidth in bits per second.
      - Accepts an integer or string with suffixes like "1Gbps" or "500Mbps".
    type: raw
  minimum_bandwidth_absolute:
    description:
      - The minimum bandwidth in bits per second.
      - Accepts an integer or string with suffixes like "100Mbps".
    type: raw
  minimum_bandwidth_weight:
    description:
      - The relative weight for bandwidth allocation (0-100).
    type: int
author:
  - Ansible Cloud Team (@ansible)
'''

EXAMPLES = r'''
- name: Create a production network adapter with VLAN 100
  microsoft.hyperv.hv_network_adapter:
    vm_name: WebServer01
    name: Production
    switch_name: ExternalSwitch
    vlan_mode: Access
    vlan_id: 100
    maximum_bandwidth: "1Gbps"

- name: Remove an old network adapter
  microsoft.hyperv.hv_network_adapter:
    vm_name: WebServer01
    name: Legacy
    state: absent
'''

RETURN = r'''
vm_name:
    description: Name of the virtual machine.
    returned: always
    type: str
    sample: WebServer01
name:
    description: Name of the network adapter.
    returned: always
    type: str
    sample: Production
state:
    description: Final state of the adapter.
    returned: always
    type: str
    sample: present
switch_name:
    description: Name of the Virtual Switch the adapter is connected to.
    returned: success
    type: str
    sample: ExternalSwitch
mac_address:
    description: The current MAC address of the adapter.
    returned: success
    type: str
    sample: 00155D010203
'''
