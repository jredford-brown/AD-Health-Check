function Get-DNSLatency{
    param(
        [string]$Server,
        [string]$Query
    )

    foreach ($forwarder in $Server) {
        foreach ($nsRecord in $forwarder.IPAddress) {
            if ($nsRecord -match '\d+\.\d+\.\d+\.\d+') {
                $totalMilliseconds = 0
                for ($i = 1; $i -le 10; $i++) {
                    $measurement = (Measure-Command {Resolve-DnsName www.bing.com -Server $nsRecord -Type A}).TotalMilliseconds
                    $totalMilliseconds += $measurement
                }
                $averageMilliseconds = $totalMilliseconds / 10
                Write-Output "Average query time for $nsRecord $averageMilliseconds milliseconds" -ForegroundColor Black
            } else {
                $resolvedAddress = (Resolve-DnsName -Name $nsRecord -ErrorAction SilentlyContinue).IPAddress
                if ($resolvedAddress) {
                    $totalMilliseconds = 0
                    for ($i = 1; $i -le 10; $i++) {
                        $measurement = (Measure-Command {Resolve-DnsName www.bing.com -Server $nsRecord -Type A}).TotalMilliseconds
                        $totalMilliseconds += $measurement
                    }
                    $averageMilliseconds = $totalMilliseconds / 10
                    Write-Output "Average query time for $resolvedAddress $averageMilliseconds milliseconds" -ForegroundColor Black
                } else {
                    Write-Output "Failed to resolve DNS forwarder address: $nsRecord" -ForegroundColor Red
                    continue
                }
            }
        }
    }
}