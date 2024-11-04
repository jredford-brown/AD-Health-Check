function Get-ADTestPorts {
    $currentDomain = (Get-ADDomain).DNSRoot
    $domainDCs = Get-ADDomainController -Filter * -Server $currentDomain | Select-Object -ExpandProperty HostName

    $ports = @(
    53,   # DNS
    88,   # Kerberos
    42,   # WINS
    135,  # RPC (Endpoint Mapper)
    137,  # NetBIOS
    138,  # NetBIOS
    389,  # LDAP
    445,  # SMB
    636,  # LDAPS
    1688,  # KMS
    3268, # Global Catalog LDAP
    3269 # Global Catalog LDAPS
    )

    foreach ($dc in $domainDCs) {
        Write-Host "Testing connectivity to $dc"
        foreach ($port in $ports) {
            $result = Test-NetConnection -ComputerName $dc -Port $port -WarningAction SilentlyContinue
            if ($result.TcpTestSucceeded) {
                Write-Host "Connection to $dc on port $port is successful."
            }
            else {
                Write-Host "Connection to $dc on port $port failed."
            }
        }
        Write-Output ""
    }
}