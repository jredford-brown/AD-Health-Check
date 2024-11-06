$scriptDir = Split-Path -parent $MyInvocation.MyCommand.Path
try {
    Import-Module $scriptDir\Get-ADTestPorts.ps1
    Import-Module $scriptDir\Get-ADEthernetForwarderConfiguration.ps1
    Import-Module $scriptDir\Get-ADLDAPConfiguration.ps1
    Import-Module $scriptDir\Get-NTP.ps1
    Import-Module $scriptDir\Get-DNSLatency.ps1
    Import-Module $scriptDir\Get-SitesServices.ps1
    Import-Module ActiveDirectory
}
catch {
    throw "A fatal exception has occured while importing modules. $_.ScriptStackTrace"
}

try {
    $query = "www.bing.com"
    $sitesAndHosts = Get-ADDomainController -Filter *
    $hostName = [System.Net.Dns]::GetHostEntry($env:computerName).HostName
    $transcriptPath = "$scriptDir\Active Directory Health Check - $(Get-Date -Format "ddMMyy.HHmm").txt"
}
catch {
    Write-Warning "An error occured during variable data collection. $_.ScriptStackTrace"
}

Start-Transcript -Path $transcriptPath -NoClobber

try {
    Write-Host "=== System Information ==="
    Get-ADEthernetForwarderConfiguration
    Get-NTP
    Write-Output ""
}
catch {
    Write-Warning "An error occured while building system info. $_.ScriptStackTrace"
}

try {
    $dcdiagTests = @(
        [PSCustomObject]@{ Command = "dcdiag /test:dns /a"; Heading = "=== DNS Test ===" }
        [PSCustomObject]@{ Command = "dcdiag /test:machineaccount /a"; Heading = "=== Machine Account Test ===" }
        [PSCustomObject]@{ Command = "dcdiag /test:services /a"; Heading = "=== Services Test ===" }
        [PSCustomObject]@{ Command = "dcdiag /test:netlogons /a"; Heading = "=== Netlogons Test ===" }
        [PSCustomObject]@{ Command = "dcdiag /test:replications /a"; Heading = "=== Replications Test ===" }
        [PSCustomObject]@{ Command = "dcdiag /test:fsmocheck /a"; Heading = "=== FSMO Check Test ===" }
        [PSCustomObject]@{ Command = "dcdiag /test:advertising /a"; Heading = "=== Self Advertising Test ===" }
        [PSCustomObject]@{ Command = "dcdiag /test:CheckSDRefDom /a"; Heading = "=== Security Descriptor Test ===" }
        [PSCustomObject]@{ Command = "dcdiag /test:CheckSecurityError /a"; Heading = "=== Security Test ===" }
        [PSCustomObject]@{ Command = "dcdiag /test:Connectivity /a"; Heading = "=== DSA Test ===" }
        [PSCustomObject]@{ Command = "dcdiag /test:cutoffservers /a"; Heading = "=== Isolated DC Test ===" }
    )
    
    foreach ($test in $dcdiagTests) {
        $output = Invoke-Expression -Command $test.Command
        Write-Host "$($test.Heading)"
        $outputLines = $output -split "`n"
        foreach ($line in $outputLines) {
            if (![string]::IsNullOrWhiteSpace($line)) {
                Write-Output "$line"
            }
        }
        Write-Output ""
    }
}
catch {
    Write-Warning "An error occured while performing domain health checks. $_.ScriptStackTrace"
}

try {
    Write-Host "=== NS Validity ==="
    $dnsZones = Get-DnsServerZone | Where-Object { $_.ZoneType -eq "Primary" } | Select-Object -ExpandProperty ZoneName
    foreach ($zone in $dnsZones) {
        $nsRecords = (Resolve-DnsName -Type NS -Name $zone -ErrorAction SilentlyContinue).NameHost
        if ($nsRecords) {
            foreach ($nsRecord in $nsRecords) {
                if (-not (Test-NetConnection -ComputerName $nsRecord -Port 389 -InformationLevel Quiet)) {
                    Write-Host "NS record '$nsRecord' in zone '$zone'. Cannot be reached, it might be a stale entry or the machine is unreachable."
                }
                if (Test-NetConnection -ComputerName $nsRecord -Port 389 -InformationLevel Quiet) {
                    Write-Host "NS record '$nsRecord' in zone '$zone'. OK."
                }
            }
        } else {
            Write-Host "No NS records found for zone '$zone'."
        }
    }
    Write-Output ""
}
catch {
    Write-Warning "An error occured while checking Name Server records. $_.ScriptStackTrace"
}

try {
    Write-Host "=== Forwarder Response Time ==="
    Get-DNSLatency($query)
    Write-Output ""
}
catch {
    Write-Warning "An error occured while checking forwarder latency. $_.ScriptStackTrace"
}

try {
    Write-Host "=== Test Connectivity ==="
    Get-ADTestPorts
    Write-Output ""
}
catch {
    Write-Warning "An error occured while checking port connectivity. $_.ScriptStackTrace"
}

try {
    Write-Host "=== Replication Status ==="
    Get-SitesServices($sitesAndHosts)
    Write-Output ""
}
catch {
    Write-Warning "An error occured while collecting replication status. $_.ScriptStackTrace"
}

try {
    Write-Host "=== LDAP Configuration ==="
    Get-ADLDAPConfiguration($hostName)
}
catch {
    Write-Warning "An error occured while collecting LDAP configuration. $_.ScriptStackTrace"
}

Stop-Transcript

<#
Ah you've stumbled upon my afterthoughts

Key Points
Nothing in this script changes anything or takes anything down, safe to run on live
If theres many misconfigurations in DNS it may take some time to run, also if you have many entries to resolve, sorry if this scares you
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