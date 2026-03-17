# -*- coding: utf-8 -*-
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: hv_host_info
short_description: Gather facts about the Hyper-V host
description:
  - Gathers hardware stats, OS version facts, and Hyper-V configuration from the host.
  - Returns structured data including uptime, memory usage, CPU type, and logical switch configuration.
  - Useful for validation of host capacity before provisioning new workloads.
author:
  - Ansible Cloud Team (@ansible)
'''

EXAMPLES = r'''
- name: Gather facts about the Hyper-V host
  microsoft.hyperv.hv_host_info:
  register: host_facts

- name: Print the host memory capacity
  ansible.builtin.debug:
    msg: "Total memory bytes: {{ host_facts.host_info.memory.total_bytes }}"
'''

RETURN = r'''
host_info:
    description: A dictionary containing Hyper-V host information.
    returned: always
    type: dict
    sample: {
        "os": {
            "caption": "Microsoft Windows Server 2025 Standard Evaluation",
            "version": "10.0.26100",
            "uptime_seconds": 3600,
            "last_boot_up_time": "2026-03-17T09:00:00.0000000Z"
        },
        "memory": {
            "total_bytes": 17159315456,
            "free_bytes": 14062620672
        },
        "processors": [
            {
                "name": "Intel(R) Xeon(R) Silver 4114 CPU @ 2.20GHz",
                "cores": 1,
                "logical_processors": 1
            }
        ],
        "hyperv": {
            "name": "WIN-LOTKV8386GO",
            "logical_processor_count": 8,
            "memory_capacity_bytes": 17159315456,
            "virtual_machine_path": "C:\\ProgramData\\Microsoft\\Windows\\Hyper-V",
            "virtual_hard_disk_path": "C:\\ProgramData\\Microsoft\\Windows\\Virtual Hard Disks",
            "supported_vm_versions": ["8.0", "8.1", "9.0"]
        },
        "virtual_switches": []
    }
'''
