# -*- coding: utf-8 -*-
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: hv_processor
short_description: Manage Hyper-V Virtual Machine Processors (vCPU)
description:
  - Manage processor and vCPU configuration for Hyper-V Virtual Machines.
  - Supports setting vCPU count, resource limits, and reservations.
  - Allows exposing virtualization extensions (nested virtualization) to the guest OS.
  - Manages processor compatibility mode for live migrations across different hardware.
options:
  name:
    description:
      - The name of the virtual machine to configure.
    type: str
    required: true
    aliases: [ vm_name ]
  count:
    description:
      - The number of virtual processors (vCPUs) to allocate to the virtual machine.
    type: int
  compatibility_for_migration_enabled:
    description:
      - Specifies whether the virtual machine's processors should operate in compatibility mode.
      - Required when performing a live migration to a host with a different processor version.
    type: bool
  expose_virtualization_extensions:
    description:
      - Exposes hardware virtualization extensions to the virtual machine.
      - Enabling this allows nested virtualization (e.g., running Hyper-V or Docker/WSL2 inside the VM).
    type: bool
  enable_host_resource_protection:
    description:
      - Specifies whether host resource protection is enabled.
      - Protects the host from VMs that attempt to aggressively consume resources.
    type: bool
  maximum:
    description:
      - The maximum percentage of resources the virtual machine can consume.
    type: int
  reserve:
    description:
      - The guaranteed percentage of resources reserved for the virtual machine.
    type: int
  relative_weight:
    description:
      - The relative weight of the virtual machine compared to others when competing for resources.
    type: int
  hw_thread_count_per_core:
    description:
      - The number of hardware threads per core.
    type: int
author:
  - Ansible Cloud Team (@ansible)
'''

EXAMPLES = r'''
- name: Right-size a VM to 4 vCPUs and enable Nested Virtualization
  microsoft.hyperv.hv_processor:
    name: DockerHostVM
    count: 4
    expose_virtualization_extensions: true

- name: Enable compatibility mode for an impending Live Migration
  microsoft.hyperv.hv_processor:
    name: DatabaseVM
    compatibility_for_migration_enabled: true

- name: Limit CPU consumption to 80% with a 10% guarantee
  microsoft.hyperv.hv_processor:
    name: DevBoxVM
    maximum: 80
    reserve: 10
'''

RETURN = r'''
name:
    description: Name of the virtual machine.
    returned: always
    type: str
    sample: WebServer01
count:
    description: The number of allocated vCPUs.
    returned: always
    type: int
    sample: 4
compatibility_for_migration_enabled:
    description: The state of processor compatibility mode.
    returned: always
    type: bool
    sample: false
expose_virtualization_extensions:
    description: The state of exposed virtualization extensions (Nested Virtualization).
    returned: always
    type: bool
    sample: true
enable_host_resource_protection:
    description: The state of host resource protection.
    returned: always
    type: bool
    sample: false
maximum:
    description: The maximum processor limit.
    returned: always
    type: int
    sample: 100
reserve:
    description: The processor reservation percentage.
    returned: always
    type: int
    sample: 0
relative_weight:
    description: The processor weight.
    returned: always
    type: int
    sample: 100
hw_thread_count_per_core:
    description: The number of threads per core.
    returned: always
    type: int
    sample: 0
'''
