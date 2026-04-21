#!powershell

# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.hyperv.plugins.module_utils.HyperV

$spec = @{
    options = @{
        name = @{ type = "str"; required = $true }
        path = @{ type = "str"; required = $true }
        state = @{ type = "str"; default = "exported"; choices = @("exported", "imported") }
        import_mode = @{ type = "str"; default = "copy"; choices = @("register", "restore", "copy") }
        vhd_destination_path = @{ type = "str" }
        virtual_machine_path = @{ type = "str" }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$name = $module.Params.name
$path = $module.Params.path
$state = $module.Params.state
$import_mode = $module.Params.import_mode
$vhd_destination_path = $module.Params.vhd_destination_path
$virtual_machine_path = $module.Params.virtual_machine_path

$module.Result.name = $name
$module.Result.path = $path

try {
    if ($state -eq "exported") {
        $vm = Get-VM -Name $name -ErrorAction SilentlyContinue
        if (-not $vm) {
            $module.FailJson("Virtual Machine '$name' not found for export.")
        }

        # Check if export already exists for idempotency
        $exportFolder = Join-Path $path $name
        if (Test-Path -LiteralPath $exportFolder) {
            $module.Result.changed = $false
            $module.Result.id = $vm.Id.ToString()
            $module.ExitJson()
        }

        $module.Result.changed = $true
        if ($module.CheckMode) {
            $module.ExitJson()
        }

        if (-not (Test-Path -LiteralPath $path)) {
            New-Item -ItemType Directory -Path $path -Force -ErrorAction Stop | Out-Null
        }

        $exportedVM = Export-VM -VM $vm -Path $path -Passthru -ErrorAction Stop
        $module.Result.id = $exportedVM.Id.ToString()
    }
    else {
        # state: imported
        if (-not (Test-Path -LiteralPath $path)) {
            $module.FailJson("Import configuration file not found at path: $path")
        }

        # Check if VM with requested name already exists
        $existingVM = Get-VM -Name $name -ErrorAction SilentlyContinue
        if ($existingVM) {
            $module.Result.changed = $false
            $module.Result.id = $existingVM.Id.ToString()
            $module.ExitJson()
        }

        $module.Result.changed = $true
        if ($module.CheckMode) {
            $module.ExitJson()
        }

        $importParams = @{
            Path = $path
            ErrorAction = "Stop"
        }

        switch ($import_mode) {
            "register" {
                $importParams.Register = $true
            }
            "restore" {
                $importParams.Copy = $true
                if ($vhd_destination_path) { $importParams.VhdDestinationPath = $vhd_destination_path }
                if ($virtual_machine_path) { $importParams.VirtualMachinePath = $virtual_machine_path }
            }
            "copy" {
                $importParams.Copy = $true
                $importParams.GenerateNewId = $true
                if ($vhd_destination_path) { $importParams.VhdDestinationPath = $vhd_destination_path }
                if ($virtual_machine_path) { $importParams.VirtualMachinePath = $virtual_machine_path }
            }
        }

        $importedVM = Import-VM @importParams

        # If the name in the config doesn't match requested name, rename it
        if ($importedVM.Name -ne $name) {
            Rename-VM -VM $importedVM -NewName $name -ErrorAction Stop
            $importedVM = Get-VM -Id $importedVM.Id -ErrorAction Stop
        }

        $module.Result.id = $importedVM.Id.ToString()
    }

    $module.ExitJson()
}
catch {
    $module.FailJson("Failed to transfer VM: $($_.Exception.Message)")
}
