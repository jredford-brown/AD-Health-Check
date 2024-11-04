function Test-Port {
    param (
        [string]$localhost,
        [int]$port
    )

    try {
        $connection = New-Object System.Net.Sockets.TcpClient([string]$localhost, $port)
        $connection.Close()
        return $true
    } catch {
        return $false
    }
}

function Get-LdapsCertificate {
    param (
        [string]$domain,
        [int]$port
    )

    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient($domain, $port)
        $sslStream = New-Object System.Net.Security.SslStream($tcpClient.GetStream(), $false)
        $sslStream.AuthenticateAsClient($domain)
        $cert = $sslStream.RemoteCertificate

        $certInfo = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 $cert
        $expiryDate = $certInfo.NotAfter
        $subject = $certInfo.Subject

        Write-Output "LDAPS certificate for $domain expires on $expiryDate"
        Write-Output "Certificate Subject: $subject"

        $sslStream.Close()
        $tcpClient.Close()

    } catch {
        Write-Output "Error retrieving LDAPS certificate: $_.ScriptStackTrace"
    }
}

function Get-ADLDAPConfiguration {
    param (
        [string]$domain
    )

    if (Test-Port -Host $domain -Port 389) {
        Write-Output "LDAP connection successful on port 389."
    } else {
        Write-Output "LDAP connection failed on port 389."
    }

    if (Test-Port -Host $domain -Port 636) {
        Write-Output "LDAPS connection successful on port 636."
        Get-LdapsCertificate -Domain $domain -Port 636
    } else {
        Write-Output "LDAPS connection failed on port 636."
    }
}