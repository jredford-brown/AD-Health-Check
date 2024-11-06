function Get-NTP {
    $ntpSettings = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters"
    $ntpServer = $ntpSettings.NtpServer
    $type = $ntpSettings.Type
    

    Write-Host "=== NTP Configuration ==="
    Write-Output "NTP Server: $ntpServer"
    Write-Output "Type: $type"
    Write-Output ""
}