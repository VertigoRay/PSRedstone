<#
.SYNOPSIS
Create a WebClient object for use with the Winstall WWW.
.DESCRIPTION
Creates and returns a `System.Net.WebClient` object for use with the *Winstall WWW*.

When determining what server to use, it will try to contact all of the servers supplied and will use the first available.

Can also be used with [PrivateFiles](https://git.cas.unt.edu/winstall/winstall/wikis/PrivateFiles); see examples.
.PARAMETER CacheServer
Default: `$global:Winstall.Cache.Server`

This is the server to be used; such as: `winstall.cas.unt.edu`.
.PARAMETER Servers
Default: `$global:Winstall.Settings.Functions.GetWinstallWWWWebClient.Servers`
.PARAMETER URLS
Default: `$global:Winstall.Settings.Functions.GetWinstallWWWWebClient.URLS`
.PARAMETER Usernames
Default: `$global:Winstall.Settings.Functions.GetWinstallWWWWebClient.Usernames`
.PARAMETER Passwords
Default: `$global:Winstall.Settings.Functions.GetWinstallWWWWebClient.Passwords`
.PARAMETER TestUriPath
Default: `$global:Winstall.Settings.Functions.GetWinstallWWWWebClient.TestUriPath`
.OUTPUTS
[hashtable]
@{
    'CacheServer' = [string]$CacheServer;
    'WebClient' = [System.Net.WebClient]$WebClient;
}
.EXAMPLE
> $result = Get-WinstallWWWWebClient
> $result.CacheServer
winstall.cas.unt.edu
> $result.WebClient

AllowReadStreamBuffering  : False
AllowWriteStreamBuffering : False
Encoding                  : System.Text.SBCSCodePageEncoding
BaseAddress               :
Credentials               : System.Net.NetworkCredential
UseDefaultCredentials     : False
Headers                   : {}
QueryString               : {}
ResponseHeaders           :
Proxy                     : System.Net.WebRequest+WebProxyWrapper
CachePolicy               :
IsBusy                    : False
Site                      :
Container                 :
.EXAMPLE
# Use with [PrivateFiles](https://git.cas.unt.edu/winstall/winstall/wikis/PrivateFiles):
> $get_winstallwwwwebclient = @{
    'CacheServer' = '';
    'Servers' =    $global:Winstall.Settings.PrivateFiles.Servers;
    'URLs' =       $global:Winstall.Settings.PrivateFiles.URLs;
    'Usernames' =  $global:Winstall.Settings.PrivateFiles.HTTPAuth_Usernames;
    'Passwords' =  $global:Winstall.Settings.PrivateFiles.HTTPAuth_Passwords;
}
$result = Get-WinstallWWWWebClient @get_winstallwwwwebclient
#>
function global:Get-WinstallWWWWebClient {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false, Position=0, HelpMessage="Private Parameter; used for debug overrides.")]
        [string]
        $CacheServer = $global:Winstall.Cache.Server
        ,
        [Parameter(Mandatory=$false, HelpMessage="Private Parameter; used for debug overrides.")]
        [string[]]
        $Servers = $global:Winstall.Settings.Functions.GetWinstallWWWWebClient.Servers
        ,
        [Parameter(Mandatory=$false, HelpMessage="Private Parameter; used for debug overrides.")]
        [string[]]
        $URLs = $global:Winstall.Settings.Functions.GetWinstallWWWWebClient.URLs
        ,
        [Parameter(Mandatory=$false, HelpMessage="Private Parameter; used for debug overrides.")]
        [string[]]
        $Usernames = $global:Winstall.Settings.Functions.GetWinstallWWWWebClient.Usernames
        ,
        [Parameter(Mandatory=$false, HelpMessage="Private Parameter; used for debug overrides.")]
        [string[]]
        $Passwords = $global:Winstall.Settings.Functions.GetWinstallWWWWebClient.Passwords
        ,
        [Parameter(Mandatory=$false, Position=0, HelpMessage="Private Parameter; used for debug overrides.")]
        [string[]]
        $TestUriPath = $global:Winstall.Settings.Functions.GetWinstallWWWWebClient.TestUriPath
    )

    Write-Information "> $($MyInvocation.BoundParameters | ConvertTo-Json -Compress)"
    Write-Verbose "Function Invocation: $($MyInvocation | Out-String)"

    $private:PrevErrorActionPreference

    if (-not $CacheServer) {
        Write-Debug "Cache Server not already determined ..."
        foreach ($server in $Servers) {
            $CacheServer = $server
            Write-Debug "Trying CacheServer: ${CacheServer}"

            $server_index = ($Servers).IndexOf($CacheServer)
            Write-Debug "Server Index: ${server_index}"

            $u = $Usernames[$server_index]
            Write-Debug "HTTPAuth.Username: ${u}"
            $p = $Passwords[$server_index]
            Write-Debug "HTTPAuth.Password: ${p}"

            $webclient = New-Object System.Net.WebClient
            Write-Debug "System.Net.WebClient: $($webclient | Out-String)"
            $webclient.Credentials = New-Object System.Net.NetworkCredential($u, $p)
            Write-Debug "System.Net.NetworkCredential: $($webclient.Credentials | Out-String)"

            $url = $URLs[$server_index] -f @($CacheServer, $TestUriPath[$server_index])
            Write-Information "URL: ${url}"

            try {
                $webclient.DownloadString($url)
                break
            } catch {
                Write-Error "Cache Server (${CacheServer}): ${_}"
                continue
            }
        }
    } else {
        $server_index = ($Servers).IndexOf($CacheServer)
        Write-Debug "Server Index: ${server_index}"

        $u = $Usernames[$server_index]
        Write-Debug "HTTPAuth.Username: ${u}"
        $p = $Passwords[$server_index]
        Write-Debug "HTTPAuth.Password: ${p}"

        $webclient = New-Object System.Net.WebClient
        Write-Debug "System.Net.WebClient: $($webclient | Out-String)"
        $webclient.Credentials = New-Object System.Net.NetworkCredential($u, $p)
        Write-Debug "System.Net.NetworkCredential: $($webclient.Credentials | Out-String)"

        $return = $webclient
    }

    $return = @{
        'CacheServer' = $CacheServer;
        'WebClient' = $webclient;
    }

    Write-Information "Return: $($return | ConvertTo-Json -Depth 1 -Compress)"
    return $return
}