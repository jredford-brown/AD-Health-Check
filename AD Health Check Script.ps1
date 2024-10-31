$scriptDir = Split-Path -parent $MyInvocation.MyCommand.Path

Import-Module $scriptDir\Get-ADTestPorts.ps1
Import-Module $scriptDir\Get-ADEthernetForwarderConfiguration.ps1
Import-Module $scriptDir\Get-ADLDAPConfiguration.ps1
Import-Module $scriptDir\Get-NTPandDNS.ps1
Import-Module $scriptDir\Get-DNSLatency.ps1
Import-Module $scriptDir\Get-SitesServices.ps1
Import-Module $scriptDir\Set-HealthCheckResults.ps1
Import-Module ActiveDirectory

$forwarders = Get-DnsServerForwarder
$query = "www.bing.com"
$sitesAndHosts = Get-ADDomainController -Filter *
$domain = (Get-ADDomain).DNSRoot
$transcriptPath = "${env}TTech AD Health Check - $(Get-Date -Format "ddMMyy.HHmm").txt"
Start-Transcript -Path $transcriptPath -NoClobber

Write-Host "==============================="
Write-Host "Server Configuration:"
Get-ADEthernetForwarderConfiguration
Get-NTPandDNS
Write-Host "==============================="
Write-Output ""

# Define an array of dcdiag tests
$dcdiagTests = @(
    [PSCustomObject]@{ Command = "dcdiag /a /test:dns"; Heading = "DNS Test" }
    [PSCustomObject]@{ Command = "dcdiag /a /test:machineaccount"; Heading = "Machine Account Test" }
    [PSCustomObject]@{ Command = "dcdiag /a /test:services"; Heading = "Services Test" }
    [PSCustomObject]@{ Command = "dcdiag /a /test:netlogons"; Heading = "Netlogons Test" }
    [PSCustomObject]@{ Command = "dcdiag /a /test:replications"; Heading = "Replications Test" }
    [PSCustomObject]@{ Command = "dcdiag /a /test:fsmocheck"; Heading = "FSMO Check Test" }
)

foreach ($test in $dcdiagTests) {
    $output = dcdiag /a $test.Command | Select-String -Pattern 'DC:|failed' -Context 1
    if ($output) {
        Write-Host "==============================="
        Write-Host "$($test.Heading):"
        Write-Host "==============================="
        Write-Output ""
        $output | Out-File -FilePath $fileVar -Append
    } else {
        Write-Host "==============================="
        Write-Host "$($test.Heading): No issues to report."
        Write-Host "==============================="
        Write-Output ""
    }
}
Write-Output ""

Write-Host "==============================="
Write-Host "NS Records:"
$dnsZones = Get-DnsServerZone | Where-Object { $_.ZoneType -eq "Primary" } | Select-Object -ExpandProperty ZoneName
foreach ($zone in $dnsZones) {
    $nsRecords = (Resolve-DnsName -Type NS -Name $zone -ErrorAction SilentlyContinue).NameHost
    if ($nsRecords) {
        foreach ($nsRecord in $nsRecords) {
            if (-not (Test-NetConnection -ComputerName $nsRecord -Port 389 -InformationLevel Quiet)) {
                Write-Host "NS record '$nsRecord' in zone '$zone' cannot be reached. It might be a stale entry or the machine is unreachable."
            }
            if (Test-NetConnection -ComputerName $nsRecord -Port 389 -InformationLevel Quiet) {
                Write-Host "NS record '$nsRecord' in zone '$zone' can be reached."
            }
        }
    } else {
        Write-Host "No NS records found for zone '$zone'."
    }
}
Write-Host "==============================="
Write-Output ""

Write-Host "==============================="
Write-Host "Forwarder Response Time:"
Get-DNSLatency($forwarders, $query)
Write-Host "==============================="
Write-Output ""

Write-Host "==============================="
Write-Host "Test Port Access:"
Get-ADTestPorts
Write-Host "==============================="
Write-Output ""

Write-Host "==============================="
Write-Host "Replication Status:"
Get-SitesServices($sitesAndHosts)
Write-Host "==============================="
Write-Output ""

Write-Host "==============================="
Write-Host "LDAP Configuration:"
Get-ADLDAPConfiguration($domain)
Write-Host "==============================="

Stop-Transcript

<#
Ah you've stumbled upon my afterthoughts

Key Points
Nothing in this script changes anything or takes anything down, safe to run on live
If theres many misconfigurations in DNS it may take some time to run, sorry if this scares you
There is a readme in the directory to parse some of the information you're reading if you're not sure
You may see data duplication, this is not on purpose, im just stupid
Please don't think less of me for the below

# -----------------------------------------------
# Intellectual Property Notice
#
# This script and its associated files are the
# intellectual property of Jamie Redford-Brown.
# All rights reserved.
# You are permitted to use this script and its
# associated files but not the alteration of files or to claim as your own.
# -----------------------------------------------
#>


#$forwarders = Get-DnsServerForwarder
#foreach ($forwarder in $forwarders) {
#    foreach ($nsRecord in $forwarder.IPAddress) {
#        if ($nsRecord -match '\d+\.\d+\.\d+\.\d+') {
#            $totalMilliseconds = 0
#            for ($i = 1; $i -le 10; $i++) {
#                $measurement = (Measure-Command {Resolve-DnsName www.bing.com -Server $nsRecord -Type A}).TotalMilliseconds
#                $totalMilliseconds += $measurement
#            }
#            $averageMilliseconds = $totalMilliseconds / 10
#            Write-Output "Average query time for $nsRecord $averageMilliseconds milliseconds" -ForegroundColor Black
#        } else {
#            $resolvedAddress = (Resolve-DnsName -Name $nsRecord -ErrorAction SilentlyContinue).IPAddress
#            if ($resolvedAddress) {
#                $totalMilliseconds = 0
#                for ($i = 1; $i -le 10; $i++) {
#                    $measurement = (Measure-Command {Resolve-DnsName www.bing.com -Server $nsRecord -Type A}).TotalMilliseconds
#                    $totalMilliseconds += $measurement
#                }
#                $averageMilliseconds = $totalMilliseconds / 10
#                Write-Output "Average query time for $resolvedAddress $averageMilliseconds milliseconds" -ForegroundColor Black
#            } else {
#                Write-Warning "Failed to resolve DNS forwarder address: $nsRecord" | Out-File -FilePath $fileVar -Append
#                continue
#            }
#        }
#    }
#}

#Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters" | Select-Object NtpServer | Out-File -FilePath $fileVar -Append
#Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters" | Select-Object Type | Out-File -FilePath $fileVar -Append
#Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | ForEach-Object {
#    $nic = $_
#    $ipConfig = Get-NetIPConfiguration -InterfaceAlias $nic.InterfaceAlias
#    $dnsServers = $ipConfig.DnsServer.ServerAddresses
#
#    [PSCustomObject]@{
#        "Interface Name" = $nic.Name
#        "IP Address" = ($ipConfig.IPv4Address | Select-Object -First 1).IPAddress
#        "Primary DNS" = if ($dnsServers.Count -gt 0) { $dnsServers[1] } else { "N/A" }
#        "Secondary DNS" = if ($dnsServers.Count -gt 1) { $dnsServers[2] } else { "N/A" }
#    }
#} | Out-File -FilePath $fileVar -Append

#function Measure-DNSQueryTime {
#    param(
#        [string]$Server
#    )
#
#    $results = @()
#    for ($i = 1; $i -le 5; $i++) {n
#        $startTime = Get-Date
#        $result = Resolve-DnsName -Name $query -Server $Server
#        $endTime = Get-Date
#        $queryTime = ($endTime - $startTime).TotalMilliseconds
#        $results += $queryTime
#        Write-Output "Query $i to $Server took $queryTime milliseconds"
#    }
#    return $results
#}
