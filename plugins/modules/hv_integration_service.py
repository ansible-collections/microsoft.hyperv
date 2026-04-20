# -*- coding: utf-8 -*-
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: hv_integration_service
short_description: Manage Hyper-V Virtual Machine Integration Services
description:
  - Enable or disable specific integration services on a Hyper-V Virtual Machine.
  - Common services include C(Guest Service Interface), C(Heartbeat), C(Key-Value Pair Exchange), C(Shutdown), C(Time Synchronization), and C(VSS).
options:
  vm_name:
    description:
      - The name of the virtual machine.
    type: str
    required: true
    aliases: [ name ]
  service_name:
    description:
      - The name of the integration service to manage.
      - Common values include C(Guest Service Interface), C(Heartbeat), C(Key-Value Pair Exchange), C(Shutdown), C(Time Synchronization), and C(VSS).
    type: str
    required: true
  state:
    description:
      - The desired state of the integration service.
      - C(enabled) ensures the service is enabled.
      - C(disabled) ensures the service is disabled.
    type: str
    choices: [ enabled, disabled ]
    default: enabled
author:
  - Ansible Cloud Team (@ansible)
'''

EXAMPLES = r'''
- name: Enable Guest Service Interface (required for Copy-VMFile)
  microsoft.hyperv.hv_integration_service:
    vm_name: WebServer01
    service_name: "Guest Service Interface"
    state: enabled

- name: Disable Time Synchronization
  microsoft.hyperv.hv_integration_service:
    vm_name: DatabaseServer
    service_name: "Time Synchronization"
    state: disabled
'''

RETURN = r'''
vm_name:
    description: Name of the virtual machine.
    returned: always
    type: str
    sample: WebServer01
service_name:
    description: Name of the integration service.
    returned: always
    type: str
    sample: "Guest Service Interface"
state:
    description: The final state of the integration service.
    returned: always
    type: str
    sample: enabled
'''
