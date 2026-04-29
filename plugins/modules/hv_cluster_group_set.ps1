#!powershell

# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
    options = @{
        name = @{ type = "str"; required = $true }
        groups = @{ type = "list"; elements = "str" }
        providers = @{ type = "list"; elements = "str" }
        state = @{ type = "str"; default = "present"; choices = @("present", "absent") }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$name = $module.Params.name
$groups = $module.Params.groups
$providers = $module.Params.providers
$state = $module.Params.state

$module.Result.name = $name

# Verify clustering cmdlets are available
if (-not (Get-Command "Get-ClusterGroupSet" -ErrorAction SilentlyContinue)) {
    $module.FailJson("Failover Clustering module is not available on this host. Ensure the RSAT-Clustering feature is installed.")
}

try {
    # Check if cluster service is running
    $cluster = Get-Cluster -ErrorAction SilentlyContinue
    if (-not $cluster) {
        $module.FailJson("This host is not a member of an active Failover Cluster.")
    }

    $groupSet = Get-ClusterGroupSet -Name $name -ErrorAction SilentlyContinue
    $setExists = ($null -ne $groupSet)

    # Initialize current state variables early for accurate change detection in Check Mode
    $currentGroups = @()
    $currentProviders = @()

    if ($setExists) {
        if ($groupSet.GroupNames) {
            $currentGroups = @($groupSet.GroupNames | Sort-Object)
        }
        $depObj = Get-ClusterGroupSetDependency -Name $name -ErrorAction SilentlyContinue
        if ($depObj -and $depObj.ProviderSet) {
            $currentProviders = @($depObj.ProviderSet | Sort-Object)
        }
    }

    switch ($state) {
        "present" {
            $changed = $false

            if (-not $setExists) {
                $changed = $true
                if (-not $module.CheckMode) {
                    $groupSet = New-ClusterGroupSet -Name $name -ErrorAction Stop
                }
            }

            # Manage Group Members
            if ($module.Params.ContainsKey("groups")) {
                $desiredGroups = @()
                if ($null -ne $groups) {
                    $desiredGroups = @($groups | Sort-Object)
                }

                $groupsToAdd = $desiredGroups | Where-Object { $currentGroups -notcontains $_ }
                $groupsToRemove = $currentGroups | Where-Object { $desiredGroups -notcontains $_ }

                if ($groupsToAdd -or $groupsToRemove) {
                    $changed = $true
                    if (-not $module.CheckMode) {
                        foreach ($gName in $groupsToAdd) {
                            Add-ClusterGroupToSet -Name $name -Group $gName -ErrorAction Stop
                        }
                        foreach ($gName in $groupsToRemove) {
                            Remove-ClusterGroupFromSet -Name $name -Group $gName -ErrorAction Stop
                        }
                    }
                }
            }

            # Manage Provider Dependencies
            if ($module.Params.ContainsKey("providers")) {
                $desiredProviders = @()
                if ($null -ne $providers) {
                    $desiredProviders = @($providers | Sort-Object)
                }

                $providersToAdd = $desiredProviders | Where-Object { $currentProviders -notcontains $_ }
                $providersToRemove = $currentProviders | Where-Object { $desiredProviders -notcontains $_ }

                if ($providersToAdd -or $providersToRemove) {
                    $changed = $true
                    if (-not $module.CheckMode) {
                        foreach ($pName in $providersToAdd) {
                            Add-ClusterGroupSetDependency -Name $name -Provider $pName -ErrorAction Stop
                        }
                        foreach ($pName in $providersToRemove) {
                            Remove-ClusterGroupSetDependency -Name $name -Provider $pName -ErrorAction Stop
                        }
                    }
                }
            }

            $module.Result.changed = $changed

            # Output Forecasting / Result gathering
            if ($module.CheckMode) {
                $module.Result.groups = if ($module.Params.ContainsKey("groups")) { $desiredGroups } else { $currentGroups }
                $module.Result.providers = if ($module.Params.ContainsKey("providers")) { $desiredProviders } else { $currentProviders }
                $module.ExitJson()
            }

            # Actual final state retrieval
            $finalSet = Get-ClusterGroupSet -Name $name -ErrorAction SilentlyContinue
            if ($finalSet -and $finalSet.GroupNames) {
                $module.Result.groups = @($finalSet.GroupNames | Sort-Object)
            }
            else {
                $module.Result.groups = @()
            }

            $finalDepObj = Get-ClusterGroupSetDependency -Name $name -ErrorAction SilentlyContinue
            if ($finalDepObj -and $finalDepObj.ProviderSet) {
                $module.Result.providers = @($finalDepObj.ProviderSet | Sort-Object)
            }
            else {
                $module.Result.providers = @()
            }
        }
        "absent" {
            if (-not $setExists) {
                $module.Result.changed = $false
                $module.ExitJson()
            }

            $module.Result.changed = $true
            if ($module.CheckMode) {
                $module.ExitJson()
            }

            Remove-ClusterGroupSet -Name $name -ErrorAction Stop | Out-Null
        }
    }

    $module.ExitJson()
}
catch {
    $module.FailJson("Failed to manage Cluster Group Set '$name': $($_.Exception.Message)")
}
