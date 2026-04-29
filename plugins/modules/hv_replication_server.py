# -*- coding: utf-8 -*-
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: hv_replication_server
short_description: Manage Hyper-V Replica Server Settings
description:
  - Configure a Hyper-V host to act as a Replica server, allowing it to receive replicated virtual machines for Disaster Recovery (DR).
  - Manages host-level settings such as Authentication Type, authorized primary servers, ports, and default storage locations.
options:
  replication_enabled:
    description:
      - Specifies whether the host is enabled as a Replica server.
    type: bool
  allowed_authentication_type:
    description:
      - The authentication protocol used to secure replication traffic.
      - C(Kerberos) transmits data over HTTP (unencrypted) but requires Active Directory.
      - C(Certificate) transmits data over HTTPS (encrypted) and requires certificate infrastructure.
      - C(CertificateAndKerberos) enables both listeners.
    type: str
    choices: [ Kerberos, Certificate, CertificateAndKerberos ]
  certificate_thumbprint:
    description:
      - The thumbprint of the certificate to use for HTTPS replication.
      - Required if C(allowed_authentication_type) includes C(Certificate).
    type: str
  kerberos_port:
    description:
      - The port used for Kerberos (HTTP) replication traffic.
    type: int
    default: 80
  certificate_port:
    description:
      - The port used for Certificate (HTTPS) replication traffic.
    type: int
    default: 443
  default_storage_location:
    description:
      - The default directory on the replica server where incoming replicated VM files will be stored.
    type: str
  allow_any_server:
    description:
      - If C(true), the replica server accepts replication traffic from any primary server.
      - If C(false), you must explicitly manage authorization entries using the C(authorized_servers) list.
    type: bool
  authorized_servers:
    description:
      - A list of authorized primary servers/trust groups and their specific storage locations.
      - Only applicable if C(allow_any_server) is C(false).
      - This list is managed on a per-entry basis. It will add new entries or update existing ones based on the C(server) key.
        It will not delete existing entries on the host unless you explicitly pass them with C(state=absent).
    type: list
    elements: dict
    suboptions:
      server:
        description: The FQDN of the primary server or a wildcard (e.g., C(*.contoso.com)).
        type: str
        required: true
      trust_group:
        description: A logical tag used to group incoming replications.
        type: str
      storage_location:
        description: A specific storage path for this authorized server. Overrides the C(default_storage_location).
        type: str
        required: true
      state:
        description: Whether this authorization entry should be present or absent.
        type: str
        choices: [ present, absent ]
        default: present
author:
  - Ansible Cloud Team (@ansible)
'''

EXAMPLES = r'''
- name: Enable Kerberos replication from any server
  microsoft.hyperv.hv_replication_server:
    replication_enabled: true
    allowed_authentication_type: Kerberos
    kerberos_port: 80
    allow_any_server: true
    default_storage_location: "D:\\Hyper-V\\Replica"

- name: Enable Certificate replication with strict authorization
  microsoft.hyperv.hv_replication_server:
    replication_enabled: true
    allowed_authentication_type: Certificate
    certificate_thumbprint: "ABCDEF1234567890"
    allow_any_server: false
    authorized_servers:
      - server: "primary-01.contoso.com"
        trust_group: "Tier1-Apps"
        storage_location: "E:\\ReplicaStorage\\Primary01"
        state: present
'''

RETURN = r'''
replication_enabled:
    description: Whether replication is currently enabled on the host.
    returned: always
    type: bool
    sample: true
allowed_authentication_type:
    description: The configured authentication type.
    returned: always
    type: str
    sample: "Kerberos"
allow_any_server:
    description: Whether any server is allowed to replicate.
    returned: always
    type: bool
    sample: false
authorized_servers:
    description: The list of configured authorization entries.
    returned: always
    type: list
    sample: [{"server": "primary-01.contoso.com", "trust_group": "Tier1-Apps", "storage_location": "E:\\ReplicaStorage\\Primary01"}]
'''
