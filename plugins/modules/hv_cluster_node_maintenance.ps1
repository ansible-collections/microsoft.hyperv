#!powershell

# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
    options = @{
        node_name = @{ type = "str"; required = $true; aliases = @("name") }
        state = @{ type = "str"; default = "maintenance"; choices = @("maintenance", "active") }
        drain = @{ type = "bool"; default = $true }
        target_node = @{ type = "str" }
        wait = @{ type = "bool"; default = $true }
        failback = @{ type = "str"; choices = @("On", "Off") }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$node_name = $module.Params.node_name
$state = $module.Params.state
$drain = $module.Params.drain
$target_node = $module.Params.target_node
$wait = $module.Params.wait
$failback = $module.Params.failback

$module.Result.node_name = $node_name

# Verify clustering cmdlets are available
if (-not (Get-Command "Get-ClusterNode" -ErrorAction SilentlyContinue)) {
    $module.FailJson("Failover Clustering module is not available on this host. Ensure the RSAT-Clustering feature is installed.")
}

try {
    $cluster = Get-Cluster -ErrorAction SilentlyContinue
    if (-not $cluster) {
        $module.FailJson("This host is not a member of an active Failover Cluster.")
    }

    $node = Get-ClusterNode -Name $node_name -ErrorAction SilentlyContinue
    if (-not $node) {
        $module.FailJson("Cluster Node '$node_name' not found in the cluster.")
    }

    # Map PowerShell enum: Up (0), Down (1), Paused (2)
    $isPaused = ($node.State -eq 2)

    switch ($state) {
        "maintenance" {
            $hasRoles = $false
            if ($drain) {
                # Check if there are any non-core roles still on the node
                $roles = Get-ClusterGroup -ErrorAction SilentlyContinue | Where-Object { ($_.OwnerNode.Name -eq $node_name) -and ($_.IsCoreGroup -eq $false) }
                if ($roles) { $hasRoles = $true }
            }

            if ($isPaused -and (-not $drain -or -not $hasRoles)) {
                # Already in maintenance mode and no drain requested or no roles to drain
                $module.Result.changed = $false
                $module.Result.state = "maintenance"
                $module.ExitJson()
            }

            $module.Result.changed = $true
            $module.Result.state = "maintenance"

            if ($module.CheckMode) {
                $module.ExitJson()
            }

            $suspendParams = @{
                Name = $node_name
                ErrorAction = "Stop"
            }

            if ($drain) {
                $suspendParams.Drain = $true
                if ($null -ne $target_node) { $suspendParams.TargetNode = $target_node }
                if ($wait) { $suspendParams.Wait = $true }
            }

            Suspend-ClusterNode @suspendParams | Out-Null
        }
        "active" {
            if (-not $isPaused) {
                # Already active
                $module.Result.changed = $false
                $module.Result.state = "active"
                $module.ExitJson()
            }

            $module.Result.changed = $true
            $module.Result.state = "active"

            if ($module.CheckMode) {
                $module.ExitJson()
            }

            $resumeParams = @{
                Name = $node_name
                ErrorAction = "Stop"
            }

            if ($null -ne $failback) {
                if ($failback -eq "On") {
                    $resumeParams.Failback = "Failback" # Equivalent to string for parameter
                }
                else {
                    $resumeParams.Failback = "NoFailback"
                }
            }

            Resume-ClusterNode @resumeParams | Out-Null
        }
    }

    $module.ExitJson()
}
catch {
    $module.FailJson("Failed to manage cluster node maintenance mode for '$node_name': $($_.Exception.Message)")
}
