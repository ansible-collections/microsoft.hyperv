# Microsoft Hyper\-V Collection Release Notes

**Topics**

- <a href="#v1-0-0">v1\.0\.0</a>
    - <a href="#minor-changes">Minor Changes</a>

<a id="v1-0-0"></a>
## v1\.0\.0

<a id="minor-changes"></a>
### Minor Changes

* Align collection structure with standard Ansible conventions for modules and tests\.
* Implement foundational module\_utils \(<em class="title-reference">hyperv\_connection</em>\, <em class="title-reference">hyperv\_core</em>\, <em class="title-reference">hyperv\_powershell</em>\) for remote Hyper\-V management via PSRP\.
* hv\_checkpoint \- Manage Hyper\-V Virtual Machine Checkpoints \(Snapshots\)\.
* hv\_dvd\_drive \- Manage virtual DVD drives and ISO mounting for Hyper\-V Virtual Machines\.
* hv\_hard\_disk \- Manage Hyper\-V Virtual Machine Hard Disk Drives\.
* hv\_host \- Manage global host\-level settings for the Hyper\-V hypervisor\.
* hv\_host\_info \- Gather facts about the Hyper\-V host\.
* hv\_memory \- Manage Hyper\-V Virtual Machine Memory Settings\.
* hv\_network\_adapter \- Manage Hyper\-V Virtual Machine Network Adapters\.
* hv\_processor \- Manage Hyper\-V Virtual Machine Processors \(vCPU\)\.
* hv\_scsi\_controller \- Manage the number of synthetic SCSI controllers attached to a Hyper\-V Virtual Machine\.
* hv\_storage\_pool \- Manage Hyper\-V Storage Resource Pools\.
* hv\_vhd \- Manage Hyper\-V Virtual Hard Disk \(VHD/VHDX\) files\.
* hv\_vm \- Manage the creation and removal of Virtual Machines on a Hyper\-V host\.
* hv\_vm\_boot \- Manage boot configuration for Hyper\-V Virtual Machines\.
* hv\_vm\_info \- Gather information about Hyper\-V Virtual Machines\.
* hv\_vm\_state \- Manage the power state of virtual machines on a Hyper\-V host\.
