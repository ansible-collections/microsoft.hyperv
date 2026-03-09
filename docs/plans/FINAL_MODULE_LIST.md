# Final Module List - Microsoft Hyper-V Collection

**Epic**: [ACA-4728](https://issues.redhat.com/browse/ACA-4728)
**Total Modules**: 35
**Original Tasks**: 47
**Consolidation**: 12 modules eliminated (26% reduction)

---

## Module List with Full Details

### 1. hv_vm
**Jira Task**: ACA-4782
**Type**: Standard Module
**Purpose**: VM provisioning and deprovisioning

**Description**: Create and delete Generation 1 and Generation 2 virtual machines. Foundation module for all VM operations.

**PowerShell Cmdlets**:
- `New-VM`
- `Remove-VM`
- `Get-VM`

**Key Parameters**:
```yaml
name: str (required)
generation: int (1 or 2, default: 2)
memory_startup_bytes: str (e.g., "4GB")
state: str (present, absent)
```

**Example**:
```yaml
- name: Create Gen2 VM
  microsoft.hyperv.hv_vm:
    name: WebServer01
    generation: 2
    memory_startup_bytes: 4GB
    state: present
```

---

### 2. hv_vm_state ✨ CONSOLIDATED
**Jira Tasks**: ACA-4783, ACA-4784
**Type**: Consolidated Module
**Combines**: Power management + VM restart
**Purpose**: Manage all VM power states including start, stop, pause, save, resume, and restart

**Description**: Unified power state management for virtual machines. Handles graceful shutdown, forced turnoff, pause/resume, save/restore, and restart operations. Consolidates what were originally two separate modules (hv_vm_state and hv_vm_restart) into a single coherent interface.

**PowerShell Cmdlets**:
- `Start-VM`
- `Stop-VM`
- `Suspend-VM`
- `Resume-VM`
- `Save-VM`
- `Restart-VM`

**Key Parameters**:
```yaml
name: str (required)
state: str (running, stopped, paused, saved, restarted)
force: bool (default: false)
wait_for_shutdown: bool (default: true)
shutdown_timeout: int (seconds, default: 300)
```

**Example**:
```yaml
- name: Gracefully restart VM
  microsoft.hyperv.hv_vm_state:
    name: Database01
    state: restarted
    wait_for_shutdown: true
    shutdown_timeout: 600
```

**Replaces Deprecated Modules**:
- `hv_vm_restart` - Use `state: restarted` instead

---

### 3. hv_checkpoint
**Jira Task**: ACA-4785
**Type**: Standard Module
**Purpose**: Manage VM snapshots/checkpoints

**Description**: Create, restore, and remove VM checkpoints (snapshots). Essential for pre-patch safety nets and configuration rollback scenarios.

**PowerShell Cmdlets**:
- `Checkpoint-VM`
- `Restore-VMCheckpoint`
- `Remove-VMCheckpoint`
- `Get-VMCheckpoint`

**Key Parameters**:
```yaml
vm_name: str (required)
checkpoint_name: str
state: str (present, absent, restored)
checkpoint_type: str (Standard, Production)
```

**Example**:
```yaml
- name: Create pre-patch checkpoint
  microsoft.hyperv.hv_checkpoint:
    vm_name: SQLServer01
    checkpoint_name: "Pre-Patch-{{ ansible_date_time.date }}"
    checkpoint_type: Standard
    state: present
```

---

### 4. hv_vm_transfer ✨ CONSOLIDATED
**Jira Tasks**: ACA-4786, ACA-4787
**Type**: Consolidated Module
**Combines**: VM export + VM import
**Purpose**: Export and import virtual machines for backup, restore, and cloning

**Description**: Handles VM export to portable format and import from exported files. Supports in-place registration, copy, and clone operations. Consolidates export and import operations which are complementary backup/restore workflows.

**PowerShell Cmdlets**:
- `Export-VM`
- `Import-VM`

**Key Parameters**:
```yaml
operation: str (export, import) (required)
vm_name: str (for export)
source_path: str (for import)
destination_path: str (required)
import_type: str (register, copy, clone)
```

**Example**:
```yaml
- name: Export VM as golden image
  microsoft.hyperv.hv_vm_transfer:
    operation: export
    vm_name: GoldenImage2022
    destination_path: \\FileServer\VMs\GoldenImages\

- name: Import VM clone
  microsoft.hyperv.hv_vm_transfer:
    operation: import
    source_path: \\FileServer\VMs\GoldenImages\GoldenImage2022
    vm_name: WebServer01
    import_type: copy
```

**Replaces Deprecated Modules**:
- `hv_vm_export` - Use `operation: export`
- `hv_vm_import` - Use `operation: import`

---

### 5. hv_vm_move
**Jira Task**: ACA-4788
**Type**: Standard Module
**Purpose**: Live migrate virtual machines

**Description**: Orchestrate live migration (host-to-host) and storage migration without VM downtime. Supports shared-nothing live migration.

**PowerShell Cmdlets**:
- `Move-VM`

**Key Parameters**:
```yaml
vm_name: str (required)
destination_host: str (for host migration)
destination_path: str (for storage migration)
migration_type: str (live, storage, shared_nothing)
```

**Example**:
```yaml
- name: Live migrate to Host02
  microsoft.hyperv.hv_vm_move:
    vm_name: App01
    destination_host: HyperV-Host02
    migration_type: live
```

---

### 6. hv_vm_tag
**Jira Task**: ACA-4825
**Type**: Standard Module
**Purpose**: Manage VM metadata tags

**Description**: Implement tagging system for VMs using Notes field or Registry. Enables dynamic inventory grouping and categorization.

**PowerShell Cmdlets**:
- `Set-VM` (Notes field)
- Registry operations for persistent tags

**Key Parameters**:
```yaml
vm_name: str (required)
tags: dict (key-value pairs)
state: str (present, absent)
storage_method: str (notes, registry)
```

**Example**:
```yaml
- name: Tag production VMs
  microsoft.hyperv.hv_vm_tag:
    vm_name: WebServer01
    tags:
      Environment: Production
      Application: WebFrontend
      Owner: TeamA
    state: present
```

---

### 7. hv_vm_group
**Jira Task**: ACA-4816
**Type**: Standard Module
**Purpose**: Manage VM groups for placement rules

**Description**: Create VM groups for anti-affinity and placement policies. Used with clustering to ensure redundant VMs don't run on same physical host.

**PowerShell Cmdlets**:
- `New-VMGroup`
- `Add-VMGroupMember`
- `Remove-VMGroup`

**Key Parameters**:
```yaml
name: str (required)
group_type: str (VMCollectionType, ManagementCollectionType)
members: list (VM names)
state: str (present, absent)
```

**Example**:
```yaml
- name: Create SQL cluster group
  microsoft.hyperv.hv_vm_group:
    name: SQL-Cluster-Group
    group_type: VMCollectionType
    members:
      - SQL-Node1
      - SQL-Node2
    state: present
```

---

### 8. hv_processor
**Jira Task**: ACA-4789
**Type**: Standard Module
**Purpose**: Configure virtual CPU settings

**Description**: Manage vCPU count, reservation, limits, and compatibility mode. Includes nested virtualization extension support.

**PowerShell Cmdlets**:
- `Set-VMProcessor`
- `Get-VMProcessor`

**Key Parameters**:
```yaml
vm_name: str (required)
count: int (vCPU count)
reserve: int (percentage)
limit: int (percentage)
expose_virtualization_extensions: bool (for nested virt)
compatibility_mode: str
```

**Example**:
```yaml
- name: Configure processor for nested virtualization
  microsoft.hyperv.hv_processor:
    vm_name: BuildAgent01
    count: 4
    expose_virtualization_extensions: true
```

---

### 9. hv_memory
**Jira Task**: ACA-4790
**Type**: Standard Module
**Purpose**: Configure dynamic memory settings

**Description**: Configure static or dynamic memory allocation with startup, minimum, maximum, and buffer settings.

**PowerShell Cmdlets**:
- `Set-VMMemory`
- `Get-VMMemory`

**Key Parameters**:
```yaml
vm_name: str (required)
startup_bytes: str
dynamic_memory: bool
minimum_bytes: str
maximum_bytes: str
buffer: int (percentage)
priority: int (0-100)
```

**Example**:
```yaml
- name: Configure dynamic memory
  microsoft.hyperv.hv_memory:
    vm_name: WebServer01
    startup_bytes: 4GB
    dynamic_memory: true
    minimum_bytes: 2GB
    maximum_bytes: 16GB
    buffer: 20
```

---

### 10. hv_scsi_controller
**Jira Task**: ACA-4791
**Type**: Standard Module
**Purpose**: Manage SCSI controllers

**Description**: Add or remove synthetic SCSI controllers. Required for Gen2 VMs and hot-add disk scenarios.

**PowerShell Cmdlets**:
- `Add-VMScsiController`
- `Remove-VMScsiController`
- `Get-VMScsiController`

**Key Parameters**:
```yaml
vm_name: str (required)
controller_number: int
state: str (present, absent)
```

**Example**:
```yaml
- name: Add secondary SCSI controller
  microsoft.hyperv.hv_scsi_controller:
    vm_name: Database01
    controller_number: 1
    state: present
```

---

### 11. hv_hard_disk
**Jira Task**: ACA-4792
**Type**: Standard Module
**Purpose**: Attach/detach virtual hard disks

**Description**: Attach existing VHDX files to VM's IDE or SCSI controllers at specific locations.

**PowerShell Cmdlets**:
- `Add-VMHardDiskDrive`
- `Remove-VMHardDiskDrive`
- `Set-VMHardDiskDrive`

**Key Parameters**:
```yaml
vm_name: str (required)
controller_type: str (IDE, SCSI)
controller_number: int
controller_location: int
path: str (VHDX file path)
state: str (present, absent)
```

**Example**:
```yaml
- name: Attach data disk
  microsoft.hyperv.hv_hard_disk:
    vm_name: Database01
    controller_type: SCSI
    controller_number: 0
    controller_location: 1
    path: D:\VMs\Database01\Data.vhdx
    state: present
```

---

### 12. hv_dvd_drive
**Jira Task**: ACA-4793
**Type**: Standard Module
**Purpose**: Manage virtual DVD drives and ISO mounting

**Description**: Add DVD drives, mount ISO images, and eject media for OS installation and software deployment.

**PowerShell Cmdlets**:
- `Set-VMDvdDrive`
- `Add-VMDvdDrive`
- `Remove-VMDvdDrive`

**Key Parameters**:
```yaml
vm_name: str (required)
controller_number: int
controller_location: int
path: str (ISO file path, optional)
state: str (present, absent, mounted, ejected)
```

**Example**:
```yaml
- name: Mount installation ISO
  microsoft.hyperv.hv_dvd_drive:
    vm_name: NewServer01
    controller_number: 0
    controller_location: 1
    path: \\FileServer\ISOs\WindowsServer2022.iso
    state: mounted
```

---

### 13. hv_network_adapter ✨ CONSOLIDATED
**Jira Tasks**: ACA-4794, ACA-4799, ACA-4800, ACA-4803
**Type**: Consolidated Module
**Combines**: Network adapter + VLAN + MAC address + Bandwidth (QoS)
**Purpose**: Comprehensive network adapter configuration

**Description**: Unified module for managing virtual network adapters and all their properties. Configure adapter, VLAN tagging, MAC address (static/spoofing), and bandwidth limits atomically. Consolidates 4 modules that previously managed different aspects of the same network adapter object.

**PowerShell Cmdlets**:
- `Add-VMNetworkAdapter`
- `Remove-VMNetworkAdapter`
- `Set-VMNetworkAdapter`
- `Set-VMNetworkAdapterVlan`

**Key Parameters**:
```yaml
vm_name: str (required)
adapter_name: str (required)
switch_name: str
vlan_id: int (1-4094, optional)
mac_address: str (optional)
mac_spoofing: bool (optional)
bandwidth_minimum: int (bits/sec, optional)
bandwidth_maximum: int (bits/sec, optional)
state: str (present, absent)
```

**Example**:
```yaml
- name: Configure production network adapter with all properties
  microsoft.hyperv.hv_network_adapter:
    vm_name: WebServer01
    adapter_name: Production
    switch_name: ConvergedSwitch
    vlan_id: 100
    mac_address: "00:15:5D:01:02:03"
    mac_spoofing: false
    bandwidth_maximum: 1000000000  # 1 Gbps
    bandwidth_minimum: 100000000   # 100 Mbps reserved
    state: present
```

**Replaces Deprecated Modules**:
- `hv_vlan` - Use `vlan_id` parameter
- `hv_mac_address` - Use `mac_address` and `mac_spoofing` parameters
- `hv_bandwidth` - Use `bandwidth_minimum` and `bandwidth_maximum` parameters

---

### 14. hv_com_port
**Jira Task**: ACA-4795
**Type**: Standard Module
**Purpose**: Configure COM/serial ports

**Description**: Configure named pipes for COM ports, used for kernel debugging and legacy application support.

**PowerShell Cmdlets**:
- `Set-VMComPort`
- `Get-VMComPort`

**Key Parameters**:
```yaml
vm_name: str (required)
port_number: int (1 or 2)
path: str (named pipe path)
state: str (present, absent)
```

**Example**:
```yaml
- name: Configure COM1 for kernel debugging
  microsoft.hyperv.hv_com_port:
    vm_name: DebugTarget
    port_number: 1
    path: \\.\pipe\DebugPipe
    state: present
```

---

### 15. hv_vm_boot ✨ CONSOLIDATED
**Jira Tasks**: ACA-4796, ACA-4820
**Type**: Consolidated Module
**Combines**: Gen2 firmware + Gen1 BIOS
**Purpose**: Unified boot configuration for all VM generations

**Description**: Configure boot settings for both Generation 1 (BIOS) and Generation 2 (UEFI firmware) VMs. Auto-detects VM generation and applies appropriate settings. Handles Secure Boot, boot order, and BIOS settings in a single module.

**PowerShell Cmdlets**:
- `Set-VMFirmware` (Gen2)
- `Set-VMBios` (Gen1)
- `Get-VM` (to detect generation)

**Key Parameters**:
```yaml
vm_name: str (required)
vm_generation: int (1 or 2, auto-detected if not provided)

# Gen2 (firmware) parameters:
secure_boot: bool
secure_boot_template: str (MicrosoftWindows, MicrosoftUEFICertificateAuthority, OpenSourceShieldedVM)
boot_order: list (NetworkAdapter, HardDiskDrive, DvdDrive)
enable_secure_boot: bool

# Gen1 (BIOS) parameters:
numlock: bool
startup_order: list
```

**Example Gen2**:
```yaml
- name: Configure Gen2 VM boot with Secure Boot
  microsoft.hyperv.hv_vm_boot:
    vm_name: WebServer01
    secure_boot: true
    secure_boot_template: MicrosoftWindows
    boot_order:
      - HardDiskDrive
      - NetworkAdapter
```

**Example Gen1**:
```yaml
- name: Configure Gen1 VM BIOS
  microsoft.hyperv.hv_vm_boot:
    vm_name: LegacyApp
    numlock: true
```

**Replaces Deprecated Modules**:
- `hv_firmware` - Use this module for Gen2 VMs
- `hv_vm_bios` - Use this module for Gen1 VMs

---

### 16. hv_integration_service
**Jira Task**: ACA-4797
**Type**: Standard Module
**Purpose**: Manage integration services

**Description**: Enable/disable integration services like Guest Service Interface, Heartbeat, Time Synchronization, VSS, Shutdown, and Data Exchange.

**PowerShell Cmdlets**:
- `Enable-VMIntegrationService`
- `Disable-VMIntegrationService`
- `Get-VMIntegrationService`

**Key Parameters**:
```yaml
vm_name: str (required)
service_name: str (or "all")
  # Options: Guest Service Interface, Heartbeat, Key-Value Pair Exchange,
  #          Shutdown, Time Synchronization, VSS
state: str (enabled, disabled)
```

**Example**:
```yaml
- name: Enable Guest Service Interface for file copy
  microsoft.hyperv.hv_integration_service:
    vm_name: WebServer01
    service_name: "Guest Service Interface"
    state: enabled
```

---

### 17. hv_vswitch ✨ CONSOLIDATED
**Jira Tasks**: ACA-4798, ACA-4805
**Type**: Consolidated Module
**Combines**: Virtual switch + Switch extensions
**Purpose**: Manage virtual switches and their extensions

**Description**: Create and configure virtual switches (External/Internal/Private) with Switch Embedded Teaming (SET) support. Includes management of switch extensions like Microsoft Azure VFP, Cisco Nexus, and third-party SDN tools. Extensions are properties of the switch and should be configured together.

**PowerShell Cmdlets**:
- `New-VMSwitch`
- `Remove-VMSwitch`
- `Set-VMSwitch`
- `Enable-VMSwitchExtension`
- `Disable-VMSwitchExtension`

**Key Parameters**:
```yaml
name: str (required)
type: str (External, Internal, Private)
team_members: list (physical NICs for SET)
allow_management_os: bool
extensions: list
  - name: str
    enabled: bool
state: str (present, absent)
```

**Example**:
```yaml
- name: Create converged switch with Azure VFP extension
  microsoft.hyperv.hv_vswitch:
    name: ConvergedSwitch
    type: External
    team_members:
      - Ethernet1
      - Ethernet2
    allow_management_os: true
    extensions:
      - name: "Microsoft Azure VFP Switch Extension"
        enabled: true
    state: present
```

**Replaces Deprecated Modules**:
- `hv_switch_extension` - Use `extensions` parameter

---

### 18. hv_network_acl ✨ CONSOLIDATED
**Jira Tasks**: ACA-4801, ACA-4802
**Type**: Consolidated Module
**Combines**: Standard ACL + Extended ACL
**Purpose**: Unified ACL management for micro-segmentation

**Description**: Configure both standard and extended (stateful) ACLs on virtual network adapters. Extended ACLs provide enhanced SDN capabilities with protocol and port-based filtering. Consolidates two types of ACLs that work on the same adapter.

**PowerShell Cmdlets**:
- `Add-VMNetworkAdapterAcl`
- `Remove-VMNetworkAdapterAcl`
- `Add-VMNetworkAdapterExtendedAcl`
- `Remove-VMNetworkAdapterExtendedAcl`

**Key Parameters**:
```yaml
vm_name: str (required)
adapter_name: str (required)
acl_type: str (standard, extended)
action: str (allow, deny)
direction: str (inbound, outbound)
remote_ip: str (CIDR notation)
local_ip: str (optional, for extended)
protocol: str (optional, for extended: TCP, UDP, ICMP)
local_port: int (optional, for extended)
remote_port: int (optional, for extended)
weight: int (optional, for extended)
state: str (present, absent)
```

**Example Standard ACL**:
```yaml
- name: Block HTTP traffic to database
  microsoft.hyperv.hv_network_acl:
    vm_name: Database01
    adapter_name: Backend
    acl_type: standard
    action: deny
    direction: inbound
    remote_ip: 0.0.0.0/0
    local_port: 80
    state: present
```

**Example Extended ACL**:
```yaml
- name: Allow stateful SQL traffic
  microsoft.hyperv.hv_network_acl:
    vm_name: WebServer01
    adapter_name: Backend
    acl_type: extended
    action: allow
    direction: outbound
    remote_ip: 10.0.2.0/24
    protocol: TCP
    remote_port: 1433
    weight: 100
    state: present
```

**Replaces Deprecated Modules**:
- `hv_extended_acl` - Use `acl_type: extended`

---

### 19. hv_isolation
**Jira Task**: ACA-4804
**Type**: Standard Module
**Purpose**: Configure network isolation for SDN

**Description**: Configure multi-tenant isolation using VXLAN/NVGRE. Set Virtual Subnet IDs (VSID) for cloud provider scenarios.

**PowerShell Cmdlets**:
- `Set-VMNetworkAdapterIsolation`
- `Get-VMNetworkAdapterIsolation`

**Key Parameters**:
```yaml
vm_name: str (required)
adapter_name: str (required)
isolation_mode: str (VLAN, VXLAN, NVGRE, None)
vsid: int (Virtual Subnet ID for VXLAN/NVGRE)
multi_tenant_stack: str
state: str (present, absent)
```

**Example**:
```yaml
- name: Configure VXLAN isolation
  microsoft.hyperv.hv_isolation:
    vm_name: Tenant01-Web
    adapter_name: Tenant
    isolation_mode: VXLAN
    vsid: 5000
    state: present
```

---

### 20. hv_vhd ✨ CONSOLIDATED
**Jira Tasks**: ACA-4806, ACA-4807
**Type**: Consolidated Module
**Combines**: VHD file operations + VHD mount
**Purpose**: Complete VHD lifecycle management

**Description**: Create, resize, delete, mount, and unmount VHD/VHDX files. Follows the Ansible `mount` module pattern where state determines the operation. Consolidates file operations and mounting which are part of the same storage lifecycle.

**PowerShell Cmdlets**:
- `New-VHD`
- `Remove-VHD`
- `Resize-VHD`
- `Mount-VHD`
- `Dismount-VHD`

**Key Parameters**:
```yaml
path: str (required)
size: str (e.g., "100GB", required for create)
type: str (Fixed, Dynamic, Differencing)
parent_path: str (for Differencing disks)
mount_point: str (drive letter, for mounted state)
state: str (present, absent, mounted, unmounted)
```

**Example Create**:
```yaml
- name: Create dynamic VHDX
  microsoft.hyperv.hv_vhd:
    path: D:\VMs\Data01.vhdx
    size: 500GB
    type: Dynamic
    state: present
```

**Example Mount**:
```yaml
- name: Mount VHD for offline servicing
  microsoft.hyperv.hv_vhd:
    path: D:\VMs\Image.vhdx
    mount_point: E:\
    state: mounted

- name: Inject files...

- name: Dismount VHD
  microsoft.hyperv.hv_vhd:
    path: D:\VMs\Image.vhdx
    state: unmounted
```

**Replaces Deprecated Modules**:
- `hv_vhd_file` - Use `state: present/absent`
- `hv_vhd_mount` - Use `state: mounted/unmounted`

---

### 21. hv_storage_pool
**Jira Task**: ACA-4808
**Type**: Standard Module
**Purpose**: Manage storage pools and quotas

**Description**: Create and manage VM storage resource pools for quota management and departmental separation.

**PowerShell Cmdlets**:
- `New-VMResourcePool`
- `Remove-VMResourcePool`
- `Set-VMResourcePool`

**Key Parameters**:
```yaml
name: str (required)
pool_type: str (VHD, ISO, VFD)
parent_path: str
state: str (present, absent)
```

**Example**:
```yaml
- name: Create HR storage pool
  microsoft.hyperv.hv_storage_pool:
    name: HR_Storage
    pool_type: VHD
    parent_path: D:\VMs\HR
    state: present
```

---

### 22. hv_san_adapter
**Jira Task**: ACA-4809
**Type**: Standard Module
**Purpose**: Manage Fibre Channel SAN adapters (vHBA)

**Description**: Add virtual Fibre Channel HBAs to VMs for direct SAN access in guest clustering scenarios.

**PowerShell Cmdlets**:
- `Add-VMFibreChannelHba`
- `Remove-VMFibreChannelHba`
- `Set-VMFibreChannelHba`

**Key Parameters**:
```yaml
vm_name: str (required)
san_name: str (Fibre Channel SAN name)
world_wide_node_name: str (WWNN)
world_wide_port_name: str (WWPN)
state: str (present, absent)
```

**Example**:
```yaml
- name: Add vHBA for SQL clustering
  microsoft.hyperv.hv_san_adapter:
    vm_name: SQLCluster-Node1
    san_name: ProductionSAN
    state: present
```

---

### 23. hv_replication
**Jira Task**: ACA-4810
**Type**: Standard Module
**Purpose**: Configure Hyper-V Replica (VM-level)

**Description**: Enable and configure VM-level replication to replica servers for disaster recovery.

**PowerShell Cmdlets**:
- `Enable-VMReplication`
- `Disable-VMReplication`
- `Set-VMReplication`

**Key Parameters**:
```yaml
vm_name: str (required)
replica_server: str
replica_port: int (default: 80 or 443)
authentication_type: str (Kerberos, Certificate)
replication_frequency: int (seconds: 30, 300, 900)
state: str (enabled, disabled)
```

**Example**:
```yaml
- name: Enable replication to DR site
  microsoft.hyperv.hv_replication:
    vm_name: CriticalApp01
    replica_server: DR-HyperV-01
    replica_port: 443
    authentication_type: Certificate
    replication_frequency: 300
    state: enabled
```

---

### 24. hv_replication_server
**Jira Task**: ACA-4811
**Type**: Standard Module
**Purpose**: Configure replication server settings (Host-level)

**Description**: Configure the Hyper-V host to receive replication traffic. Set authentication and allowed servers.

**PowerShell Cmdlets**:
- `Set-VMReplicationServer`
- `Get-VMReplicationServer`

**Key Parameters**:
```yaml
replication_enabled: bool
authentication_type: str (Kerberos, Certificate, Both)
allowed_from_any_server: bool
kerberos_authentication_port: int
certificate_authentication_port: int
certificate_thumbprint: str
```

**Example**:
```yaml
- name: Configure DR host to receive replicas
  microsoft.hyperv.hv_replication_server:
    replication_enabled: true
    authentication_type: Certificate
    certificate_authentication_port: 443
    certificate_thumbprint: "ABC123..."
    allowed_from_any_server: false
```

---

### 25. hv_migration_network
**Jira Task**: ACA-4812
**Type**: Standard Module
**Purpose**: Configure live migration networks

**Description**: Define which network subnets are allowed for live migration traffic to isolate migration from production networks.

**PowerShell Cmdlets**:
- `Add-VMMigrationNetwork`
- `Remove-VMMigrationNetwork`
- `Set-VMMigrationNetwork`

**Key Parameters**:
```yaml
subnet: str (CIDR notation)
priority: int
state: str (present, absent)
```

**Example**:
```yaml
- name: Configure dedicated migration network
  microsoft.hyperv.hv_migration_network:
    subnet: 10.0.100.0/24
    priority: 10
    state: present
```

---

### 26. hv_hardware_passthrough ✨ CONSOLIDATED
**Jira Tasks**: ACA-4813, ACA-4814
**Type**: Consolidated Module
**Combines**: GPU partitioning + Discrete Device Assignment (DDA)
**Purpose**: Direct hardware access for high-performance scenarios

**Description**: Configure GPU partitioning (GPU-P) or Discrete Device Assignment (DDA) for passing physical hardware directly to VMs. Both provide direct hardware access for high-performance computing, AI workloads, and specialized devices.

**PowerShell Cmdlets**:
- `Add-VMGpuPartitionAdapter` (GPU-P)
- `Add-VMAssignableDevice` (DDA)
- `Remove-VMGpuPartitionAdapter`
- `Remove-VMAssignableDevice`

**Key Parameters**:
```yaml
vm_name: str (required)
device_type: str (gpu_partition, dda) (required)

# For gpu_partition:
gpu_name: str
partition_count: int
minimum_partition: int
maximum_partition: int
optimal_partition: int

# For dda:
device_location_path: str (PCI path)
device_instance_path: str

state: str (present, absent)
```

**Example GPU Partition**:
```yaml
- name: Assign GPU partition for AI workload
  microsoft.hyperv.hv_hardware_passthrough:
    vm_name: ML-Training-01
    device_type: gpu_partition
    gpu_name: "NVIDIA Tesla T4"
    partition_count: 4
    state: present
```

**Example DDA**:
```yaml
- name: Assign NVMe device via DDA
  microsoft.hyperv.hv_hardware_passthrough:
    vm_name: HighPerformanceDB
    device_type: dda
    device_location_path: "PCIROOT(0)#PCI(0300)#PCI(0000)"
    state: present
```

**Replaces Deprecated Modules**:
- `hv_gpu_partition` - Use `device_type: gpu_partition`
- `hv_dda_device` - Use `device_type: dda`

---

### 27. hv_shielded_vm
**Jira Task**: ACA-4815
**Type**: Standard Module
**Purpose**: Configure shielded VMs with Key Protector

**Description**: Provision Key Protector for shielded VMs to protect against compromised fabric administrators.

**PowerShell Cmdlets**:
- `Set-VMKeyProtector`
- `Set-VMSecurity`
- `Get-VMKeyProtector`

**Key Parameters**:
```yaml
vm_name: str (required)
key_protector: str (base64 encoded)
shield_security_policy: bool
encryption_state: str (encrypted, supported)
state: str (enabled, disabled)
```

**Example**:
```yaml
- name: Enable shielded VM
  microsoft.hyperv.hv_shielded_vm:
    vm_name: SecureApp01
    key_protector: "{{ key_protector_data }}"
    shield_security_policy: true
    encryption_state: encrypted
    state: enabled
```

---

### 28. hv_nested_virt
**Jira Task**: ACA-4817
**Type**: Standard Module
**Purpose**: Enable/disable nested virtualization

**Description**: Helper module to expose virtualization extensions and configure MAC spoofing for nested Hyper-V scenarios (labs, containers, CI/CD).

**PowerShell Cmdlets**:
- `Set-VMProcessor -ExposeVirtualizationExtensions`
- `Set-VMNetworkAdapter -MacAddressSpoofing`

**Key Parameters**:
```yaml
vm_name: str (required)
state: str (enabled, disabled)
```

**Example**:
```yaml
- name: Enable nested virtualization for lab
  microsoft.hyperv.hv_nested_virt:
    vm_name: LabHost01
    state: enabled
```

---

### 29. hv_host ✨ CONSOLIDATED
**Jira Tasks**: ACA-4818, ACA-4819
**Type**: Consolidated Module
**Combines**: Host configuration + Console settings
**Purpose**: Complete Hyper-V host management

**Description**: Configure global Hyper-V host settings including default VM/VHD paths, NUMA spanning, and Enhanced Session Mode (console settings). Both use the same Set-VMHost cmdlet and should be configured together.

**PowerShell Cmdlets**:
- `Set-VMHost`
- `Get-VMHost`

**Key Parameters**:
```yaml
default_vm_path: str
default_vhd_path: str
numa_spanning: bool
enhanced_session_mode: bool
live_migration_type: str (CredSSP, Kerberos, SMB)
max_live_migrations: int
use_any_network_for_migration: bool
```

**Example**:
```yaml
- name: Configure Hyper-V host defaults
  microsoft.hyperv.hv_host:
    default_vm_path: C:\ClusterStorage\Volume1\VMs
    default_vhd_path: C:\ClusterStorage\Volume1\VHDs
    numa_spanning: false
    enhanced_session_mode: true
    max_live_migrations: 4
```

**Replaces Deprecated Modules**:
- `hv_host_config` - All parameters now in `hv_host`
- `hv_vm_console` - Use `enhanced_session_mode` parameter

---

### 30. hv_guest ✨ CONSOLIDATED
**Jira Tasks**: ACA-4821, ACA-4822
**Type**: Consolidated Module
**Combines**: Guest command execution + File copy
**Purpose**: PowerShell Direct operations (VMBus)

**Description**: Execute commands and copy files to/from guest VMs using PowerShell Direct (VMBus), bypassing network requirements. Useful for VMs with broken networking or in isolated DMZs. Similar to VMware's vmware_vm_shell pattern.

**PowerShell Cmdlets**:
- `Invoke-Command -VMName` (PowerShell Direct)
- `Copy-Item` with PowerShell Direct sessions

**Key Parameters**:
```yaml
vm_name: str (required)
operation: str (command, file_copy) (required)
username: str (guest credentials)
password: str (guest credentials)

# For command:
command: str
script_block: str

# For file_copy:
source: str
destination: str
direction: str (to_guest, from_guest)
```

**Example Command Execution**:
```yaml
- name: Execute command in guest
  microsoft.hyperv.hv_guest:
    vm_name: WebServer01
    operation: command
    username: Administrator
    password: "{{ vault_password }}"
    command: "Get-Service -Name W3SVC | Restart-Service"
  register: service_result
```

**Example File Copy**:
```yaml
- name: Copy configuration to guest
  microsoft.hyperv.hv_guest:
    vm_name: WebServer01
    operation: file_copy
    username: Administrator
    password: "{{ vault_password }}"
    source: /ansible/configs/web.config
    destination: C:\inetpub\wwwroot\web.config
    direction: to_guest
```

**Replaces Deprecated Modules**:
- `hv_guest_command` - Use `operation: command`
- `hv_guest_file_copy` - Use `operation: file_copy`

---

### 31. hv_vm_info
**Jira Task**: ACA-4823
**Type**: Standard Module
**Purpose**: Gather VM information and facts

**Description**: Collect comprehensive information about one or all VMs including IPs, MACs, state, uptime, host location, checkpoints, and hardware configuration.

**PowerShell Cmdlets**:
- `Get-VM`
- `Get-VMNetworkAdapter`
- `Get-VMCheckpoint`

**Key Parameters**:
```yaml
vm_name: str (optional, omit for all VMs)
gather_network: bool (default: true)
gather_checkpoints: bool (default: true)
gather_hardware: bool (default: false)
```

**Example**:
```yaml
- name: Gather all VM facts
  microsoft.hyperv.hv_vm_info:
  register: all_vms

- name: Gather specific VM with hardware details
  microsoft.hyperv.hv_vm_info:
    vm_name: WebServer01
    gather_hardware: true
  register: vm_details
```

**Returns**: Structured Ansible facts with VM properties

---

### 32. hv_host_info
**Jira Task**: ACA-4824
**Type**: Standard Module
**Purpose**: Gather Hyper-V host information

**Description**: Collect facts about the Hyper-V host including uptime, memory usage, CPU type, logical processors, virtual switch configuration, and capacity.

**PowerShell Cmdlets**:
- `Get-VMHost`
- `Get-VMSwitch`
- `Get-Counter` (for performance metrics)

**Key Parameters**:
```yaml
gather_switches: bool (default: true)
gather_performance: bool (default: false)
```

**Example**:
```yaml
- name: Gather host capacity info
  microsoft.hyperv.hv_host_info:
    gather_switches: true
    gather_performance: true
  register: host_capacity

- name: Display available memory
  debug:
    msg: "Available memory: {{ host_capacity.memory_available }}"
```

**Returns**: Structured Ansible facts with host properties

---

### 33. hv_cluster_node_maintenance
**Jira Task**: ACA-4826
**Type**: Standard Module
**Purpose**: Drain cluster node for maintenance

**Description**: Orchestrate cluster node drain by pausing the node and live migrating all roles off for zero-downtime host patching.

**PowerShell Cmdlets**:
- `Suspend-ClusterNode`
- `Resume-ClusterNode`
- Drain operations

**Key Parameters**:
```yaml
node_name: str (required)
state: str (maintenance, active)
drain_timeout: int (seconds)
wait_for_drain: bool (default: true)
```

**Example**:
```yaml
- name: Enter maintenance mode
  microsoft.hyperv.hv_cluster_node_maintenance:
    node_name: HyperV-Node01
    state: maintenance
    drain_timeout: 1800
    wait_for_drain: true
```

---

### 34. hv_cluster_group_set
**Jira Task**: ACA-4827
**Type**: Standard Module
**Purpose**: Manage cluster group sets and anti-affinity

**Description**: Create cluster group sets to enforce anti-affinity rules, ensuring redundant VMs never run on the same physical host.

**PowerShell Cmdlets**:
- `New-ClusterGroupSet`
- `Add-ClusterGroupSetDependency`
- `Remove-ClusterGroupSet`

**Key Parameters**:
```yaml
name: str (required)
groups: list (cluster group names)
dependency_type: str (AntiAffinity, Affinity)
state: str (present, absent)
```

**Example**:
```yaml
- name: Create anti-affinity group set for SQL cluster
  microsoft.hyperv.hv_cluster_group_set:
    name: SQL-AntiAffinity
    groups:
      - SQL-Node1-Group
      - SQL-Node2-Group
    dependency_type: AntiAffinity
    state: present
```

---

### 35. hv_resource_pool
**Jira Task**: ACA-4828
**Type**: Standard Module
**Purpose**: Manage resource pools for metering

**Description**: Create and manage processor and memory resource pools for measuring or limiting resource usage per tenant/department for chargeback/showback.

**PowerShell Cmdlets**:
- `New-VMResourcePool`
- `Set-VMResourcePool`
- `Measure-VMResourcePool`

**Key Parameters**:
```yaml
name: str (required)
pool_type: str (Processor, Memory, Ethernet)
state: str (present, absent)
```

**Example**:
```yaml
- name: Create finance department resource pool
  microsoft.hyperv.hv_resource_pool:
    name: Finance_Resources
    pool_type: Processor
    state: present
```

---

## Consolidation Summary

### Modules Consolidated
**Total Consolidations**: 10 modules combining 22 original tasks

| # | Consolidated Module | Original Modules Combined | Tickets |
|---|---------------------|--------------------------|---------|
| 1 | `hv_vm_state` | Power management + Restart | ACA-4783, 4784 |
| 2 | `hv_network_adapter` | Adapter + VLAN + MAC + QoS | ACA-4794, 4799, 4800, 4803 |
| 3 | `hv_vm_boot` | Gen2 Firmware + Gen1 BIOS | ACA-4796, 4820 |
| 4 | `hv_host` | Host config + Console | ACA-4818, 4819 |
| 5 | `hv_vswitch` | Switch + Extensions | ACA-4798, 4805 |
| 6 | `hv_network_acl` | Standard ACL + Extended ACL | ACA-4801, 4802 |
| 7 | `hv_vhd` | File operations + Mount | ACA-4806, 4807 |
| 8 | `hv_vm_transfer` | Export + Import | ACA-4786, 4787 |
| 9 | `hv_guest` | Command + File copy | ACA-4821, 4822 |
| 10 | `hv_hardware_passthrough` | GPU partition + DDA | ACA-4813, 4814 |

### Deprecated Module Names (18 total)
Modules that will show deprecation warnings and redirect to consolidated modules:
1. `hv_vm_restart` → `hv_vm_state`
2. `hv_vlan` → `hv_network_adapter`
3. `hv_mac_address` → `hv_network_adapter`
4. `hv_bandwidth` → `hv_network_adapter`
5. `hv_firmware` → `hv_vm_boot`
6. `hv_vm_bios` → `hv_vm_boot`
7. `hv_host_config` → `hv_host`
8. `hv_vm_console` → `hv_host`
9. `hv_switch_extension` → `hv_vswitch`
10. `hv_extended_acl` → `hv_network_acl`
11. `hv_vhd_file` → `hv_vhd`
12. `hv_vhd_mount` → `hv_vhd`
13. `hv_vm_export` → `hv_vm_transfer`
14. `hv_vm_import` → `hv_vm_transfer`
15. `hv_guest_command` → `hv_guest`
16. `hv_guest_file_copy` → `hv_guest`
17. `hv_gpu_partition` → `hv_hardware_passthrough`
18. `hv_dda_device` → `hv_hardware_passthrough`

---

## Module Utils

All modules utilize shared libraries for code reuse (estimated 45-55%):

1. **hyperv_connection.py** - PowerShell remoting session management
2. **hyperv_core.py** - VM operations, state checking, idempotency
3. **hyperv_validation.py** - Parameter validation, Gen1/Gen2 compatibility
4. **hyperv_powershell.py** - Script generation, parameter escaping
5. **hyperv_network.py** - Network adapter and switch operations
6. **hyperv_storage.py** - VHD and disk operations
7. **hyperv_cluster.py** - Failover clustering operations
8. **hyperv_guest_integration.py** - PowerShell Direct (VMBus) integration

---

**Last Updated**: 2026-02-10
**Epic Status**: Planning
**Total Modules**: 35
**Reduction**: 26% from original 47 tasks
