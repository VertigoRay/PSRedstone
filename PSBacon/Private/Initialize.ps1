. "${PSScriptRoot}\..\Public\Assert-BaconIsElevated.ps1"
. "${PSScriptRoot}\..\Public\Get-BaconRegistryValueOrDefault.ps1"
# . "${PSScriptRoot}\..\Public\Get-BaconRegistryValueDoNotExpandEnvironmentNames.ps1"

class Bacon {
    hidden [string] $_Publisher = $null
    hidden [string] $_Product = $null
    hidden [string] $_Version = $null
    hidden [string] $_Action = $null
    [hashtable] $Settings = @{}
    [bool] $IsElevated = (New-Object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    # Use the default settings, don't read any of the settings in from the registry. In production this is never set.
    [bool] $OnlyUseDefaultSettings = $false
    [Management.Automation.InvocationInfo] $MyInvocation = $MyInvocation
    
    # Bacon() {
    # }
    
    # Bacon([Management.Automation.InvocationInfo] $ParentMyInvocation) {
    #     $this.MyInvocation = $ParentMyInvocation
    # }

    static Bacon() {
        # Creating some custom setters that update other properties, like Log Paths, when related properties are changed.
        Update-TypeData -TypeName 'Bacon' -MemberName 'Publisher' -MemberType 'ScriptProperty' -Value {
            # Getter
            return $this._Publisher
        } -SecondValue {
            param($value)
            # Setter
            $this._Publisher = $value
            $this.LogSetUp()
        } -Force
        Update-TypeData -TypeName 'Bacon' -MemberName 'Product' -MemberType 'ScriptProperty' -Value {
            # Getter
            return $this._Product
        } -SecondValue {
            param($value)
            # Setter
            $this._Product = $value
            $this.LogSetUp()
        } -Force
        Update-TypeData -TypeName 'Bacon' -MemberName 'Version' -MemberType 'ScriptProperty' -Value {
            # Getter
            return $this._Version
        } -SecondValue {
            param($value)
            # Setter
            $this._Version = $value
            $this.LogSetUp()
        } -Force
        Update-TypeData -TypeName 'Bacon' -MemberName 'Action' -MemberType 'ScriptProperty' -Value {
            # Getter
            return $this._Action
        } -SecondValue {
            param($value)
            # Setter
            $this._Action = $value
            $this.LogSetUp()
        } -Force
    }
    
    Bacon([string] $Publisher, [string] $Product, [string] $Version, [string] $Action) {
        $global:InformationPreference = 'Continue'
        
        $this.SettingsSetUp()
        $this.SetDefaultSettingsFromRegistry($this.Settings.Registry.Key)
        $this.SetPSDefaultParameterValues($this.Settings.Functions)
        
        $this.set__Publisher($Publisher)
        $this.set__Product($Product)
        $this.set__Version($Version)
        $this.set__Action($Action)

        $this.LogSetUp()
    }

    hidden [void] SettingsSetUp() {
        $this.Settings = @{}
        $this.Settings.Registry = @{
            Key = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\PSBacon'
        }

        $this.Settings.Functions = @{
            'Get-BaconRegistryValueOrDefault' = @{
                OnlyUseDefaultSettings = Get-BaconRegistryValueOrDefault 'Settings\Functions\Get-BaconRegistryValueOrDefault' 'OnlyUseDefaultSettings' $false -RegistryKeyRoot $this.Settings.Registry.Key
                RegistryKeyRoot = $this.Settings.Registry.Key
            }
        }
    }

    hidden [void] LogSetUp() {
        $this.Settings.Log = @{}

        if (Assert-BaconIsElevated) {
            $private:Directory = [IO.DirectoryInfo] "${env:SystemRoot}\Logs\Bacon"
        } else {
            $private:Directory = [IO.DirectoryInfo] "${env:Temp}\Logs\Bacon"
        }

        if (-not $private:Directory.Exists) {
            New-Item -ItemType 'Directory' -Path $private:Directory.FullName -Force | Out-Null
            $private:Directory.Refresh()
        }

        $this.Settings.Log.File = [IO.FileInfo] (Join-Path $private:Directory.FullName ('{0} {1} {2} {3}.log' -f $this.Publisher, $this.Product, $this.Version, $this.Action))
        $this.Settings.Log.FileF = (Join-Path $private:Directory.FullName ('{0} {1} {2} {3}{{0}}.log' -f $this.Publisher, $this.Product, $this.Version, $this.Action)) -as [string]
        
        $global:PSDefaultParameterValues.Set_Item('Write-Log:FilePath', $global:Bacon.Settings.Log.File.FullName)
    }

    hidden [psobject] GetRegOrDefault($RegistryKey, $RegistryValue, $DefaultValue) {
        Write-Verbose "[Bacon GetRegOrDefault] > $($MyInvocation.BoundParameters | ConvertTo-Json -Compress)"
        Write-Debug "[Bacon GetRegOrDefault] Function Invocation: $($MyInvocation | Out-String)"

        if ($this.OnlyUseDefaultSettings) {
            Write-Verbose "[Bacon GetRegOrDefault] OnlyUseDefaultSettings Set; Returning: ${DefaultValue}"
            return $DefaultValue
        }

        try {
            $ret = Get-ItemPropertyValue -Path ('{0}\{1}' -f $this.RegistryKeyRoot, $RegistryKey) -Name $RegistryValue -ErrorAction 'Stop'
            Write-Verbose "[Bacon GetRegOrDefault] Registry Set; Returning: ${ret}"
            return $ret
        } catch [System.Management.Automation.PSArgumentException] {
            Write-Verbose "[Bacon GetRegOrDefault] Registry Not Set; Returning Default: ${DefaultValue}"
            $Error.RemoveAt(0) # This isn't a real error, so I don't want it in the error record.
            return $DefaultValue
        } catch [System.Management.Automation.ItemNotFoundException] {
            Write-Verbose "[Bacon GetRegOrDefault] Registry Not Set; Returning Default: ${DefaultValue}"
            $Error.RemoveAt(0) # This isn't a real error, so I don't want it in the error record.
            return $DefaultValue
        }
    }

    [string] GetRegValueDoNotExpandEnvironmentNames($Key, $Value) {
        $item = Get-Item $Key
        if ($item) {
            return $item.GetValue($Value, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
        } else {
            return $null
        }
    }

    <#
    Dig through the Registry Key and import all the Keys and Values into the $global:Bacon objet.

    There's a fundamental flaw that I haven't addressed yet.
    - if there's a value and sub-key with the same name at the same key level, the sub-key won't be processed.
    #>
    hidden [void] SetDefaultSettingsFromRegistry([string] $Key) {
        $this.SetDefaultSettingsFromRegistrySubKey($this.Settings, $this.Settings.Registry.Key)

        foreach ($item in (Get-ChildItem $this.Settings.Registry.Key -Recurse)) {
            $private:psPath = $item.PSPath.Split(':')[-1].Replace($this.Settings.Registry.Key.Split(':')[-1], $null)
            $private:node = $this.Settings
            foreach ($child in ($private:psPath.Trim('\').Split('\'))) {
                if (-not $node.$child) { 
                    $node.$child = @{}
                }
                $node = $node.$child
            }

            $this.SetDefaultSettingsFromRegistrySubKey($node, $item.PSPath)
        }
    }

    hidden [void] SetDefaultSettingsFromRegistrySubKey([hashtable] $Hash, [string] $Key) {
        foreach ($regValue in (Get-Item $Key).Property) {
            $Hash.Set_Item($regValue, (Get-ItemProperty -Path $Key -Name $regValue).$regValue)
        }
        

    }

    hidden [void] SetPSDefaultParameterValues([hashtable] $FunctionParameters) {
        foreach ($function in $FunctionParameters.GetEnumerator()) {
            Write-Debug ('[Bacon::SetPSDefaultParameterValues] Function: {0}: {1}' -f $function.Name, ($function.Value | ConvertTo-Json))
            foreach ($parameter in $function.GetEnumerator()) {
                Write-Debug ('[Bacon::SetPSDefaultParameterValues] Parameter: {0}: {1}' -f $parameter.Name, ($parameter.Value | ConvertTo-Json))
                $global:PSDefaultParameterValues.Set_Item(('{0}:{1}' -f $function.Name, $parameter.Name), $parameter.Value)
            }
        }
    }
}

$bacon = [Bacon]::new('Mozilla', 'Firefox', '1.2.3', 'test')
$bacon

# Class Sausage:Bacon {
#     Sausage([string] $Publisher, [string] $Product, [string] $Version, [string] $Action):base([string] $Publisher, [string] $Product, [string] $Version, [string] $Action) {
#     }
# }

# $sausage = [Sausage]::new('Mozilla', 'Firefox', '1.2.3', 'test')
# $sausage
