# -*- coding: utf-8 -*-
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: hv_san_adapter
short_description: Manage Hyper-V Virtual Fibre Channel HBAs
description:
  - Add, remove, or configure virtual Fibre Channel Host Bus Adapters (vHBA) on a Hyper-V Virtual Machine.
  - This enables direct access to Fibre Channel SAN storage for virtualized workloads, often used in Guest Clustering scenarios.
options:
  vm_name:
    description:
      - The name of the virtual machine.
    type: str
    required: true
    aliases: [ name, vm ]
  san_name:
    description:
      - The name of the Virtual SAN on the Hyper-V host to which the vHBA will be connected.
      - Required when C(state=present) and creating a new adapter.
    type: str
  wwn_set_a:
    description:
      - A dictionary containing World Wide Node Name (WWNN) and World Wide Port Name (WWPN) for Set A.
      - Required if not using C(generate_wwn).
    type: dict
    suboptions:
      wwnn:
        description: World Wide Node Name.
        type: str
      wwpn:
        description: World Wide Port Name.
        type: str
  wwn_set_b:
    description:
      - A dictionary containing World Wide Node Name (WWNN) and World Wide Port Name (WWPN) for Set B.
      - Required if not using C(generate_wwn).
    type: dict
    suboptions:
      wwnn:
        description: World Wide Node Name.
        type: str
      wwpn:
        description: World Wide Port Name.
        type: str
  generate_wwn:
    description:
      - Whether to automatically generate unique World Wide Names for the adapter.
    type: bool
    default: true
  state:
    description:
      - The desired state of the virtual HBA.
      - C(present) ensures the vHBA is attached and configured.
      - C(absent) ensures the vHBA is removed from the VM.
    type: str
    choices: [ present, absent ]
    default: present
author:
  - Ansible Cloud Team (@ansible)
'''

EXAMPLES = r'''
- name: Add a virtual HBA to a VM using auto-generated WWNs
  microsoft.hyperv.hv_san_adapter:
    vm_name: SQLCluster01
    san_name: "ProductionSAN"
    generate_wwn: true
    state: present

- name: Add a virtual HBA with specific WWNs
  microsoft.hyperv.hv_san_adapter:
    vm_name: SQLCluster01
    san_name: "ProductionSAN"
    generate_wwn: false
    wwn_set_a:
      wwnn: "C003FF5544332211"
      wwpn: "C003FF5544332212"
    wwn_set_b:
      wwnn: "C003FF5544332213"
      wwpn: "C003FF5544332214"

- name: Remove a virtual HBA
  microsoft.hyperv.hv_san_adapter:
    vm_name: SQLCluster01
    state: absent
'''

RETURN = r'''
vm_name:
    description: Name of the virtual machine.
    returned: always
    type: str
    sample: SQLCluster01
san_name:
    description: The name of the connected Virtual SAN.
    returned: when state is present
    type: str
    sample: "ProductionSAN"
wwn_set_a:
    description: The assigned WWNN and WWPN for Set A.
    returned: when state is present
    type: dict
    sample: { "wwnn": "C003FF5544332211", "wwpn": "C003FF5544332212" }
wwn_set_b:
    description: The assigned WWNN and WWPN for Set B.
    returned: when state is present
    type: dict
    sample: { "wwnn": "C003FF5544332213", "wwpn": "C003FF5544332214" }
'''
