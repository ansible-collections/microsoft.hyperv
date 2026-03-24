==========================================
Microsoft Hyper-V Collection Release Notes
==========================================

.. contents:: Topics

v1.0.0
======

Minor Changes
-------------

- Align collection structure with standard Ansible conventions for modules and tests.
- Implement foundational module_utils (`hyperv_connection`, `hyperv_core`, `hyperv_powershell`) for remote Hyper-V management via PSRP.
- hv_checkpoint - Manage Hyper-V Virtual Machine Checkpoints (Snapshots).
- hv_dvd_drive - Manage virtual DVD drives and ISO mounting for Hyper-V Virtual Machines.
- hv_hard_disk - Manage Hyper-V Virtual Machine Hard Disk Drives.
- hv_host - Manage global host-level settings for the Hyper-V hypervisor.
- hv_host_info - Gather facts about the Hyper-V host.
- hv_memory - Manage Hyper-V Virtual Machine Memory Settings.
- hv_network_adapter - Manage Hyper-V Virtual Machine Network Adapters.
- hv_processor - Manage Hyper-V Virtual Machine Processors (vCPU).
- hv_scsi_controller - Manage the number of synthetic SCSI controllers attached to a Hyper-V Virtual Machine.
- hv_storage_pool - Manage Hyper-V Storage Resource Pools.
- hv_vhd - Manage Hyper-V Virtual Hard Disk (VHD/VHDX) files.
- hv_vm - Manage the creation and removal of Virtual Machines on a Hyper-V host.
- hv_vm_boot - Manage boot configuration for Hyper-V Virtual Machines.
- hv_vm_info - Gather information about Hyper-V Virtual Machines.
- hv_vm_state - Manage the power state of virtual machines on a Hyper-V host.
