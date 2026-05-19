# Microsoft Hyper\-V Collection Release Notes

**Topics**

- <a href="#v1-1-0">v1\.1\.0</a>
    - <a href="#minor-changes">Minor Changes</a>
- <a href="#v1-0-0">v1\.0\.0</a>
    - <a href="#minor-changes-1">Minor Changes</a>

<a id="v1-1-0"></a>
## v1\.1\.0

<a id="minor-changes"></a>
### Minor Changes

* All existing modules \- Refactored to utilize the new shared property mapping utilities\, significantly improving maintainability\, type\-safety\, and code consistency\.
* HyperV\.psm1 \- Introduced a suite of shared PowerShell utility functions \(<em class="title-reference">Get\-HyperVParametersFromMap</em>\, <em class="title-reference">Test\-HyperVPropertiesChanged</em>\, <em class="title-reference">Set\-HyperVResultFromMap</em>\) to standardize parameter building\, idempotency checks\, and result population across the collection\.
* hv\_cluster\_group\_set \- Manage Hyper\-V Cluster Group Sets \(Anti\-Affinity\)\.
* hv\_cluster\_node\_maintenance \- Manage Hyper\-V Cluster Node Maintenance Mode\.
* hv\_com\_port \- Manage Hyper\-V Virtual Machine Serial \(COM\) Ports\.
* hv\_guest \- Manage Hyper\-V Guest OS via PowerShell Direct\.
* hv\_guest\_command \- Execute PowerShell scripts in Hyper\-V Guest OS via PowerShell Direct\.
* hv\_guest\_copy \- Transfer files to and from Hyper\-V Guest OS via PowerShell Direct\.
* hv\_hardware\_passthrough \- Manage GPU partitioning \(GPU\-P\) and Discrete Device Assignment \(DDA\)\.
* hv\_integration\_service \- Manage Hyper\-V Virtual Machine Integration Services\.
* hv\_isolation \- Manage Hyper\-V Network Adapter Isolation \(SDN\)\.
* hv\_migration\_network \- Manage Hyper\-V Migration Networks\.
* hv\_nested\_virt \- Enable or disable nested virtualization for Hyper\-V VMs\.
* hv\_network\_acl \- Manage Standard and Extended Network Access Control Lists \(ACLs\) on Hyper\-V virtual network adapters\.
* hv\_replication \- Manage Hyper\-V Virtual Machine Replication\.
* hv\_replication\_server \- Manage Hyper\-V Replica Server Settings\.
* hv\_resource\_pool \- Create and manage resource pools for metering and chargeback\.
* hv\_san\_adapter \- Manage Hyper\-V Virtual Fibre Channel HBAs\.
* hv\_shielded\_vm \- Manage security settings and Key Protectors for secure VMs\.
* hv\_vm\_group \- Manage Hyper\-V Virtual Machine Groups\.
* hv\_vm\_move \- Manage Hyper\-V Virtual Machine Live Migration and Storage Migration\.
* hv\_vm\_tag \- Manage Hyper\-V Virtual Machine Metadata Tags\.
* hv\_vm\_transfer \- Manage Hyper\-V Virtual Machine Export and Import\.
* hv\_vswitch \- Manage Hyper\-V Virtual Switches and extensions\.
* microsoft\.hyperv\.hv\_vm\_guest\_wait \- Wait for VM guest agent and IP addresses \(including CIDR support\) to become available

<a id="v1-0-0"></a>
## v1\.0\.0

<a id="minor-changes-1"></a>
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
