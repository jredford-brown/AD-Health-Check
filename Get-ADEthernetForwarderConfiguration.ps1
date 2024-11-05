﻿function Get-ADEthernetForwarderConfiguration {
    $forest = Get-ADForest
    $domains = $forest.Domains
    $results = @()
    $ipConfig = Get-NetIPConfiguration -InterfaceAlias $nic.InterfaceAlias

    foreach ($domain in $domains) {
        $dcs = Get-ADDomainController -Filter * -Server $domain

        foreach ($dc in $dcs) {
            $interfaces = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -ComputerName $dc.HostName -Filter "IPEnabled = True"
            foreach ($interface in $interfaces) {
                $result = [PSCustomObject]@{
                    DomainController = $dc.Name
                    IPAddress        = $ipConfig.IPv4Address.IPAddress
                    Domain           = $domain
                    InterfaceIndex   = $interface.InterfaceIndex
                    DNSAddresses     = $interface.DNSServerSearchOrder -join ", "
                    Forwarders       = "N/A" #Placeholder
                }
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