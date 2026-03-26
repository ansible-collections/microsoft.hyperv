# Microsoft Hyper-V Collection for Ansible

[![CI](https://github.com/ansible-collections/microsoft.hyperv/workflows/CI/badge.svg?event=push)](https://github.com/ansible-collections/microsoft.hyperv/actions) [![Codecov](https://img.shields.io/codecov/c/github/ansible-collections/microsoft.hyperv)](https://codecov.io/gh/ansible-collections/microsoft.hyperv)

This collection provides comprehensive automation capabilities for Microsoft Hyper-V environments. It enables users to manage virtual machines, virtual networking, storage, replication, clustering, and advanced Hyper-V features through Ansible playbooks.

## Our mission

At the **Microsoft Hyper-V Collection**, our mission is to produce and maintain simple, flexible,
and powerful open-source software tailored to automating and managing Microsoft Hyper-V virtualization infrastructure.

We welcome members from all skill levels to participate actively in our open, inclusive, and vibrant community.
Whether you are an expert or just beginning your journey with Ansible and Hyper-V automation,
you are encouraged to contribute, share insights, and collaborate with fellow enthusiasts!

## Code of Conduct

We follow the [Ansible Code of Conduct](https://docs.ansible.com/projects/ansible/devel/community/code_of_conduct.html) in all our interactions within this project.

If you encounter abusive behavior, please refer to the [policy violations](https://docs.ansible.com/projects/ansible/devel/community/code_of_conduct.html#policy-violations) section of the Code for information on how to raise a complaint.

## Communication

* Join the Ansible forum:
  * [Get Help](https://forum.ansible.com/c/help/6): get help or help others. Please add the `hyperv` tag if you start new discussions.
  * [Posts tagged with 'hyperv'](https://forum.ansible.com/tag/hyperv): subscribe to participate in Hyper-V-related conversations.
  * [Social Spaces](https://forum.ansible.com/c/chat/4): gather and interact with fellow enthusiasts.
  * [News & Announcements](https://forum.ansible.com/c/news/5): track project-wide announcements including social events. The [Bullhorn newsletter](https://docs.ansible.com/projects/ansible/devel/community/communication.html#the-bullhorn), which is used to announce releases and important changes, can also be found here.

For more information about communication, see the [Ansible communication guide](https://docs.ansible.com/projects/ansible/devel/community/communication.html).

## Contributing to this collection

The content of this collection is made by people like you, a community of individuals collaborating on making the world better through developing automation software.

We are actively accepting new contributors and all types of contributions are very welcome.

Don't know how to start? Refer to the [Ansible community guide](https://docs.ansible.com/projects/ansible/devel/community/index.html)!

Want to submit code changes? Take a look at the [Quick-start development guide](https://docs.ansible.com/projects/ansible/devel/community/create_pr_quick_start.html).

We also use the following guidelines:

* [Collection review checklist](https://docs.ansible.com/projects/ansible/devel/community/collection_contributors/collection_reviewing.html)
* [Ansible development guide](https://docs.ansible.com/projects/ansible/devel/dev_guide/index.html)
* [Ansible collection development guide](https://docs.ansible.com/projects/ansible/devel/dev_guide/developing_collections.html#contributing-to-collections)

## Collection maintenance

The current maintainers are listed in the [MAINTAINERS](https://github.com/ansible-collections/microsoft.hyperv/blob/main/MAINTAINERS) file. If you have questions or need help, feel free to mention them in the proposals.

To learn how to maintain/become a maintainer of this collection, refer to the [Maintainer guidelines](https://docs.ansible.com/projects/ansible/devel/community/maintainers.html).

It is necessary for maintainers of this collection to be subscribed to:

* The collection itself (the `Watch` button -> `All Activity` in the upper right corner of the repository's homepage).
* The [news-for-maintainers repository](https://github.com/ansible-collections/news-for-maintainers).

They also should be subscribed to Ansible's [The Bullhorn newsletter](https://docs.ansible.com/projects/ansible/devel/community/communication.html#the-bullhorn).

## Governance

The process of decision making in this collection is based on discussing and finding consensus among participants.

Every voice is important. If you have something on your mind, create an issue or dedicated discussion and let's discuss it!

## Tested with Ansible

This collection is tested with the most current Ansible releases.

## External requirements

### Platform Requirements
- **Operating System**: Windows Server 2016 or later with Hyper-V role installed
- **PowerShell**: PowerShell 5.1 or later
- **Hyper-V**: Hyper-V must be enabled on the target Windows host

### Supported connections
This collection uses the `winrm` or `psrp` connection plugins to communicate with Windows hosts running Hyper-V.

## Available Modules

The following modules are currently available and fully supported in the collection:

### Virtual Machine Management
- `hv_vm` - VM provisioning and deprovisioning
- `hv_vm_state` - VM power management (start, stop, pause, save, restart)
- `hv_checkpoint` - Snapshot management

### VM Hardware Configuration
- `hv_processor` - vCPU management
- `hv_memory` - Dynamic RAM configuration
- `hv_scsi_controller` - SCSI controller management
- `hv_hard_disk` - Hard disk management
- `hv_dvd_drive` - DVD drive management
- `hv_network_adapter` - Network adapter configuration (VLAN, MAC, QoS)
- `hv_vm_boot` - Boot configuration (BIOS/Firmware)

### Storage Management
- `hv_vhd` - VHD/VHDX file operations
- `hv_storage_pool` - Storage pool management

### Advanced Features
- `hv_host` - Hyper-V host configuration

### Information Gathering
- `hv_vm_info` - Gather VM information
- `hv_host_info` - Gather Hyper-V host information

## Planned Modules

The following modules are planned and will be released in future updates:

### Virtual Machine Management
- `hv_vm_transfer` - Export and import VMs
- `hv_vm_move` - Live migration
- `hv_vm_tag` - VM tagging
- `hv_vm_group` - VM grouping

### VM Hardware Configuration
- `hv_com_port` - COM port configuration
- `hv_integration_service` - Integration services management

### Virtual Networking
- `hv_vswitch` - Virtual switch management
- `hv_network_acl` - VM access control lists
- `hv_isolation` - Network isolation settings (SDN)

### Storage Management
- `hv_san_adapter` - Fibre Channel SAN adapter management

### Replication and Migration
- `hv_replication` - VM replication settings
- `hv_replication_server` - Host replication settings
- `hv_migration_network` - Migration network settings

### Advanced Features
- `hv_hardware_passthrough` - GPU-P and Discrete Device Assignment
- `hv_shielded_vm` - Shielded VM configuration
- `hv_nested_virt` - Nested virtualization

### Guest Operations
- `hv_guest` - File copy and command execution via PowerShell Direct

### Clustering
- `hv_cluster_node_maintenance` - Cluster maintenance mode
- `hv_cluster_group_set` - Cluster group management
- `hv_resource_pool` - Resource pool management

## Support
As Red Hat Ansible Certified Content, this collection is entitled to support through the Ansible Automation Platform (AAP).

*   **Certified Support:** If you have an active Red Hat subscription, you can open a support case via the [Red Hat Customer Portal](https://access.redhat.com/support/cases/#/case/combine) or by using the **Create issue** button on the top right corner of the collection page in Automation Hub.
*   **Community Support:** If this collection was obtained via Ansible Galaxy or GitHub and a Red Hat support case cannot be opened, community assistance is available on the [Ansible Forum](https://forum.ansible.com/).
*   **Supported Versions:** Support is provided for the current major version and the previous major version of this collection.

## Using this collection

### Installing the Collection from Ansible Galaxy

Before using this collection, you need to install it with the Ansible Galaxy command-line tool:
```bash
ansible-galaxy collection install microsoft.hyperv
```

You can also include it in a `requirements.yml` file and install it with `ansible-galaxy collection install -r requirements.yml`, using the format:
```yaml
---
collections:
  - name: microsoft.hyperv
```

Note that if you install the collection from Ansible Galaxy, it will not be upgraded automatically when you upgrade the `ansible` package. To upgrade the collection to the latest available version, run the following command:
```bash
ansible-galaxy collection install microsoft.hyperv --upgrade
```

You can also install a specific version of the collection, for example, if you need to downgrade when something is broken in the latest version (please report an issue in this repository). Use the following syntax to install version `1.0.0`:

```bash
ansible-galaxy collection install microsoft.hyperv:==1.0.0
```

See [using Ansible collections](https://docs.ansible.com/projects/ansible/devel/user_guide/collections_using.html) for more details.

### Example Playbook

Here's a simple example of using this collection to create and start a Hyper-V VM:

```yaml
---
- name: Manage Hyper-V Virtual Machines
  hosts: hyperv_hosts
  gather_facts: false

  tasks:
    - name: Create a new VM
      microsoft.hyperv.hv_vm:
        name: TestVM01
        generation: 2
        memory_startup_bytes: 2GB
        state: present

    - name: Configure VM processor
      microsoft.hyperv.hv_processor:
        vm_name: TestVM01
        count: 2

    - name: Add network adapter
      microsoft.hyperv.hv_network_adapter:
        vm_name: TestVM01
        switch_name: External

    - name: Start the VM
      microsoft.hyperv.hv_vm_state:
        name: TestVM01
        state: running
```

## Release notes

See the [changelog](https://github.com/ansible-collections/microsoft.hyperv/blob/main/CHANGELOG.md).

## More information

### Collection Documentation
- [Changelog](https://github.com/ansible-collections/microsoft.hyperv/blob/main/CHANGELOG.md) - Release notes and version history

### Microsoft Hyper-V Resources
- [Microsoft Hyper-V Documentation](https://docs.microsoft.com/en-us/windows-server/virtualization/hyper-v/hyper-v-on-windows-server)
- [Hyper-V PowerShell Reference](https://docs.microsoft.com/en-us/powershell/module/hyper-v/)

### Ansible Resources
- [Ansible user guide](https://docs.ansible.com/projects/ansible/devel/user_guide/index.html)
- [Ansible developer guide](https://docs.ansible.com/projects/ansible/devel/dev_guide/index.html)
- [Ansible collections requirements](https://docs.ansible.com/projects/ansible/devel/community/collection_contributors/collection_requirements.html)
- [Ansible community Code of Conduct](https://docs.ansible.com/projects/ansible/devel/community/code_of_conduct.html)
- [The Bullhorn (the Ansible contributor newsletter)](https://docs.ansible.com/projects/ansible/devel/community/communication.html#the-bullhorn)
- [Important announcements for maintainers](https://github.com/ansible-collections/news-for-maintainers)

## Licensing

GNU General Public License v3.0 or later.

See [LICENSE](https://www.gnu.org/licenses/gpl-3.0.txt) to see the full text.
