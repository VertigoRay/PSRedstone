<#
.SYNOPSIS
Download a file from a URL.
.DESCRIPTION
Attempt download, retry if fails up to 60 attempts.
.PARAMETER Uri
A complete URL to the file to be downloaded
.PARAMETER OutFile
The complete filepath and filename where the file should be saved.
.PARAMETER Credentials
Specify credentials, if required:

```powershell
New-Object System.Net.NetworkCredential($username, $password_in_plain_text)
```
.EXAMPLE
# Download an image
Invoke-DownloadFile -Uri "http://i.imgur.com/ISostpv.jpg" -OutFile "c:\temp\file.jpg"
Pass credentials, or dont.
.EXAMPLE
# Download an image that needs Credentials
$creds = New-Object System.Net.NetworkCredential($username, $password_in_plain_text)
Invoke-DownloadFile -Uri "http://i.imgur.com/ISostpv.jpg" -OutFile "c:\temp\file.jpg" -Credentials $creds
#>
Function Global:Invoke-DownloadFile {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, Position = 0)]
		[string]
		$Uri,
		
		[Parameter(Mandatory = $true, Position = 1)]
		[string]
		$OutFile,

		[Parameter(Position = 2)]
		[SecureString]
		$Credentials
	)

	Write-Information "> $($MyInvocation.BoundParameters | ConvertTo-Json -Compress)"
    Write-Verbose "Function Invocation: $($MyInvocation | Out-String)"


	if (-not (Split-Path $OutFile -Parent)) {
		Write-Warning "The supplied OutFile does not appear to be a complete path. We'll let this play out, but it's very likely your file just got saved to the ``System32`` folder."
	}

	$webClient = New-Object System.Net.WebClient
	
	if ($Credentials) {
		$webClient.Credentials = $Credentials
	}

	for ($i=1; $i -le 60; $i++){
		try {
			$webClient.DownloadFile($Uri, $OutFile)
			break
		} catch {
			if ($i -eq 60) {
				Write-Error "Unable to download file: $_"
				break
			}

			Write-Warning $_
			Write-Information "Trying again in ${i} seconds ..."
			Start-Sleep $i
			continue
		}
	}
}
