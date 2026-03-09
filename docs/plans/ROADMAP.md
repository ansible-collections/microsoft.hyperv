# Microsoft Hyper-V Collection Roadmap

This document outlines the development roadmap for the Ansible Microsoft Hyper-V Collection (Epic: ACA-4728).

## Overview

The Microsoft Hyper-V Collection aims to provide comprehensive automation capabilities for managing Hyper-V virtualization infrastructure through Ansible. Through strategic consolidation of related functionality, the collection will include **35 modules** covering all aspects of Hyper-V management.

## Development Status

**Epic**: [ACA-4728](https://issues.redhat.com/browse/ACA-4728)
**Original Tasks**: 47
**Optimized Module Count**: 35 (26% reduction through strategic consolidation)
**Current Status**: Planning/Initial Development

## Consolidation Strategy

After analyzing all 47 original tasks, we identified opportunities to combine related functionality while maintaining clear module boundaries. See [FINAL_MODULE_LIST.md](FINAL_MODULE_LIST.md) for detailed analysis.

**Key Consolidations**:
- Power management operations (start, stop, restart) → `hv_vm_state`
- Network adapter properties (VLAN, MAC, QoS) → `hv_network_adapter`
- Boot configuration (Gen1 BIOS, Gen2 firmware) → `hv_vm_boot`
- Virtual switch and extensions → `hv_vswitch`
- VHD file operations and mounting → `hv_vhd`
- And 7 more strategic consolidations

**Benefits**:
- Reduced module count without sacrificing functionality
- Atomic configuration changes (e.g., configure adapter with VLAN in one task)
- Consistent user experience with logical groupings
- Estimated 45-55% code reuse through shared module_utils

---

## Module Development Plan

### Phase 1: Foundation & Core VM Management (Priority: Critical)

**Timeline**: Weeks 1-4

#### Module Utils (Week 1-2)
- [ ] **hyperv_connection.py** - WinRM/PSRP session management
- [ ] **hyperv_core.py** - VM state checking, idempotency, error parsing
- [ ] **hyperv_validation.py** - Gen1/Gen2 validation, parameter checks
- [ ] **hyperv_powershell.py** - PowerShell script generation and execution

#### Core VM Lifecycle (Week 3-4)
- [ ] **hv_vm** (ACA-4782) - VM provisioning and deprovisioning
- [ ] **hv_vm_state** (ACA-4783, ACA-4784) - ✨ **CONSOLIDATED** - Power management including start, stop, pause, save, restart
- [ ] **hv_checkpoint** (ACA-4785) - Snapshot management
- [ ] **hv_vm_info** (ACA-4823) - Gather VM information
- [ ] **hv_host_info** (ACA-4824) - Gather Hyper-V host information
- [ ] **hv_host** (ACA-4818, ACA-4819) - ✨ **CONSOLIDATED** - Host configuration including console settings

---

### Phase 2: Hardware Configuration (Priority: High)

**Timeline**: Weeks 5-8

#### Compute Resources (Week 5)
- [ ] **hv_processor** (ACA-4789) - vCPU management
- [ ] **hv_memory** (ACA-4790) - Dynamic RAM configuration

#### Storage Hardware (Week 6)
- [ ] **hyperv_storage.py** - Module util for storage operations
- [ ] **hv_vhd** (ACA-4806, ACA-4807) - ✨ **CONSOLIDATED** - VHD/VHDX file operations including mount/unmount
- [ ] **hv_hard_disk** (ACA-4792) - Hard disk attachment
- [ ] **hv_scsi_controller** (ACA-4791) - SCSI controller management
- [ ] **hv_dvd_drive** (ACA-4793) - DVD drive and ISO management

#### Networking Hardware (Week 7-8)
- [ ] **hyperv_network.py** - Module util for network operations
- [ ] **hv_vswitch** (ACA-4798, ACA-4805) - ✨ **CONSOLIDATED** - Virtual switch management including extensions
- [ ] **hv_network_adapter** (ACA-4794, ACA-4799, ACA-4800, ACA-4803) - ✨ **CONSOLIDATED** - Network adapter with VLAN, MAC, and QoS settings
- [ ] **hv_network_acl** (ACA-4801, ACA-4802) - ✨ **CONSOLIDATED** - Standard and extended ACL management
- [ ] **hv_isolation** (ACA-4804) - Network isolation (VXLAN/NVGRE) for SDN

#### Boot & Integration (Week 8)
- [ ] **hv_vm_boot** (ACA-4796, ACA-4820) - ✨ **CONSOLIDATED** - Boot configuration for Gen1 (BIOS) and Gen2 (firmware)
- [ ] **hv_integration_service** (ACA-4797) - Integration services management
- [ ] **hv_com_port** (ACA-4795) - COM port configuration

---

### Phase 3: Advanced VM Operations (Priority: High)

**Timeline**: Weeks 9-12

#### Backup & Recovery (Week 9)
- [ ] **hv_vm_transfer** (ACA-4786, ACA-4787) - ✨ **CONSOLIDATED** - VM export and import operations
- [ ] **hv_vm_tag** (ACA-4825) - VM metadata tagging

#### Live Migration (Week 10)
- [ ] **hv_vm_move** (ACA-4788) - Live migration and storage migration
- [ ] **hv_migration_network** (ACA-4812) - Migration network configuration

#### Storage Advanced (Week 11-12)
- [ ] **hv_storage_pool** (ACA-4808) - Storage pool management
- [ ] **hv_san_adapter** (ACA-4809) - Fibre Channel SAN adapter management

---

### Phase 4: Enterprise Features & Clustering (Priority: Medium)

**Timeline**: Weeks 13-16

#### Clustering (Week 13-14)
- [ ] **hyperv_cluster.py** - Module util for clustering operations
- [ ] **hv_cluster_node_maintenance** (ACA-4826) - Cluster node drain and maintenance mode
- [ ] **hv_cluster_group_set** (ACA-4827) - Anti-affinity and cluster group sets
- [ ] **hv_vm_group** (ACA-4816) - VM grouping for placement rules

#### Replication & DR (Week 15)
- [ ] **hv_replication** (ACA-4810) - Hyper-V Replica configuration (VM-level)
- [ ] **hv_replication_server** (ACA-4811) - Replication server settings (Host-level)

#### Guest Integration (Week 16)
- [ ] **hyperv_guest_integration.py** - Module util for PowerShell Direct
- [ ] **hv_guest** (ACA-4821, ACA-4822) - ✨ **CONSOLIDATED** - Execute commands and copy files via PowerShell Direct

---

### Phase 5: Specialized Features (Priority: Low)

**Timeline**: Weeks 17-20

#### High-Performance Computing (Week 17)
- [ ] **hv_hardware_passthrough** (ACA-4813, ACA-4814) - ✨ **CONSOLIDATED** - GPU partitioning and Discrete Device Assignment
- [ ] **hv_nested_virt** (ACA-4817) - Nested virtualization support

#### Security & Advanced (Week 18-20)
- [ ] **hv_shielded_vm** (ACA-4815) - Shielded VM and Key Protector configuration
- [ ] **hv_resource_pool** (ACA-4828) - Resource pool management and metering

---

## Consolidated Modules Reference

The following modules combine functionality from multiple original tasks:

| Consolidated Module | Combines Original Tickets | Rationale |
|---------------------|--------------------------|-----------|
| **hv_vm_state** | ACA-4783, ACA-4784 | All power state operations (start, stop, restart, pause) |
| **hv_network_adapter** | ACA-4794, 4799, 4800, 4803 | Adapter configuration with VLAN, MAC, and QoS properties |
| **hv_vm_boot** | ACA-4796, ACA-4820 | Boot configuration for both Gen1 (BIOS) and Gen2 (firmware) |
| **hv_host** | ACA-4818, ACA-4819 | Host-level settings including console configuration |
| **hv_vswitch** | ACA-4798, ACA-4805 | Virtual switch with extensions |
| **hv_network_acl** | ACA-4801, ACA-4802 | Standard and extended ACL rules |
| **hv_vhd** | ACA-4806, ACA-4807 | VHD lifecycle including file operations and mounting |
| **hv_vm_transfer** | ACA-4786, ACA-4787 | Export and import operations |
| **hv_guest** | ACA-4821, ACA-4822 | PowerShell Direct command execution and file copy |
| **hv_hardware_passthrough** | ACA-4813, ACA-4814 | GPU partitioning and DDA for direct hardware access |

**Note**: Original module names (e.g., `hv_vm_restart`, `hv_vlan`) will be provided as deprecated aliases pointing to the consolidated modules for backward compatibility.

---

## Release Strategy

### Version 0.1.0 (Initial Release)
**Target**: Q2 2026

**Includes**:
- Module utils foundation (hyperv_connection, hyperv_core, hyperv_validation, hyperv_powershell)
- Core VM lifecycle: hv_vm, hv_vm_state, hv_checkpoint
- Information gathering: hv_vm_info, hv_host_info
- Host configuration: hv_host
- Basic hardware: hv_processor, hv_memory

**Deliverables**:
- Complete module documentation
- Integration test suite
- 5+ example playbooks

---

### Version 0.2.0
**Target**: Q3 2026

**Includes**:
- Complete hardware configuration (storage, networking)
- Virtual switch and network adapter management
- Boot configuration support
- VHD management

**Deliverables**:
- Network configuration examples
- Storage provisioning playbooks
- Performance benchmarks

---

### Version 0.3.0
**Target**: Q3 2026

**Includes**:
- Advanced VM operations (export, import, migration)
- Storage pools and SAN adapters
- Network ACLs and isolation
- Guest integration services

**Deliverables**:
- Backup/restore playbooks
- Migration automation examples
- Network security configurations

---

### Version 1.0.0 (Stable Release)
**Target**: Q4 2026

**Includes**:
- All Phases 1-4 modules complete and tested
- Clustering support
- Replication and DR features
- PowerShell Direct guest operations
- Comprehensive documentation

**Deliverables**:
- Complete role library
- Best practices guide
- Production-ready playbook collection
- Migration guide from other platforms

---

### Version 1.1.0+
**Target**: 2027+

**Includes**:
- Specialized features (GPU, DDA, shielded VMs)
- Resource metering and pools
- Community-requested features
- Performance optimizations

---

## Module Utils Architecture

Shared libraries for code reuse (40-55% code reuse estimated):

### Core Utilities
1. **hyperv_connection.py** - PowerShell remoting session management
2. **hyperv_core.py** - VM state checking, idempotency helpers, error parsing
3. **hyperv_validation.py** - Parameter validation, Gen1/Gen2 compatibility checks
4. **hyperv_powershell.py** - Script generation, parameter escaping, JSON parsing

### Specialized Utilities
5. **hyperv_network.py** - Network adapter operations, switch validation
6. **hyperv_storage.py** - VHD operations, disk size parsing, controller management
7. **hyperv_cluster.py** - Cluster node detection, CSV validation, resource enumeration
8. **hyperv_guest_integration.py** - PowerShell Direct session handling, file transfer

**Benefits**:
- Centralized error handling
- Consistent validation patterns
- Bug fixes benefit all modules
- Reduced testing surface area

---

## Testing Strategy

### Unit Tests
- Mock PowerShell cmdlet responses
- Test parameter validation logic
- Test state transition logic
- Minimum 80% code coverage target

### Integration Tests
- Real Hyper-V infrastructure testing
- Gen1 and Gen2 VM scenarios
- Clustered and standalone host scenarios
- Windows Server 2016, 2019, 2022 compatibility

### Sanity Tests
- Ansible coding standards (ansible-test sanity)
- Documentation completeness
- YAML syntax validation

### Performance Tests
- Module execution time benchmarks
- Large-scale deployment scenarios (100+ VMs)
- Concurrent operation testing

---

## Documentation Requirements

Each module must include:

### Code Documentation
- Complete DOCUMENTATION block with all parameters
- Comprehensive EXAMPLES section (minimum 3 examples)
- Detailed RETURN block documenting all return values
- NOTES section for prerequisites and caveats

### Collection Documentation
- Module reference guide (MODULES.md)
- Architecture overview
- Best practices guide
- Migration guides from other platforms
- Troubleshooting guide

---

## Contributing

Community contributions are welcome! Please refer to:
- [CONTRIBUTING.md](../../CONTRIBUTING.md) - Contribution guidelines and workflows
- [EPIC_COMPARISON.md](EPIC_COMPARISON.md) - Consolidation strategy details
- [MODULES.md](MODULES.md) - Complete module reference
- Individual Jira tasks in Epic [ACA-4728](https://issues.redhat.com/browse/ACA-4728)

---

## Timeline Summary

| Quarter | Milestone | Modules Delivered | Status |
|---------|-----------|-------------------|--------|
| Q1 2026 | Foundation | Module utils + 6 core modules | Planning |
| Q2 2026 | v0.1.0 Release | 12 modules total | Planning |
| Q3 2026 | v0.2.0 + v0.3.0 | 25 modules total | Planning |
| Q4 2026 | v1.0.0 Stable | 35 modules total | Planning |
| 2027+ | v1.1.0+ | Enhancements & community features | Planning |

---

## Questions or Feedback

For questions about the roadmap or to provide feedback:
- Open an issue on [GitHub](https://github.com/ansible-collections/microsoft.hyperv/issues)
- Join discussions on the [Ansible Forum](https://forum.ansible.com/tag/hyperv)
- Reference Epic [ACA-4728](https://issues.redhat.com/browse/ACA-4728) for detailed task tracking
- Review the [EPIC_COMPARISON.md](EPIC_COMPARISON.md) for consolidation rationale

---

**Last Updated**: 2026-02-09
**Version**: 2.0 (Hybrid Consolidation Strategy)
**Status**: Approved for Implementation
