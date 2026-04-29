# -*- coding: utf-8 -*-
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: hv_replication
short_description: Manage Hyper-V Virtual Machine Replication
description:
  - Enable, configure, or disable Hyper-V Replica for a specific virtual machine.
  - Hyper-V Replica provides asynchronous, host-based replication for Disaster Recovery (DR).
options:
  vm_name:
    description:
      - The name of the virtual machine to manage replication for.
    type: str
    required: true
    aliases: [ name ]
  replica_server:
    description:
      - The FQDN or NetBIOS name of the destination Replica server.
      - Required when C(state=present).
    type: str
  replica_port:
    description:
      - The port used to transmit replication traffic to the Replica server.
      - Default is 80 (HTTP) or 443 (HTTPS) depending on the authentication type.
    type: int
  authentication_type:
    description:
      - The authentication protocol to use for replication.
      - C(Kerberos) transmits data over HTTP (unencrypted) but requires Active Directory.
      - C(Certificate) transmits data over HTTPS (encrypted) and requires certificate infrastructure.
    type: str
    choices: [ Kerberos, Certificate ]
    default: Kerberos
  certificate_thumbprint:
    description:
      - The thumbprint of the certificate to use for HTTPS replication.
      - Required if C(authentication_type) is C(Certificate).
    type: str
  frequency_sec:
    description:
      - The replication frequency in seconds.
      - Determines how often changes are sent to the Replica server.
    type: int
    choices: [ 30, 300, 900 ]
    default: 300
  compression_enabled:
    description:
      - Specifies whether replication traffic should be compressed before transmission.
    type: bool
    default: true
  start_initial_replication:
    description:
      - If C(true), the module will automatically initiate the initial replication sync after enabling replication.
      - Has no effect if replication is already active.
    type: bool
    default: false
  state:
    description:
      - The desired replication state for the virtual machine.
      - C(present) enables replication with the specified settings.
      - C(absent) completely removes and disables replication for the VM.
    type: str
    choices: [ present, absent ]
    default: present
author:
  - Ansible Cloud Team (@ansible)
'''

EXAMPLES = r'''
- name: Enable Kerberos replication for a VM (every 5 minutes)
  microsoft.hyperv.hv_replication:
    vm_name: WebServer01
    replica_server: dr-host-01.contoso.local
    authentication_type: Kerberos
    frequency_sec: 300
    state: present

- name: Disable replication for a VM
  microsoft.hyperv.hv_replication:
    vm_name: WebServer01
    state: absent
'''

RETURN = r'''
vm_name:
    description: Name of the virtual machine.
    returned: always
    type: str
    sample: WebServer01
replica_server:
    description: The destination server receiving the replication traffic.
    returned: when state is present
    type: str
    sample: dr-host-01.contoso.local
authentication_type:
    description: The authentication type used.
    returned: when state is present
    type: str
    sample: Kerberos
frequency_sec:
    description: The replication frequency in seconds.
    returned: when state is present
    type: int
    sample: 300
state:
    description: The final replication state.
    returned: always
    type: str
    sample: present
'''
