# -*- coding: utf-8 -*-
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: hv_com_port
short_description: Manage Hyper-V Virtual Machine Serial (COM) Ports
description:
  - Configure serial (COM) ports on a Hyper-V Virtual Machine.
  - Map COM ports to named pipes for kernel debugging or legacy application support.
  - Set the debugger mode for COM ports.
options:
  vm_name:
    description:
      - The name of the virtual machine.
    type: str
    required: true
    aliases: [ name ]
  number:
    description:
      - The number of the COM port to configure (typically 1 or 2).
    type: int
    required: true
    choices: [ 1, 2 ]
  path:
    description:
      - The path to the named pipe or file to map the COM port to.
      - To disconnect the COM port, provide an empty string.
    type: str
  debugger_mode:
    description:
      - Whether to enable debugger mode on the COM port.
    type: str
    choices: [ "On", "Off" ]
author:
  - Ansible Cloud Team (@ansible)
'''

EXAMPLES = r'''
- name: Map COM 1 to a named pipe for debugging
  microsoft.hyperv.hv_com_port:
    vm_name: WebServer01
    number: 1
    path: "\\\\.\\pipe\\debugpipe"
    debugger_mode: On

- name: Disconnect COM 2
  microsoft.hyperv.hv_com_port:
    vm_name: WebServer01
    number: 2
    path: ""
'''

RETURN = r'''
vm_name:
    description: Name of the virtual machine.
    returned: always
    type: str
    sample: WebServer01
number:
    description: The number of the configured COM port.
    returned: always
    type: int
    sample: 1
path:
    description: The current path mapped to the COM port.
    returned: always
    type: str
    sample: "\\\\.\\pipe\\debugpipe"
debugger_mode:
    description: The current debugger mode status.
    returned: always
    type: str
    sample: "On"
'''
