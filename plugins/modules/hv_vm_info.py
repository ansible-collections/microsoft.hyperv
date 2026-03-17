# -*- coding: utf-8 -*-
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: hv_vm_info
short_description: Gather information about Hyper-V Virtual Machines
description:
  - Gathers facts and information about one or all Virtual Machines on a Hyper-V host.
  - Returns structured data including state, uptime, ID, and generation.
options:
  name:
    description:
      - The name of the specific Virtual Machine to query.
      - If omitted, gathers information about all VMs on the host.
    type: str
    aliases: [ vm_name ]
author:
  - Ansible Cloud Team (@ansible)
'''

EXAMPLES = r'''
- name: Gather facts about all VMs
  microsoft.hyperv.hv_vm_info:

- name: Gather facts about a specific VM
  microsoft.hyperv.hv_vm_info:
    name: WebServer01
'''

RETURN = r'''
vms:
    description: A list of dictionaries containing VM information.
    returned: always
    type: list
    elements: dict
    sample: [
        {
            "name": "WebServer01",
            "state": "Running",
            "status": "OperatingNormally",
            "uptime_seconds": 3600,
            "id": "12345678-1234-1234-1234-1234567890ab",
            "generation": 2
        }
    ]
'''
