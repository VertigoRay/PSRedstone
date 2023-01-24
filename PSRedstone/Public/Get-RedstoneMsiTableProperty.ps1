<#
.SYNOPSIS
Get all of the properties from a Windows Installer database table or the Summary Information stream and return as a custom object.
.DESCRIPTION
Use the Windows Installer object to read all of the properties from a Windows Installer database table or the Summary Information stream.
.PARAMETER Path
The fully qualified path to an database file. Supports .msi and .msp files.
.PARAMETER TransformPath
The fully qualified path to a list of MST file(s) which should be applied to the MSI file.
.PARAMETER Table
The name of the the MSI table from which all of the properties must be retrieved. Default is: 'Property'.
.PARAMETER TablePropertyNameColumnNum
Specify the table column number which contains the name of the properties. Default is: 1 for MSIs and 2 for MSPs.
.PARAMETER TablePropertyValueColumnNum
Specify the table column number which contains the value of the properties. Default is: 2 for MSIs and 3 for MSPs.
.PARAMETER GetSummaryInformation
Retrieves the Summary Information for the Windows Installer database.
Summary Information property descriptions: https://msdn.microsoft.com/en-us/library/aa372049(v=vs.85).aspx
.PARAMETER ContinueOnError
Continue if an error is encountered. Default is: $true.
.EXAMPLE
# Retrieve all of the properties from the default 'Property' table.
Get-RedstoneMsiTableProperty -Path 'C:\Package\AppDeploy.msi' -TransformPath 'C:\Package\AppDeploy.mst'
Get-RedstoneMsiTableProperty -Path 'C:\Package\AppDeploy.msi' -TransformPath 'C:\Package\AppDeploy.mst'
.EXAMPLE
# Retrieve all of the properties from the 'Property' table and then pipe to Select-Object to select the ProductCode property.
Get-RedstoneMsiTableProperty -Path 'C:\Package\AppDeploy.msi' -TransformPath 'C:\Package\AppDeploy.mst' -Table 'Property' | Select-Object -ExpandProperty ProductCode
Get-RedstoneMsiTableProperty -Path 'C:\Package\AppDeploy.msi' -TransformPath 'C:\Package\AppDeploy.mst' -Table 'Property' | Select-Object -ExpandProperty ProductCode
.EXAMPLE
# Retrieves the Summary Information for the Windows Installer database.
Get-RedstoneMsiTableProperty -Path 'C:\Package\AppDeploy.msi' -GetSummaryInformation
Get-RedstoneMsiTableProperty -Path 'C:\Package\AppDeploy.msi' -GetSummaryInformation
.NOTES
This is an internal script function and should typically not be called directly.

> Copyright Ⓒ 2015 - PowerShell App Deployment Toolkit Team
>
> Copyright Ⓒ 2023 - Raymond Piller (VertigoRay)
.LINK
https://github.com/VertigoRay/PSRedstone/wiki/Functions#get-redstonemsitableproperty
#>
function Get-RedstoneMsiTableProperty {
	[CmdletBinding(DefaultParameterSetName='TableInfo')]
	Param (
		[Parameter(Mandatory=$true, Position=0)]
		[ValidateScript({ Test-Path -LiteralPath $_ -PathType 'Leaf' })]
		[string]
		$Path
		,
		[Parameter(Mandatory=$false)]
		[ValidateScript({ Test-Path -LiteralPath $_ -PathType 'Leaf' })]
		[string[]]
		$TransformPath
		,
		[Parameter(Mandatory=$false,ParameterSetName='TableInfo')]
		[ValidateNotNullOrEmpty()]
		[string]
		$Table = $(If ([IO.Path]::GetExtension($Path) -eq '.msi') { 'Property' } Else { 'MsiPatchMetadata' })
		,
		[Parameter(Mandatory=$false,ParameterSetName='TableInfo')]
		[ValidateNotNullorEmpty()]
		[int32]
		$TablePropertyNameColumnNum = $(If ([IO.Path]::GetExtension($Path) -eq '.msi') { 1 } Else { 2 })
		,
		[Parameter(Mandatory=$false,ParameterSetName='TableInfo')]
		[ValidateNotNullorEmpty()]
		[int32]
		$TablePropertyValueColumnNum = $(If ([IO.Path]::GetExtension($Path) -eq '.msi') { 2 } Else { 3 })
		,
		[Parameter(Mandatory=$false,ParameterSetName='SummaryInfo')]
		[ValidateNotNullorEmpty()]
		[switch]
		$GetSummaryInformation = $false
		,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[boolean]
		$ContinueOnError = $true
	)

	Begin {
		<#
		.SYNOPSIS
		Get a property from any object.
		.DESCRIPTION
		Get a property from any object.
		.PARAMETER InputObject
		Specifies an object which has properties that can be retrieved.
		.PARAMETER PropertyName
		Specifies the name of a property to retrieve.
		.PARAMETER ArgumentList
		Argument to pass to the property being retrieved.
		.EXAMPLE
		Get-ObjectProperty -InputObject $Record -PropertyName 'StringData' -ArgumentList @(1)
		.NOTES
		This is an internal script function and should typically not be called directly.
		.LINK
		http://psappdeploytoolkit.com
		#>
		function Private:Get-ObjectProperty {
			[CmdletBinding()]
			Param (
				[Parameter(Mandatory=$true,Position=0)]
				[ValidateNotNull()]
				[object]$InputObject,
				[Parameter(Mandatory=$true,Position=1)]
				[ValidateNotNullorEmpty()]
				[string]$PropertyName,
				[Parameter(Mandatory=$false,Position=2)]
				[object[]]$ArgumentList
			)

			Begin { }
			Process {
				## Retrieve property
				Write-Output -InputObject $InputObject.GetType().InvokeMember($PropertyName, [Reflection.BindingFlags]::GetProperty, $null, $InputObject, $ArgumentList, $null, $null, $null)
			}
			End { }
		}
	}



	Process {
		Try {
			If ($PSCmdlet.ParameterSetName -eq 'TableInfo') {
				Write-Information "Read data from Windows Installer database file [${Path}] in table [${Table}]."
			}
			Else {
				Write-Information "Read the Summary Information from the Windows Installer database file [${Path}]."
			}

			## Create a Windows Installer object
			[__comobject]$Installer = New-Object -ComObject 'WindowsInstaller.Installer' -ErrorAction 'Stop'
			## Determine if the database file is a patch (.msp) or not
			If ([IO.Path]::GetExtension($Path) -eq '.msp') { [boolean]$IsMspFile = $true }
			## Define properties for how the MSI database is opened
			[int32]$msiOpenDatabaseModeReadOnly = 0
			[int32]$msiSuppressApplyTransformErrors = 63
			[int32]$msiOpenDatabaseMode = $msiOpenDatabaseModeReadOnly
			[int32]$msiOpenDatabaseModePatchFile = 32
			If ($IsMspFile) { [int32]$msiOpenDatabaseMode = $msiOpenDatabaseModePatchFile }
			## Open database in read only mode
			[__comobject]$Database = Invoke-RedstoneObjectMethod -InputObject $Installer -MethodName 'OpenDatabase' -ArgumentList @($Path, $msiOpenDatabaseMode)
			## Apply a list of transform(s) to the database
			If (($TransformPath) -and (-not $IsMspFile)) {
				ForEach ($Transform in $TransformPath) {
					$null = Invoke-RedstoneObjectMethod -InputObject $Database -MethodName 'ApplyTransform' -ArgumentList @($Transform, $msiSuppressApplyTransformErrors)
				}
			}

			## Get either the requested windows database table information or summary information
			if ($PSCmdlet.ParameterSetName -eq 'TableInfo') {
				## Open the requested table view from the database
				[__comobject]$View = Invoke-RedstoneObjectMethod -InputObject $Database -MethodName 'OpenView' -ArgumentList @("SELECT * FROM ${Table}")
				$null = Invoke-RedstoneObjectMethod -InputObject $View -MethodName 'Execute'

				## Create an empty object to store properties in
				[psobject]$TableProperties = New-Object -TypeName 'PSObject'

				## Retrieve the first row from the requested table. If the first row was successfully retrieved, then save data and loop through the entire table.
				#  https://msdn.microsoft.com/en-us/library/windows/desktop/aa371136(v=vs.85).aspx
				[__comobject]$Record = Invoke-RedstoneObjectMethod -InputObject $View -MethodName 'Fetch'
				While ($Record) {
					#  Read string data from record and add property/value pair to custom object
					$TableProperties | Add-Member -MemberType 'NoteProperty' -Name (Get-ObjectProperty -InputObject $Record -PropertyName 'StringData' -ArgumentList @($TablePropertyNameColumnNum)) -Value (Get-ObjectProperty -InputObject $Record -PropertyName 'StringData' -ArgumentList @($TablePropertyValueColumnNum)) -Force
					#  Retrieve the next row in the table
					[__comobject]$Record = Invoke-RedstoneObjectMethod -InputObject $View -MethodName 'Fetch'
				}
				Write-Output -InputObject $TableProperties
			} else {
				## Get the SummaryInformation from the windows installer database
				[__comobject]$SummaryInformation = Get-ObjectProperty -InputObject $Database -PropertyName 'SummaryInformation'
				[hashtable]$SummaryInfoProperty = @{}
				## Summary property descriptions: https://msdn.microsoft.com/en-us/library/aa372049(v=vs.85).aspx
				$SummaryInfoProperty.Add('CodePage', (Get-ObjectProperty -InputObject $SummaryInformation -PropertyName 'Property' -ArgumentList @(1)))
				$SummaryInfoProperty.Add('Title', (Get-ObjectProperty -InputObject $SummaryInformation -PropertyName 'Property' -ArgumentList @(2)))
				$SummaryInfoProperty.Add('Subject', (Get-ObjectProperty -InputObject $SummaryInformation -PropertyName 'Property' -ArgumentList @(3)))
				$SummaryInfoProperty.Add('Author', (Get-ObjectProperty -InputObject $SummaryInformation -PropertyName 'Property' -ArgumentList @(4)))
				$SummaryInfoProperty.Add('Keywords', (Get-ObjectProperty -InputObject $SummaryInformation -PropertyName 'Property' -ArgumentList @(5)))
				$SummaryInfoProperty.Add('Comments', (Get-ObjectProperty -InputObject $SummaryInformation -PropertyName 'Property' -ArgumentList @(6)))
				$SummaryInfoProperty.Add('Template', (Get-ObjectProperty -InputObject $SummaryInformation -PropertyName 'Property' -ArgumentList @(7)))
				$SummaryInfoProperty.Add('LastSavedBy', (Get-ObjectProperty -InputObject $SummaryInformation -PropertyName 'Property' -ArgumentList @(8)))
				$SummaryInfoProperty.Add('RevisionNumber', (Get-ObjectProperty -InputObject $SummaryInformation -PropertyName 'Property' -ArgumentList @(9)))
				$SummaryInfoProperty.Add('LastPrinted', (Get-ObjectProperty -InputObject $SummaryInformation -PropertyName 'Property' -ArgumentList @(11)))
				$SummaryInfoProperty.Add('CreateTimeDate', (Get-ObjectProperty -InputObject $SummaryInformation -PropertyName 'Property' -ArgumentList @(12)))
				$SummaryInfoProperty.Add('LastSaveTimeDate', (Get-ObjectProperty -InputObject $SummaryInformation -PropertyName 'Property' -ArgumentList @(13)))
				$SummaryInfoProperty.Add('PageCount', (Get-ObjectProperty -InputObject $SummaryInformation -PropertyName 'Property' -ArgumentList @(14)))
				$SummaryInfoProperty.Add('WordCount', (Get-ObjectProperty -InputObject $SummaryInformation -PropertyName 'Property' -ArgumentList @(15)))
				$SummaryInfoProperty.Add('CharacterCount', (Get-ObjectProperty -InputObject $SummaryInformation -PropertyName 'Property' -ArgumentList @(16)))
				$SummaryInfoProperty.Add('CreatingApplication', (Get-ObjectProperty -InputObject $SummaryInformation -PropertyName 'Property' -ArgumentList @(18)))
				$SummaryInfoProperty.Add('Security', (Get-ObjectProperty -InputObject $SummaryInformation -PropertyName 'Property' -ArgumentList @(19)))
				[psobject]$SummaryInfoProperties = New-Object -TypeName 'PSObject' -Property $SummaryInfoProperty
				Write-Output -InputObject $SummaryInfoProperties
			}
		}
		Catch {
            $resolvedError = if (Get-Command 'Resolve-Error' -ErrorAction 'Ignore') { Resolve-Error } else { $null }
			Write-Error ('Failed to get the MSI table [{0}]. {1}' -f $Table, $resolvedError)
			If (-not $ContinueOnError) {
				Throw ('Failed to get the MSI table [{0}]. {1}' -f $Table, $_.Exception.Message)
			}
		}
		Finally {
			Try {
				If ($View) {
					$null = Invoke-RedstoneObjectMethod -InputObject $View -MethodName 'Close' -ArgumentList @()
					Try { $null = [Runtime.Interopservices.Marshal]::ReleaseComObject($View) } Catch { }
				}
				ElseIf($SummaryInformation) {
					Try { $null = [Runtime.Interopservices.Marshal]::ReleaseComObject($SummaryInformation) } Catch { }
				}
			}
			Catch { }
			Try { $null = [Runtime.Interopservices.Marshal]::ReleaseComObject($DataBase) } Catch { }
			Try { $null = [Runtime.Interopservices.Marshal]::ReleaseComObject($Installer) } Catch { }
		}
	}

	End {}
}