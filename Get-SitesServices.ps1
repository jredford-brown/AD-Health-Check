function Get-SitesServices {
    param (
        $allDomains = [string]$sitesAndHosts
    )

    foreach ($dc in $allDomains) {
        $site = $dc.Site
        $hostname = $dc.HostName
        $output = repadmin /showreps $hostname
        $replicationInterval = Get-ADReplicationSiteLink -Filter {SitesIncluded -eq $site}
        $viaRPC = @()
        $viaLast = @()
        Write-Output "Domain Controller: $hostname"
        Write-Output "Site: $site"
        Write-Output "Replication Interval: $($replicationInterval.ReplicationFrequencyInMinutes) minutes"
        Write-Output "Replication Status: "
        Write-Output "Replication Queue: $(repadmin /queue $hostname)"
        foreach ($line in $output) {
            if ($line -match 'via RPC') {
                $viaRPC += $line
            }
            elseif ($line -match 'Last attempt') {
                $viaLast += $line
            }
        }
        $count = [Math]::Min($viaRPC.Count, $viaLast.Count)
        for ($i = 0; $i -lt $count; $i++) {
            Write-Output "$($viaRPC[$i]) $($viaLast[$i])"
        }
        Write-Output ""
    }
}