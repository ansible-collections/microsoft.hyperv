# -*- coding: utf-8 -*-
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: hv_memory
short_description: Manage Hyper-V Virtual Machine Memory Settings
description:
  - Manage memory allocation for Hyper-V Virtual Machines.
  - Configure Static RAM or enable Dynamic Memory (Dynamic RAM) to optimize host density.
  - Allows precise tuning of Startup, Minimum, Maximum, Buffer, and Priority settings.
options:
  name:
    description:
      - The name of the virtual machine to configure.
    type: str
    required: true
    aliases: [ vm_name ]
  dynamic_memory_enabled:
    description:
      - Specifies whether Dynamic Memory should be enabled.
      - Enabling this allows the host to reclaim unused memory from the VM to increase overall density.
    type: bool
  startup_bytes:
    description:
      - The amount of memory the VM requires to start up.
      - When Dynamic Memory is disabled, this effectively acts as the static RAM assignment.
      - Accepts an integer in bytes or a string like "4GB" or "1024MB".
    type: raw
  minimum_bytes:
    description:
      - The minimum amount of memory the VM will be allocated when Dynamic Memory is enabled.
      - Accepts an integer in bytes or a string like "512MB".
    type: raw
  maximum_bytes:
    description:
      - The maximum amount of memory the VM can grow to consume when Dynamic Memory is enabled.
      - Accepts an integer in bytes or a string like "16GB".
    type: raw
  buffer:
    description:
      - The percentage of memory the host should attempt to keep free as a buffer within the VM.
    type: int
  priority:
    description:
      - The memory weight/priority of the virtual machine when the host is under memory pressure.
      - Accepts an integer between 0 and 100.
    type: int
author:
  - Ansible Cloud Team (@ansible)
'''

EXAMPLES = r'''
- name: Configure Static Memory (8GB)
  microsoft.hyperv.hv_memory:
    name: StaticAppVM
    dynamic_memory_enabled: false
    startup_bytes: "8GB"

- name: Configure Dynamic Memory for high density (4GB to 16GB)
  microsoft.hyperv.hv_memory:
    name: DensityOptimizedVM
    dynamic_memory_enabled: true
    startup_bytes: "4GB"
    minimum_bytes: "2GB"
    maximum_bytes: "16GB"
    buffer: 20
    priority: 80
'''

RETURN = r'''
name:
    description: Name of the virtual machine.
    returned: always
    type: str
    sample: WebServer01
dynamic_memory_enabled:
    description: The final state of Dynamic Memory on the VM.
    returned: always
    type: bool
    sample: true
startup_bytes:
    description: The startup memory assigned to the VM, in bytes.
    returned: always
    type: int
    sample: 4294967296
minimum_bytes:
    description: The minimum memory guaranteed to the VM, in bytes.
    returned: always
    type: int
    sample: 2147483648
maximum_bytes:
    description: The maximum memory the VM can consume, in bytes.
    returned: always
    type: int
    sample: 17179869184
buffer:
    description: The current memory buffer percentage.
    returned: always
    type: int
    sample: 20
priority:
    description: The current memory priority weight.
    returned: always
    type: int
    sample: 50
'''
