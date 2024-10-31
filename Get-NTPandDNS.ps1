﻿function Get-NTPandDNS {
    $ntpSettings = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters"
    $ntpServer = $ntpSettings.NtpServer
    $type = $ntpSettings.Type

    Write-Host "==============================="
    Write-Output "NTP Configuration"
    Write-Output "NTP Server: $ntpServer"
    Write-Output "Type: $type"
    Write-Host "==============================="
    Write-Output ""
    Write-Host "==============================="
    Write-Output "Network Adapter Configuration"
    Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | ForEach-Object {
        $nic = $_
        $ipConfig = Get-NetIPConfiguration -InterfaceAlias $nic.InterfaceAlias
        $dnsServers = $ipConfig.DnsServer.ServerAddresses
        Write-Output "Interface Name: $($nic.Name)"
        Write-Output "IP Address: $($ipConfig.IPv4Address.IPAddress)"
        if ($dnsServers.Count -gt 0) {
            Write-Output "DNS Servers:"
            $dnsServers | ForEach-Object { Write-Output "  $_" }
        } else {
            Write-Output "DNS Servers: N/A"
        }
        Write-Host "==============================="
        Write-Output ""
    }
}