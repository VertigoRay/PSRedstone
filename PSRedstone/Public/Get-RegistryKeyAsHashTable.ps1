
<#
.SYNOPSIS
Get the values in a registry key and all sub-keys.
.DESCRIPTION
Get the values in a registry key and all sub-keys.
This shouldn't be used to pull a massive section of the registry expecting perfect results.

There's a fundamental flaw that I haven't addressed yet.
If there's a value and sub-key with the same name at the same key level, the sub-key won't be processed.
Because of this, use this function to only return key sections with known/expected

#>
function Get-RegistryKeyAsHashTable ([string] $Key, [switch] $Recurse) {
    $private:hash = @{}

    if (Test-Path $Key) {
        $values = (Get-Item $Key).Property
        foreach ($value in (Get-ItemProperty $Key).PSObject.Properties) {
            if ($value.Name -in $values) {
                $private:hash.Add($value.Name, $value.Value)
            }
        }

        if ($Recurse) {
            foreach ($item in (Get-ChildItem $Key -ErrorAction 'Ignore')) {
                if ($private:hash.Keys -notcontains $item.PSChildName) {
                    $private:hash.Add($item.PSChildName, (Get-RegistryKeyAsHashTable -Key $item.PSPath))
                }
            }
        }
    }

    return $private:hash
}