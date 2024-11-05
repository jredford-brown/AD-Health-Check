function Get-ADEthernetForwarderConfiguration {
    $forest = Get-ADForest
    $domains = $forest.Domains
    $results = @()

    foreach ($domain in $domains) {
        $dcs = Get-ADDomainController -Filter * -Server $domain
        foreach ($dc in $dcs) {
            $interfaces = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -ComputerName $dc.HostName -Filter "IPEnabled = True"
            foreach ($interface in $interfaces) {
                try {
                    $result = [PSCustomObject]@{
                        DomainController = $dc.Name
                        IPAddress        = $interface.IPAddress
                        Domain           = $domain
                        InterfaceIndex   = $interface.InterfaceIndex
                        DNSAddresses     = $interface.DNSServerSearchOrder -join ", "
                        Forwarders       = "N/A" #Placeholder
                    }
                } catch {continue}
                $results += $result
            }
            try {
                $forwarders = Get-DnsServerForwarder -ComputerName $dc.HostName -ErrorAction Stop
                $forwarderAddresses = $forwarders.IPAddress -join ", "
            } catch {
                $forwarderAddresses = "DNS Server role not installed"
            }
            foreach ($res in $results | Where-Object { $_.DomainController -eq $dc.Name }) {
                $res.Forwarders = $forwarderAddresses
            }
        }
    }
    $results | Format-List
}