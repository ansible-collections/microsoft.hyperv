# Microsoft Hyper-V Collection - Module Reference

This document provides a comprehensive reference for all modules in the microsoft.hyperv collection.

## Collection Overview

**Total Modules**: 35 (consolidated from 47 original tasks)
**Consolidation Strategy**: Hybrid approach combining related functionality while maintaining clear module boundaries
**Code Reuse**: 45-55% through 8 shared module_utils libraries

See [FINAL_MODULE_LIST.md](FINAL_MODULE_LIST.md) for detailed consolidation analysis.

---

## Module Categories

### Virtual Machine Management

| Module | Jira Tasks | Purpose | Type | Status |
|--------|-----------|---------|------|--------|
| **hv_vm** | ACA-4782 | Create and delete virtual machines | Standard | Planned |
| **hv_vm_state** | ACA-4783, ACA-4784 | Manage VM power state (start, stop, pause, save, restart) | ✨ Consolidated | Planned |
| **hv_checkpoint** | ACA-4785 | Manage VM snapshots/checkpoints | Standard | Planned |
| **hv_vm_transfer** | ACA-4786, ACA-4787 | Export and import virtual machines | ✨ Consolidated | Planned |
| **hv_vm_move** | ACA-4788 | Live migrate virtual machines | Standard | Planned |
| **hv_vm_tag** | ACA-4825 | Manage VM metadata tags | Standard | Planned |
| **hv_vm_group** | ACA-4816 | Manage VM groups for placement rules | Standard | Planned |

**Consolidation Notes**:
- `hv_vm_state` combines power management and restart operations
- `hv_vm_transfer` combines export and import (live migration kept separate due to complexity)

---

### VM Hardware Configuration

| Module | Jira Tasks | Purpose | Type | Status |
|--------|-----------|---------|------|--------|
| **hv_processor** | ACA-4789 | Configure virtual CPU settings and nested virtualization | Standard | Planned |
| **hv_memory** | ACA-4790 | Configure dynamic memory settings | Standard | Planned |
| **hv_scsi_controller** | ACA-4791 | Manage SCSI controllers | Standard | Planned |
| **hv_hard_disk** | ACA-4792 | Attach/detach virtual hard disks | Standard | Planned |
| **hv_dvd_drive** | ACA-4793 | Manage virtual DVD drives and ISO mounting | Standard | Planned |
| **hv_network_adapter** | ACA-4794, 4799, 4800, 4803 | Manage virtual network adapters with VLAN, MAC, and QoS | ✨ Consolidated | Planned |
| **hv_com_port** | ACA-4795 | Configure COM/serial ports | Standard | Planned |
| **hv_vm_boot** | ACA-4796, ACA-4820 | Configure boot settings for Gen1 (BIOS) and Gen2 (firmware) | ✨ Consolidated | Planned |
| **hv_integration_service** | ACA-4797 | Manage integration services (time sync, heartbeat, etc.) | Standard | Planned |

**Consolidation Notes**:
- `hv_network_adapter` includes VLAN ID, MAC address, and bandwidth (QoS) configuration
- `hv_vm_boot` handles both Gen1 BIOS and Gen2 firmware settings

**Deprecated Aliases**:
- `hv_vlan` → Use `hv_network_adapter` with `vlan_id` parameter
- `hv_mac_address` → Use `hv_network_adapter` with `mac_address` parameter
- `hv_bandwidth` → Use `hv_network_adapter` with `bandwidth_*` parameters
- `hv_firmware` → Use `hv_vm_boot` for Gen2 VMs
- `hv_vm_bios` → Use `hv_vm_boot` for Gen1 VMs
- `hv_vm_restart` → Use `hv_vm_state` with `state: restarted`

---

### Virtual Networking

| Module | Jira Tasks | Purpose | Type | Status |
|--------|-----------|---------|------|--------|
| **hv_vswitch** | ACA-4798, ACA-4805 | Manage virtual switches and extensions | ✨ Consolidated | Planned |
| **hv_network_acl** | ACA-4801, ACA-4802 | Configure port ACLs (standard and extended) | ✨ Consolidated | Planned |
| **hv_isolation** | ACA-4804 | Configure network isolation (VXLAN/NVGRE) for SDN | Standard | Planned |

**Consolidation Notes**:
- `hv_vswitch` includes switch extension management
- `hv_network_acl` handles both standard and extended ACL rules

**Deprecated Aliases**:
- `hv_switch_extension` → Use `hv_vswitch` with `extensions` parameter
- `hv_extended_acl` → Use `hv_network_acl` with `acl_type: extended`

---

### Storage Management

| Module | Jira Tasks | Purpose | Type | Status |
|--------|-----------|---------|------|--------|
| **hv_vhd** | ACA-4806, ACA-4807 | Manage VHD/VHDX files and mount operations | ✨ Consolidated | Planned |
| **hv_storage_pool** | ACA-4808 | Manage storage pools and quotas | Standard | Planned |
| **hv_san_adapter** | ACA-4809 | Manage Fibre Channel SAN adapters (vHBA) | Standard | Planned |

**Consolidation Notes**:
- `hv_vhd` combines file creation/deletion with mount/unmount operations (similar to Linux `mount` module)

**Deprecated Aliases**:
- `hv_vhd_file` → Use `hv_vhd` with file operations
- `hv_vhd_mount` → Use `hv_vhd` with `state: mounted`

---

### Replication and Migration

| Module | Jira Tasks | Purpose | Type | Status |
|--------|-----------|---------|------|--------|
| **hv_replication** | ACA-4810 | Configure Hyper-V Replica (VM-level) | Standard | Planned |
| **hv_replication_server** | ACA-4811 | Configure replication server settings (Host-level) | Standard | Planned |
| **hv_migration_network** | ACA-4812 | Configure live migration networks | Standard | Planned |

**Note**: Replication modules kept separate as they operate at different scopes (VM vs Host).

---

### Advanced Features

| Module | Jira Tasks | Purpose | Type | Status |
|--------|-----------|---------|------|--------|
| **hv_hardware_passthrough** | ACA-4813, ACA-4814 | Configure GPU partitioning and DDA (Discrete Device Assignment) | ✨ Consolidated | Planned |
| **hv_shielded_vm** | ACA-4815 | Configure shielded VMs with Key Protector | Standard | Planned |
| **hv_nested_virt** | ACA-4817 | Enable/disable nested virtualization | Standard | Planned |
| **hv_host** | ACA-4818, ACA-4819 | Configure Hyper-V host settings and console mode | ✨ Consolidated | Planned |

**Consolidation Notes**:
- `hv_hardware_passthrough` handles both GPU partitioning and DDA for direct hardware access
- `hv_host` combines host configuration with console settings

**Deprecated Aliases**:
- `hv_gpu_partition` → Use `hv_hardware_passthrough` with `device_type: gpu_partition`
- `hv_dda_device` → Use `hv_hardware_passthrough` with `device_type: dda`
- `hv_host_config` → Use `hv_host`
- `hv_vm_console` → Use `hv_host` with console parameters

---

### Guest Operations

| Module | Jira Tasks | Purpose | Type | Status |
|--------|-----------|---------|------|--------|
| **hv_guest** | ACA-4821, ACA-4822 | Execute commands and copy files via PowerShell Direct | ✨ Consolidated | Planned |

**Consolidation Notes**:
- `hv_guest` combines command execution and file transfer using PowerShell Direct (VMBus)
- Similar to VMware's `vmware_vm_shell` pattern

**Deprecated Aliases**:
- `hv_guest_command` → Use `hv_guest` with `operation: command`
- `hv_guest_file_copy` → Use `hv_guest` with `operation: file_copy`

---

### Information Gathering

| Module | Jira Tasks | Purpose | Type | Status |
|--------|-----------|---------|------|--------|
| **hv_vm_info** | ACA-4823 | Gather comprehensive VM information and facts | Standard | Planned |
| **hv_host_info** | ACA-4824 | Gather Hyper-V host information and capacity | Standard | Planned |

**Note**: Info modules kept separate as they gather different resource types with different fact structures.

---

### Clustering

| Module | Jira Tasks | Purpose | Type | Status |
|--------|-----------|---------|------|--------|
| **hv_cluster_node_maintenance** | ACA-4826 | Drain cluster node for maintenance | Standard | Planned |
| **hv_cluster_group_set** | ACA-4827 | Manage cluster group sets and anti-affinity rules | Standard | Planned |
| **hv_resource_pool** | ACA-4828 | Manage resource pools for metering and quotas | Standard | Planned |

---

## Module Consolidation Summary

| Consolidated Module | Original Modules | Tickets Combined | Benefit |
|---------------------|------------------|------------------|---------|
| **hv_vm_state** | hv_vm_state, hv_vm_restart | 2 | Single module for all power operations |
| **hv_network_adapter** | hv_network_adapter, hv_vlan, hv_mac_address, hv_bandwidth | 4 | Atomic network configuration |
| **hv_vm_boot** | hv_firmware, hv_vm_bios | 2 | Unified boot configuration |
| **hv_host** | hv_host_config, hv_vm_console | 2 | Complete host management |
| **hv_vswitch** | hv_vswitch, hv_switch_extension | 2 | Switch with extensions |
| **hv_network_acl** | hv_vm_acl, hv_extended_acl | 2 | Unified ACL management |
| **hv_vhd** | hv_vhd_file, hv_vhd_mount | 2 | Complete VHD lifecycle |
| **hv_vm_transfer** | hv_vm_export, hv_vm_import | 2 | Backup/restore operations |
| **hv_guest** | hv_guest_command, hv_guest_file_copy | 2 | PowerShell Direct operations |
| **hv_hardware_passthrough** | hv_gpu_partition, hv_dda_device | 2 | Direct hardware access |

**Total**: 10 consolidated modules combining 22 original modules → **35 final modules**

---

## Module Naming Conventions

All modules in this collection follow these naming conventions:

- **Prefix**: All modules start with `hv_` (Hyper-V)
- **Naming**: Module names use snake_case
- **Purpose**: Names reflect the Hyper-V resource or operation they manage
- **Info Modules**: End with `_info` suffix (hv_vm_info, hv_host_info)

---

## Common Module Parameters

Most modules in this collection support these common parameters:

### Connection Parameters
- `ansible_host` - The Hyper-V host to connect to
- `ansible_user` - Username for authentication
- `ansible_password` - Password for authentication
- `ansible_connection` - Connection type (winrm or psrp recommended)
- `ansible_winrm_transport` - WinRM transport method (optional)

### Common Module Parameters
- `state` - Desired state (present, absent, running, stopped, mounted, etc.)
- `name` or `vm_name` - Name of the resource being managed
- `check_mode` - Support for Ansible check mode (dry run)
- `force` - Force operations when applicable

### Idempotency
All modules are designed to be idempotent - running the same task multiple times will not cause changes if the desired state is already achieved.

---

## Module Examples

### Example 1: Complete VM Provisioning with Consolidated Modules

```yaml
---
- name: Provision Hyper-V VM with all components
  hosts: hyperv_host
  gather_facts: false

  tasks:
    - name: Create VM
      microsoft.hyperv.hv_vm:
        name: WebServer01
        generation: 2
        state: present

    - name: Configure processor and memory
      microsoft.hyperv.hv_processor:
        vm_name: WebServer01
        count: 4

    - name: Configure memory
      microsoft.hyperv.hv_memory:
        vm_name: WebServer01
        startup_bytes: 4GB
        dynamic_memory: true
        minimum_bytes: 2GB
        maximum_bytes: 8GB

    - name: Create and attach VHD (consolidated module)
      microsoft.hyperv.hv_vhd:
        path: D:\VMs\WebServer01\OS.vhdx
        size: 80GB
        type: dynamic
        state: present

    - name: Attach VHD to VM
      microsoft.hyperv.hv_hard_disk:
        vm_name: WebServer01
        controller_type: SCSI
        controller_number: 0
        controller_location: 0
        path: D:\VMs\WebServer01\OS.vhdx

    - name: Configure network with VLAN (consolidated module)
      microsoft.hyperv.hv_network_adapter:
        vm_name: WebServer01
        adapter_name: Production
        switch_name: External
        vlan_id: 100
        mac_address: "00:15:5D:00:01:0A"
        bandwidth_maximum: 1000000000  # 1 Gbps
        state: present

    - name: Configure boot order (consolidated module)
      microsoft.hyperv.hv_vm_boot:
        vm_name: WebServer01
        secure_boot: true
        secure_boot_template: MicrosoftWindows
        boot_order:
          - NetworkAdapter
          - HardDiskDrive

    - name: Start VM (consolidated module)
      microsoft.hyperv.hv_vm_state:
        name: WebServer01
        state: running
```

### Example 2: Using Deprecated Aliases (Backward Compatibility)

```yaml
# Old way (will show deprecation warning)
- name: Configure VLAN
  microsoft.hyperv.hv_vlan:
    vm_name: WebServer01
    adapter_name: Production
    vlan_id: 100

# New consolidated way (recommended)
- name: Configure network adapter with VLAN
  microsoft.hyperv.hv_network_adapter:
    vm_name: WebServer01
    adapter_name: Production
    switch_name: External
    vlan_id: 100
```

### Example 3: Guest Operations (Consolidated Module)

```yaml
- name: Execute command in guest
  microsoft.hyperv.hv_guest:
    vm_name: WebServer01
    operation: command
    username: Administrator
    password: "{{ vault_password }}"
    command: "Get-Service -Name W3SVC"
  register: service_status

- name: Copy file to guest
  microsoft.hyperv.hv_guest:
    vm_name: WebServer01
    operation: file_copy
    username: Administrator
    password: "{{ vault_password }}"
    source: /ansible/configs/web.config
    destination: C:\inetpub\wwwroot\web.config
```

---

## Module Development Status

| Status | Description | Count |
|--------|-------------|-------|
| **Planned** | Module is in the roadmap, development not started | 35 |
| **In Development** | Module is currently being developed | 0 |
| **In Review** | Module is complete and under code review | 0 |
| **Available** | Module is available in the collection | 0 |

**Current Phase**: Planning
**Next Milestone**: Phase 1 foundation (module_utils + 6 core modules)

---

## Module Utils

All modules leverage shared utilities for code reuse:

| Module Util | Purpose | Used By |
|-------------|---------|---------|
| **hyperv_connection.py** | PowerShell remoting session management | All modules |
| **hyperv_core.py** | VM operations, state management, error handling | VM-related modules |
| **hyperv_validation.py** | Parameter validation, Gen1/Gen2 compatibility | Hardware modules |
| **hyperv_powershell.py** | Script generation, parameter escaping | All modules |
| **hyperv_network.py** | Network adapter and switch operations | Network modules |
| **hyperv_storage.py** | VHD and disk operations | Storage modules |
| **hyperv_cluster.py** | Failover clustering operations | Cluster modules |
| **hyperv_guest_integration.py** | PowerShell Direct (VMBus) integration | Guest operations |

**Estimated Code Reuse**: 45-55% across all modules

---

## Contributing to Module Development

Interested in contributing to module development?

### Resources
- [CONTRIBUTING.md](../../CONTRIBUTING.md) - Contribution guidelines and workflows
- [ROADMAP.md](ROADMAP.md) - Development phases and priorities
- [EPIC_COMPARISON.md](EPIC_COMPARISON.md) - Consolidation strategy analysis
- Individual Jira tasks in Epic [ACA-4728](https://issues.redhat.com/browse/ACA-4728)

### Getting Started
1. Review the [ROADMAP.md](ROADMAP.md) to understand development phases
2. Check [EPIC_COMPARISON.md](EPIC_COMPARISON.md) for consolidation rationale
3. Find a module in "Planned" status
4. Comment on the corresponding Jira task to claim it
5. Follow module development guidelines in [CONTRIBUTING.md](CONTRIBUTING.md)

---

## Module Documentation

Each module will include:

### Code Documentation
- **DOCUMENTATION** block with all parameters, types, defaults, and descriptions
- **EXAMPLES** section with minimum 3 real-world examples
- **RETURN** block documenting all return values and their types
- **NOTES** section for prerequisites, caveats, and version requirements

### Access Documentation

```bash
# View module documentation
ansible-doc microsoft.hyperv.hv_vm

# List all modules in the collection
ansible-doc -l microsoft.hyperv

# View module examples only
ansible-doc microsoft.hyperv.hv_vm | grep -A 50 EXAMPLES
```

### Online Documentation
- Module docs: https://github.com/ansible-collections/microsoft.hyperv/tree/main/docs
- Collection repository: https://github.com/ansible-collections/microsoft.hyperv

---

## Migration from Individual Modules

If you were using individual modules that are now consolidated, here's the migration guide:

| Old Module | New Module | Parameter Changes |
|------------|------------|-------------------|
| `hv_vm_restart` | `hv_vm_state` | Use `state: restarted` |
| `hv_vlan` | `hv_network_adapter` | Add as `vlan_id` parameter |
| `hv_mac_address` | `hv_network_adapter` | Add as `mac_address` parameter |
| `hv_bandwidth` | `hv_network_adapter` | Use `bandwidth_minimum/maximum` |
| `hv_firmware` | `hv_vm_boot` | Same parameters for Gen2 VMs |
| `hv_vm_bios` | `hv_vm_boot` | Same parameters for Gen1 VMs |
| `hv_switch_extension` | `hv_vswitch` | Add as `extensions` list |
| `hv_extended_acl` | `hv_network_acl` | Use `acl_type: extended` |
| `hv_vhd_file` | `hv_vhd` | Same, `state: present/absent` |
| `hv_vhd_mount` | `hv_vhd` | Use `state: mounted/unmounted` |
| `hv_vm_export` | `hv_vm_transfer` | Use `operation: export` |
| `hv_vm_import` | `hv_vm_transfer` | Use `operation: import` |
| `hv_guest_command` | `hv_guest` | Use `operation: command` |
| `hv_guest_file_copy` | `hv_guest` | Use `operation: file_copy` |
| `hv_gpu_partition` | `hv_hardware_passthrough` | Use `device_type: gpu_partition` |
| `hv_dda_device` | `hv_hardware_passthrough` | Use `device_type: dda` |
| `hv_host_config` | `hv_host` | Same parameters |
| `hv_vm_console` | `hv_host` | Console params in `hv_host` |

---

**Last Updated**: 2026-02-09
**Version**: 2.0 (Hybrid Consolidation Strategy)
**Total Modules**: 35 (26% reduction from original 47 tasks)
