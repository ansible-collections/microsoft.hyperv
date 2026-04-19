# -*- coding: utf-8 -*-
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: hv_vm_guest_wait
short_description: Wait for VM guest agent and IP addresses to become available
description:
  - Blocks execution until the Hyper-V Integration Services (Guest Agent) report a specific state.
  - Can wait for the Guest Heartbeat to become 'Ok'.
  - Can wait for one or more IP addresses to be reported by the guest OS.
  - Useful after starting a VM to ensure it is ready for remote management (e.g., via WinRM or SSH).
options:
  name:
    description:
      - The name of the virtual machine.
    type: str
    required: true
    aliases: [ vm_name ]
  timeout:
    description:
      - Maximum time in seconds to wait for the desired state.
    type: int
    default: 300
  sleep_interval:
    description:
      - Time in seconds to sleep between polling attempts.
    type: int
    default: 5
  wait_for_ip:
    description:
      - Whether to wait for the guest to report at least one IP address.
    type: bool
    default: true
  expected_ip:
    description:
      - A specific IP address or CIDR range to wait for.
      - If provided, the module will wait until at least one of the VM's IP addresses matches this value.
      - Supports CIDR notation (e.g., C(192.168.1.0/24) or shorthand C(10/8)).
    type: str
  wait_for_heartbeat:
    description:
      - Whether to wait for the Hyper-V Heartbeat service to report C(Ok).
      - This indicates the Hyper-V Guest Agent is running and communicating.
    type: bool
    default: true
  adapter_name:
    description:
      - If provided, the module will only consider IP addresses from the network adapter with this name.
    type: str
author:
  - Ansible Cloud Team (@ansible)
'''

EXAMPLES = r'''
- name: Start VM and wait for it to be ready
  block:
    - name: Ensure VM is running
      microsoft.hyperv.hv_vm_state:
        name: WebServer01
        state: running

    - name: Wait for Guest Agent and any IP
      microsoft.hyperv.hv_vm_guest_wait:
        name: WebServer01
        timeout: 600
      register: guest_info

- name: Wait for a specific static IP on a specific adapter
  microsoft.hyperv.hv_vm_guest_wait:
    name: DatabaseServer
    adapter_name: "External Adapter"
    expected_ip: "192.168.1.50"
    timeout: 300
'''

RETURN = r'''
name:
    description: Name of the virtual machine.
    returned: always
    type: str
    sample: WebServer01
ip_addresses:
    description: List of all IP addresses reported by the guest OS.
    returned: always
    type: list
    elements: str
    sample: ["192.168.1.50", "fe80::100:200:300:400"]
heartbeat:
    description: The final status of the guest heartbeat.
    returned: always
    type: str
    sample: "Ok"
state:
    description: The current power state of the VM.
    returned: always
    type: str
    sample: "Running"
'''
