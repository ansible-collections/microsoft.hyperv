# -*- coding: utf-8 -*-
# Copyright (c) 2026, Ansible Cloud Team
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

from ansible.module_utils._text import to_text

try:
    import pypsrp.client
    HAS_PYPSRP = True
except ImportError:
    HAS_PYPSRP = False


class HyperVConnection:
    """
    Manages the remote WinRM/PSRP connection to the Hyper-V host.
    This enables modules to run on the control node and connect over HTTP/HTTPS.
    """
    def __init__(self, module):
        self.module = module

        self.host = module.params.get('ansible_host')
        self.user = module.params.get('ansible_user')
        self.password = module.params.get('ansible_password')
        self.port = module.params.get('ansible_port', 5985)

        # We will use pypsrp as the primary engine for executing PowerShell
        if not HAS_PYPSRP:
            self.module.fail_json(msg="The 'pypsrp' Python library is required for this collection.")

        try:
            ssl = self.port == 5986
            auth = "basic"
            encryption = "never" if auth == "basic" and not ssl else "auto"

            self.client = pypsrp.client.Client(
                self.host,
                username=self.user,
                password=self.password,
                port=self.port,
                ssl=ssl,
                auth=auth,
                encryption=encryption,
                cert_validation=False
            )
        except Exception as e:
            self.module.fail_json(msg="Failed to initialize connection to Hyper-V host: {0}".format(to_text(e)))

    def execute_script(self, script):
        """
        Executes a PowerShell script on the remote Hyper-V host.
        Returns a tuple of (stdout, stderr, return_code).
        """
        try:
            output, streams, had_errors = self.client.execute_ps(script)
            stdout = str(output) if output else ""
            
            error_list = [str(err) for err in getattr(streams, 'error', [])]
            stderr = "\n".join(error_list)
            
            rc = 1 if had_errors or error_list else 0
            return stdout, stderr, rc
        except Exception as e:
            self.module.fail_json(msg="Error executing PowerShell script: {0}".format(str(e)))

    def close(self):
        """
        Closes the PSRP connection.
        """
        if hasattr(self, 'client') and self.client:
            # Client usually closes context on __exit__ but we can force it if needed
            pass
