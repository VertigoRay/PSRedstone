<#
.SYNOPSIS
Download a string from a URL.
.DESCRIPTION
Attempt download, retry if fails up to 60 attempts.
.PARAMETER Uri
Specifies an object which has methods that can be invoked.
.PARAMETER Credentials
Specify credentials, if required:

```powershell
New-Object System.Net.NetworkCredential($username, $password_in_plain_text)
```
.EXAMPLE
# Download the google home page
Invoke-DownlaodString -Uri "https://ipinfo.io/json"
.EXAMPLE
# Download astring that needs Credentials
$creds = New-Object System.Net.NetworkCredential($username, $PASSWORD_IN_PLAIN_TEXT)
Invoke-DownlaodString -Uri "https://ipinfo.io/json" -Credentials $creds
#>
Function Global:Invoke-DownloadString {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, Position = 0)]
		[object]
		$Uri,

		[Parameter(Position = 1)]
		[securestring]
		$Credentials
	)

	Write-Information "> $($MyInvocation.BoundParameters | ConvertTo-Json -Compress)"
    Write-Verbose "Function Invocation: $($MyInvocation | Out-String)"


	$webClient = New-Object System.Net.WebClient

	if ($Credentials)
	{
		$webClient.Credentials = $Credentials
	}

	for ($i=1; $i -le 60; $i++)
	{
		try
		{
			$response = $webClient.DownloadString($Uri)
			return $response
		}
		catch
		{
			if ($i -eq 60)
			{
				Write-Error "Unable to download string: $_"
				break
			}

			Write-Warning $_
			Write-Information "Trying again in ${i} seconds ..."
			Start-Sleep $i
			continue
		}
	}

}
