. "${PSScriptRoot}\..\Public\Assert-BaconIsElevated.ps1"
. "${PSScriptRoot}\..\Public\Get-BaconRegistryValueOrDefault.ps1"
# . "${PSScriptRoot}\..\Public\Get-BaconRegistryValueDoNotExpandEnvironmentNames.ps1"

class Bacon {
    [string] $Publisher = $Publisher
    [string] $Product = $Product
    [string] $Version = $Version
    [string] $RunFile = $Action
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
    
    Bacon($Publisher, $Product, $Version, $Action) {
        $this.Publisher = [string] $Publisher
        $this.Product = [string] $Product
        $this.Version = [string] $Version
        $this.RunFile = [string] $Action
        $this.SettingsSetUp()
        $this.SetDefaultSettingsFromRegistry($this.Settings.Registry.Key)
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

        $this.Settings.Log.File = [IO.FileInfo] (Join-Path $private:Directory ('{0} {1} {2} {3}.log' -f $this.Publisher, $this.Product, $this.Version, $this.Action))
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
    hidden [void] SetDefaultSettingsFromRegistrySubKey([hashtable] $Hash, [string] $Key) {
        Get-Item $Key |
            Select-Object -ExpandProperty Property |
            ForEach-Object {
                $Hash.Set_Item($_, (Get-ItemProperty -Path $key -Name $_).$_)
            }
    }

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
}


$bacon = [Bacon]::new('Mozilla', 'Firefox', '1.2.3', 'test')
$bacon
