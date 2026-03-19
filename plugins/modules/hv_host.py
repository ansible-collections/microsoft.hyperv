# -*- coding: utf-8 -*-
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: hv_host
short_description: Manage Hyper-V Host Configuration and Console Settings
description:
  - Manage global host-level settings for the Hyper-V hypervisor.
  - Supports configuring default VM and VHD storage paths.
  - Controls host performance characteristics like NUMA Spanning.
  - Manages console connection policies like Enhanced Session Mode.
options:
  virtual_machine_path:
    description:
      - The default directory path on the host where new virtual machine configuration files are stored.
    type: str
  virtual_hard_disk_path:
    description:
      - The default directory path on the host where new virtual hard disks are created.
    type: str
  numa_spanning_enabled:
    description:
      - Specifies whether virtual machines can allocate memory spanning across multiple NUMA nodes on the host.
      - Disabling this enforces NUMA node boundaries for VMs, prioritizing predictable performance over overall density.
    type: bool
  enable_enhanced_session_mode:
    description:
      - Determines whether Enhanced Session Mode is permitted for VM console connections (VMConnect).
      - Enhanced Session Mode allows redirection of local devices (clipboard, audio, printers) to the VM via VMBus.
    type: bool
author:
  - Ansible Cloud Team (@ansible)
'''

EXAMPLES = r'''
- name: Configure standard paths and disable NUMA spanning
  microsoft.hyperv.hv_host:
    virtual_machine_path: "D:\\Hyper-V\\VMs"
    virtual_hard_disk_path: "D:\\Hyper-V\\Virtual Hard Disks"
    numa_spanning_enabled: false

- name: Enable Enhanced Session Mode for console users
  microsoft.hyperv.hv_host:
    enable_enhanced_session_mode: true
'''

RETURN = r'''
virtual_machine_path:
    description: The final default directory for new virtual machine configurations.
    returned: always
    type: str
    sample: "C:\\ProgramData\\Microsoft\\Windows\\Hyper-V"
virtual_hard_disk_path:
    description: The final default directory for new virtual hard disks.
    returned: always
    type: str
    sample: "C:\\ProgramData\\Microsoft\\Windows\\Virtual Hard Disks"
numa_spanning_enabled:
    description: The final state of NUMA Spanning on the host.
    returned: always
    type: bool
    sample: true
enable_enhanced_session_mode:
    description: The final state of Enhanced Session Mode on the host.
    returned: always
    type: bool
    sample: false
'''
