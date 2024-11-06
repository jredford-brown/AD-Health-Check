function Get-ADEthernetForwarderConfiguration {
    $forest = Get-ADForest
    $domains = $forest.Domains
    $results = @()

    foreach ($domain in $domains) {
        $dcs = Get-ADDomainController -Filter * -Server $domain
        foreach ($dc in $dcs) {
            try {
                $interfaces = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -ComputerName $dc.HostName -Filter "IPEnabled = True" -ErrorAction Stop
                foreach ($interface in $interfaces) {
                    $ipAddresses = if ($interface.IPAddress) { $interface.IPAddress -join ", " } else { "N/A" }
                    $results += [PSCustomObject]@{
                        DomainController = $dc.Name
                        IPAddress        = $ipAddresses
                        Domain           = $domain
                        DNSAddresses     = $interface.DNSServerSearchOrder -join ", "
                        Forwarders       = "N/A" #Placeholder
                    }
                    #$results += $result
                }
            }
            catch {
                Write-Warning "Unable to retrieve network configuration for $($dc.Name). $_"
                continue
            }
            try {
                $forwarders = Get-DnsServerForwarder -ComputerName $dc.HostName -ErrorAction Stop
                $forwarderAddresses = $forwarders.IPAddress -join ", "
            }
            catch {
                $forwarderAddresses = "DNS Server role not installed"
            }
            foreach ($result in $results | Where-Object { $_.DomainController -eq $dc.Name }) {
                $result.Forwarders = $forwarderAddresses
            }
        }
    }
    $results | Format-List
}