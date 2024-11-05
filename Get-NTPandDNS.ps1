function Get-NTPandDNS {
    $ntpSettings = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters"
    $ntpServer = $ntpSettings.NtpServer
    $type = $ntpSettings.Type

    Write-Host "=== NTP Configuration ==="
    Write-Output "NTP Server: $ntpServer"
    Write-Output "Type: $type"
    Write-Output ""

    Write-Host "=== Network Adapter Configuration ==="
    Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | ForEach-Object {
        $nic = $_
        $dnsServers = $ipConfig.DnsServer.ServerAddresses
        Write-Output "Interface Name: $($nic.Name)"
        if ($dnsServers.Count -gt 0) {
            Write-Output "DNS Servers:"
            $dnsServers | ForEach-Object { Write-Output "  $_" }
        } else {
            Write-Output "DNS Servers: N/A"
        }
        Write-Output ""
    }
}