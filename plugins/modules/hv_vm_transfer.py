# -*- coding: utf-8 -*-
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: hv_vm_transfer
short_description: Manage Hyper-V Virtual Machine Export and Import
description:
  - Export virtual machines to a specified path for backup or cloning.
  - Import virtual machines from a configuration file (.vmcx or .xml).
  - "Supports different import modes: Register in place, Restore, or Copy (cloning with new ID)."
options:
  name:
    description:
      - The name of the virtual machine.
      - For C(state=exported), this is the name of the existing VM to export.
      - For C(state=imported), this is the name to verify or assign to the imported VM.
    type: str
    required: true
  path:
    description:
      - For C(state=exported), the directory where the VM will be exported. A sub-folder named after the VM will be created here.
      - For C(state=imported), the full path to the VM configuration file (e.g., C(.vmcx) or C(.xml)).
    type: str
    required: true
  state:
    description:
      - The desired state of the VM transfer.
      - C(exported) ensures an export of the VM exists at the specified path.
      - C(imported) ensures the VM is imported into the Hyper-V host.
    type: str
    choices: [ exported, imported ]
    default: exported
  import_mode:
    description:
      - The mode to use when importing a VM.
      - C(register) registers the VM in place using the existing unique ID.
      - C(restore) copies the VM files to the default or specified location, keeping the unique ID.
      - C(copy) copies the VM files and generates a new unique ID (useful for cloning).
    type: str
    choices: [ register, restore, copy ]
    default: copy
  vhd_destination_path:
    description:
      - The path where the virtual hard disks will be stored during a C(restore) or C(copy) import.
    type: str
  virtual_machine_path:
    description:
      - The path where the VM configuration files will be stored during a C(restore) or C(copy) import.
    type: str
author:
  - Ansible Cloud Team (@ansible)
'''

EXAMPLES = r'''
- name: Export a VM for backup
  microsoft.hyperv.hv_vm_transfer:
    name: WebServer01
    path: "D:\\Backups"
    state: exported

- name: Import a VM as a clone (Copy mode)
  microsoft.hyperv.hv_vm_transfer:
    name: WebServer01_Clone
    path: "D:\\Backups\\WebServer01\\Virtual Machines\\GUID.vmcx"
    state: imported
    import_mode: copy
    virtual_machine_path: "C:\\ProgramData\\Microsoft\\Windows\\Hyper-V"
    vhd_destination_path: "C:\\Users\\Public\\Documents\\Hyper-V\\Virtual Hard Disks"

- name: Register a VM in place
  microsoft.hyperv.hv_vm_transfer:
    name: WebServer02
    path: "C:\\ExternalStorage\\WebServer02\\Virtual Machines\\GUID.vmcx"
    state: imported
    import_mode: register
'''

RETURN = r'''
name:
    description: Name of the virtual machine.
    returned: always
    type: str
    sample: WebServer01
path:
    description: The path used for the operation.
    returned: always
    type: str
    sample: "D:\\Backups\\WebServer01"
id:
    description: The unique ID of the imported or exported VM.
    returned: success
    type: str
    sample: "506549c7-e374-4b53-911e-089224412953"
'''
