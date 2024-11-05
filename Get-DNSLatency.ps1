function Get-DNSLatency{
    param(
        [string]$query
    )

    $forwarders = Get-DnsServerForwarder

    foreach ($forwarder in $forwarders) {
        foreach ($nsRecord in $forwarder.IPAddress) {
            if ($nsRecord -match '\d+\.\d+\.\d+\.\d+') {
                $totalMilliseconds = 0
                for ($i = 1; $i -le 10; $i++) {
                    $measurement = (Measure-Command {Resolve-DnsName $query -Server $nsRecord -Type A}).TotalMilliseconds
                    $totalMilliseconds += $measurement
                }
                $averageMilliseconds = $totalMilliseconds / 10
                Write-Output "Average query time for $nsRecord $($averageMilliseconds)ms"
            } else {
                $resolvedAddress = (Resolve-DnsName -Name $nsRecord -ErrorAction SilentlyContinue).IPAddress
                if ($resolvedAddress) {
                    $totalMilliseconds = 0
                    for ($i = 1; $i -le 10; $i++) {
                        $measurement = (Measure-Command {Resolve-DnsName $query -Server $nsRecord -Type A}).TotalMilliseconds
                        $totalMilliseconds += $measurement
                    }
                    $averageMilliseconds = $totalMilliseconds / 10
                    Write-Output "Average query time for $resolvedAddress $($averageMilliseconds)ms"
                } else {
                    Write-Output "Failed to resolve DNS forwarder address: $nsRecord"
                    continue
                }
            }
        }
    }
}