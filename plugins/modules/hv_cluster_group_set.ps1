#!powershell

# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
    options = @{
        name = @{ type = "str"; required = $true }
        groups = @{ type = "list"; elements = "str" }
        provider = @{ type = "str" }
        state = @{ type = "str"; default = "present"; choices = @("present", "absent") }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$name = $module.Params.name
$groups = $module.Params.groups
$provider = $module.Params.provider
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
                $currentGroups = @()
                if ($groupSet) {
                    if ($groupSet.GroupNames) {
                        $currentGroups = @($groupSet.GroupNames | Sort-Object)
                    }
                }

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
            # Manage Provider Dependency
            if ($module.Params.ContainsKey("provider")) {
                $currentProviders = @()
                if ($groupSet -and -not $module.CheckMode) {
                    $depObj = Get-ClusterGroupSetDependency -Name $name -ErrorAction SilentlyContinue
                    if ($depObj) {
                        $currentProviders = @($depObj.ProviderSet | Sort-Object)
                    }
                }

                if ($null -ne $provider) {
                    if ($currentProviders -notcontains $provider) {
                        $changed = $true
                        if (-not $module.CheckMode) {
                            # Add dependency
                            Add-ClusterGroupSetDependency -Name $name -ProviderSet $provider -ErrorAction Stop
                        }
                    }
                }
                else {
                    # Provider passed as null/empty - clear dependencies
                    if ($currentProviders.Count -gt 0) {
                        $changed = $true
                        if (-not $module.CheckMode) {
                            foreach ($p in $currentProviders) {
                                Remove-ClusterGroupSetDependency -Name $name -ProviderSet $p -ErrorAction Stop
                            }
                        }
                    }
                }
            }

            $module.Result.changed = $changed

            # Output Forecasting / Result gathering
            if ($module.CheckMode) {
                if ($module.Params.ContainsKey("groups")) {
                    $module.Result.groups = $desiredGroups
                } else {
                    $module.Result.groups = $currentGroups
                }

                if ($module.Params.ContainsKey("provider")) {
                    $module.Result.provider = $provider
                } else {
                    if ($currentProviders.Count -gt 0) { $module.Result.provider = $currentProviders[0] }
                }
                $module.ExitJson()
            }

            # Actual final state retrieval
            $finalSet = Get-ClusterGroupSet -Name $name -ErrorAction SilentlyContinue
            if ($finalSet -and $finalSet.GroupNames) {
                $module.Result.groups = @($finalSet.GroupNames | Sort-Object)
            } else {
                $module.Result.groups = @()
            }

            $finalDepObj = Get-ClusterGroupSetDependency -Name $name -ErrorAction SilentlyContinue
            if ($finalDepObj -and $finalDepObj.ProviderSet) {
                $module.Result.provider = $finalDepObj.ProviderSet[0]
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
