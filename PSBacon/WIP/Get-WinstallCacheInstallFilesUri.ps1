<#
.SYNOPSIS
Queries the Winstall WWW server to get the SHA512 and ZIP URIs.
.DESCRIPTION
Queries the [Winstall WWW](https://git.cas.unt.edu/winstall/WWW) server from the Winstall Settings to get the FileName for the requested Repository and Version.

The FileName is then used to create the Full URIs to the ZIP and the SHA512; which are returned in a `hashtable`.

The project should put this information in the `global:Winstall` variable for easy use without mutliple queries in the same execution.
.PARAMETER UriPath
This is just the path portion of the URI; excluding the protocol and server. Do not include a leading slash.

The protocol and server will be derived from settings:
https://git.cas.unt.edu/winstall/winstall/wikis/Settings#winstall-www
.OUTPUTS
.EXAMPLE
#>
function global:Get-WinstallCacheInstallFilesUri {
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $UriPath
    )

    Write-Information "> $($MyInvocation.BoundParameters | ConvertTo-Json -Compress)"
    Write-Debug "Function Invocation: $($MyInvocation | Out-String)"


    foreach ($server in $global:Winstall.Settings.WinstallWWW.Servers) {
        $Uri = 'https://{0}/{1}' -f $server, $UriPath

        $credCache = New-Object System.Net.CredentialCache
        $credentials = New-Object System.Net.NetworkCredential($global:Winstall.Settings.WinstallWWW.httpauth.username, $global:Winstall.Settings.WinstallWWW.httpauth.password)
        $credCache.Add(('https://{0}' -f $server), 'Basic', $credentials)

        $request = [System.Net.HttpWebRequest]::Create($Uri)
        if ($MaximumAutomaticRedirections) {
            $request.MaximumAutomaticRedirections=1
            $request.AllowAutoRedirect = $true
        }
        $request.PreAuthenticate = $true
        $request.Credentials = $credCache
        try {
            $response = $request.GetResponse()
        } catch {
            continue
        }

        return $response.ResponseUri
    }
}