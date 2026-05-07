# -*- coding: utf-8 -*-
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: hv_hardware_passthrough
short_description: Manage physical hardware passthrough to Hyper-V VMs
description:
  - Configure GPU partitioning (GPU-P) or Discrete Device Assignment (DDA) to provide physical hardware access to virtual machines.
  - GPU Partitioning allows sharing a physical GPU among multiple VMs with performance isolation.
  - Discrete Device Assignment provides exclusive access to physical PCIe devices (like NVMe drives or specialized GPUs).
  - The VM must be in the 'Off' state to add or remove assignable devices.
options:
  vm_name:
    description:
      - The name of the virtual machine.
    type: str
    required: true
    aliases: [ name ]
  device_type:
    description:
      - The type of passthrough device to manage.
      - C(gpu_partition) manages shared GPU resources.
      - C(dda) manages exclusive PCIe device assignment.
    type: str
    required: true
    choices: [ gpu_partition, dda ]
  gpu_name:
    description:
      - The name or instance ID of the physical GPU to partition.
      - Required when C(device_type) is C(gpu_partition) and C(state) is C(present).
    type: str
  partition_count:
    description:
      - The number of partitions to create on the GPU.
      - Used with C(device_type) is C(gpu_partition).
    type: int
  device_location_path:
    description:
      - The PCI location path of the device to assign (e.g., "PCIROOT(0)#PCI(0300)#PCI(0000)").
      - Required when C(device_type) is C(dda) and C(state) is C(present).
    type: str
  state:
    description:
      - The desired state of the passthrough configuration.
      - C(present) ensures the device is assigned/partitioned.
      - C(absent) ensures the device is removed from the VM.
    type: str
    choices: [ present, absent ]
    default: present
author:
  - Ansible Cloud Team (@ansible)
'''

EXAMPLES = r'''
- name: Assign a GPU partition to a VM
  microsoft.hyperv.hv_hardware_passthrough:
    vm_name: AI-Worker-01
    device_type: gpu_partition
    gpu_name: "NVIDIA Tesla T4"
    partition_count: 4
    state: present

- name: Assign an NVMe drive via DDA
  microsoft.hyperv.hv_hardware_passthrough:
    vm_name: DB-Server-01
    device_type: dda
    device_location_path: "PCIROOT(0)#PCI(0100)#PCI(0000)"
    state: present

- name: Remove all assignable devices from a VM
  microsoft.hyperv.hv_hardware_passthrough:
    vm_name: DB-Server-01
    device_type: dda
    state: absent
'''

RETURN = r'''
vm_name:
    description: Name of the virtual machine.
    returned: always
    type: str
    sample: AI-Worker-01
device_type:
    description: The type of device managed.
    returned: always
    type: str
    sample: gpu_partition
state:
    description: Final state of the device passthrough.
    returned: always
    type: str
    sample: present
'''
