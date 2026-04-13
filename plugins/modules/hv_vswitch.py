# -*- coding: utf-8 -*-
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: hv_vswitch
short_description: Manage Hyper-V Virtual Switches and extensions
description:
  - Create, manage, and remove Hyper-V Virtual Switches.
  - Supports External, Internal, and Private switch types.
  - Manage Virtual Switch Extensions (Enable/Disable).
  - Configure advanced properties like bandwidth mode and teaming.
options:
  name:
    description:
      - The name of the virtual switch.
    type: str
    required: true
  state:
    description:
      - The desired state of the virtual switch.
    type: str
    choices: [ present, absent ]
    default: present
  switch_type:
    description:
      - The type of virtual switch to create.
      - Required when creating a new switch.
      - External switches require C(net_adapter_names).
    type: str
    choices: [ external, internal, private ]
  net_adapter_names:
    description:
      - A list of physical network adapter names to bind to an external switch.
      - Required when C(switch_type=external).
    type: list
    elements: str
  allow_management_os:
    description:
      - Whether the parent OS has access to the physical adapter.
      - Only valid for External switches.
    type: bool
  enable_embedded_teaming:
    description:
      - Whether to enable Switch Embedded Teaming (SET).
      - Only valid for External switches.
    type: bool
  minimum_bandwidth_mode:
    description:
      - The minimum bandwidth mode of the switch.
    type: str
    choices: [ None, Absolute, Weight, Default ]
  default_flow_minimum_bandwidth_absolute:
    description:
      - The default minimum bandwidth (in bytes) for a single flow.
    type: raw
  default_flow_minimum_bandwidth_weight:
    description:
      - The default minimum bandwidth weight for a single flow.
    type: int
  notes:
    description:
      - Notes associated with the virtual switch.
    type: str
  extensions:
    description:
      - A list of switch extensions to enable or disable.
    type: list
    elements: dict
    suboptions:
      name:
        description: Name or ID of the extension.
        type: str
        required: true
      state:
        description: Desired state of the extension.
        type: str
        choices: [ enabled, disabled ]
        required: true
author:
  - Ansible Cloud Team (@ansible)
'''

EXAMPLES = r'''
- name: Create a Private Virtual Switch
  microsoft.hyperv.hv_vswitch:
    name: PrivateSwitch
    switch_type: private
    state: present

- name: Create an External Virtual Switch with teaming
  microsoft.hyperv.hv_vswitch:
    name: ExternalTeam
    switch_type: external
    net_adapter_names:
      - "Ethernet 1"
      - "Ethernet 2"
    allow_management_os: true
    enable_embedded_teaming: true

- name: Enable an extension on a switch
  microsoft.hyperv.hv_vswitch:
    name: PublicSwitch
    extensions:
      - name: "Microsoft Windows Filtering Platform"
        state: enabled

- name: Remove a Virtual Switch
  microsoft.hyperv.hv_vswitch:
    name: OldSwitch
    state: absent
'''

RETURN = r'''
name:
    description: Name of the virtual switch.
    returned: always
    type: str
    sample: PublicSwitch
state:
    description: Final state of the virtual switch.
    returned: always
    type: str
    sample: present
switch_type:
    description: The type of virtual switch.
    returned: success
    type: str
    sample: External
notes:
    description: Notes associated with the virtual switch.
    returned: success
    type: str
    sample: "Production Switch"
allow_management_os:
    description: Whether the parent OS has access to the physical adapter.
    returned: success
    type: bool
    sample: true
minimum_bandwidth_mode:
    description: The minimum bandwidth mode of the switch.
    returned: success
    type: str
    sample: "Weight"
'''
