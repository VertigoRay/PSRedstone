<#
.SYNOPSIS
Gets the version of the specified file
.DESCRIPTION
Gets the version of the specified file
.PARAMETER File
Path of the file
.PARAMETER ContinueOnError
Continue if an error is encountered
.EXAMPLE
Get-FileVersion -File "$envProgramFilesX86\Adobe\Reader 11.0\Reader\AcroRd32.exe"
.NOTES
Taken from PSAppDeploy Toolkit: http://psappdeploytoolkit.codeplex.com
.LINK
#>
Function global:Get-FileVersion {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]
		$File
		,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[boolean]
		$ContinueOnError = $true
	)

	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
			Write-Log -Message "Get file version info for file [$file]" -Source ${CmdletName}

			If (Test-Path -Path $File -PathType Leaf) {
				$fileVersion = (Get-Command -Name $file -ErrorAction 'Stop').FileVersionInfo.FileVersion
				If ($fileVersion) {
					## Remove product information to leave only the file version
					$fileVersion = ($fileVersion -split ' ' | Select-Object -First 1)

					Write-Log -Message "File version is [$fileVersion]" -Source ${CmdletName}
					Write-Output $fileVersion
				}
				Else {
					Write-Log -Message 'No file version information found.' -Source ${CmdletName}
				}
			}
			Else {
				Throw "File path [$file] does not exist."
			}
		}
		Catch {
			Write-Log -Message "Failed to get file version info. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			If (-not $ContinueOnError) {
				Throw "Failed to get file version info: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}