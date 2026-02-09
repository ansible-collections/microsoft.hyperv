# Microsoft Hyper-V Collection - Module Reference

This document provides a comprehensive reference for all modules planned and available in the microsoft.hyperv collection.

## Module Categories

### Virtual Machine Management

| Module | Jira Task | Purpose | Status |
|--------|-----------|---------|--------|
| hv_vm | ACA-4782 | Create and delete virtual machines | Planned |
| hv_vm_state | ACA-4783 | Manage VM power state (start, stop, save, pause) | Planned |
| hv_vm_restart | ACA-4784 | Restart virtual machines | Planned |
| hv_checkpoint | ACA-4785 | Manage VM snapshots/checkpoints | Planned |
| hv_vm_export | ACA-4786 | Export virtual machines | Planned |
| hv_vm_import | ACA-4787 | Import virtual machines | Planned |
| hv_vm_move | ACA-4788 | Live migrate virtual machines | Planned |
| hv_vm_tag | ACA-4825 | Manage VM tags | Planned |
| hv_vm_group | ACA-4816 | Manage VM groups | Planned |

### VM Hardware Configuration

| Module | Jira Task | Purpose | Status |
|--------|-----------|---------|--------|
| hv_processor | ACA-4789 | Configure virtual CPU settings | Planned |
| hv_memory | ACA-4790 | Configure dynamic memory settings | Planned |
| hv_scsi_controller | ACA-4791 | Manage SCSI controllers | Planned |
| hv_hard_disk | ACA-4792 | Manage virtual hard disks | Planned |
| hv_dvd_drive | ACA-4793 | Manage virtual DVD drives | Planned |
| hv_network_adapter | ACA-4794 | Manage virtual network adapters | Planned |
| hv_com_port | ACA-4795 | Configure COM ports | Planned |
| hv_firmware | ACA-4796 | Configure VM firmware settings | Planned |
| hv_vm_bios | ACA-4820 | Configure VM BIOS settings | Planned |
| hv_integration_service | ACA-4797 | Manage integration services | Planned |

### Virtual Networking

| Module | Jira Task | Purpose | Status |
|--------|-----------|---------|--------|
| hv_vswitch | ACA-4798 | Manage virtual switches | Planned |
| hv_vlan | ACA-4799 | Configure VLAN settings | Planned |
| hv_mac_address | ACA-4800 | Manage MAC addresses | Planned |
| hv_vm_acl | ACA-4801 | Configure VM port ACLs | Planned |
| hv_extended_acl | ACA-4802 | Configure extended ACLs | Planned |
| hv_bandwidth | ACA-4803 | Manage bandwidth settings | Planned |
| hv_isolation | ACA-4804 | Configure network isolation | Planned |
| hv_switch_extension | ACA-4805 | Manage virtual switch extensions | Planned |

### Storage Management

| Module | Jira Task | Purpose | Status |
|--------|-----------|---------|--------|
| hv_vhd_file | ACA-4806 | Manage VHD/VHDX files | Planned |
| hv_vhd_mount | ACA-4807 | Mount and dismount VHD files | Planned |
| hv_storage_pool | ACA-4808 | Manage storage pools | Planned |
| hv_san_adapter | ACA-4809 | Manage Fibre Channel SAN adapters | Planned |

### Replication and Migration

| Module | Jira Task | Purpose | Status |
|--------|-----------|---------|--------|
| hv_replication | ACA-4810 | Configure Hyper-V Replica | Planned |
| hv_replication_connection | ACA-4811 | Manage replication connections | Planned |
| hv_migration_network | ACA-4812 | Configure migration networks | Planned |

### Advanced Features

| Module | Jira Task | Purpose | Status |
|--------|-----------|---------|--------|
| hv_gpu_partition | ACA-4813 | Configure GPU partitioning | Planned |
| hv_dda_device | ACA-4814 | Manage Discrete Device Assignment | Planned |
| hv_shielded_vm | ACA-4815 | Configure shielded VMs | Planned |
| hv_nested_virt | ACA-4817 | Enable/disable nested virtualization | Planned |
| hv_vm_console | ACA-4819 | Manage VM console settings | Planned |
| hv_host_config | ACA-4818 | Configure Hyper-V host settings | Planned |

### Guest Operations

| Module | Jira Task | Purpose | Status |
|--------|-----------|---------|--------|
| hv_guest_command | ACA-4821 | Execute commands in guest VMs | Planned |
| hv_guest_file_copy | ACA-4822 | Copy files to/from guest VMs | Planned |

### Information Gathering

| Module | Jira Task | Purpose | Status |
|--------|-----------|---------|--------|
| hv_vm_info | ACA-4823 | Gather VM information | Planned |
| hv_host_info | ACA-4824 | Gather Hyper-V host information | Planned |

### Clustering

| Module | Jira Task | Purpose | Status |
|--------|-----------|---------|--------|
| hv_cluster_node_maintenance | ACA-4826 | Manage cluster node maintenance mode | Planned |
| hv_cluster_group_set | ACA-4827 | Manage cluster group sets | Planned |
| hv_resource_pool | ACA-4828 | Manage resource pools | Planned |

## Module Naming Conventions

All modules in this collection follow these naming conventions:

- **Prefix**: All modules start with `hv_` (Hyper-V)
- **Naming**: Module names use snake_case
- **Purpose**: Names reflect the Hyper-V object or operation they manage

## Common Module Parameters

Most modules in this collection support these common parameters:

### Connection Parameters
- `ansible_host` - The Hyper-V host to connect to
- `ansible_user` - Username for authentication
- `ansible_password` - Password for authentication
- `ansible_connection` - Connection type (winrm or psrp)

### Common Module Parameters
- `state` - Desired state (present, absent, running, stopped, etc.)
- `name` or `vm_name` - Name of the object being managed
- `check_mode` - Support for Ansible check mode (dry run)

## Module Development Status

- **Planned**: Module is in the roadmap but development has not started
- **In Development**: Module is currently being developed
- **In Review**: Module is complete and under code review
- **Available**: Module is available in the collection

## Contributing to Module Development

Interested in contributing to module development? See:
- [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines
- [ROADMAP.md](ROADMAP.md) for development phases and priorities
- Individual Jira tasks in Epic [ACA-4728](https://issues.redhat.com/browse/ACA-4728)

## Module Documentation

Each module includes:
- Parameter documentation with types and defaults
- Return value documentation
- Multiple usage examples
- Notes about dependencies and requirements
- Version information

Access module documentation:
```bash
ansible-doc microsoft.hyperv.hv_vm
```

Or view online at: https://github.com/ansible-collections/microsoft.hyperv/tree/main/docs
