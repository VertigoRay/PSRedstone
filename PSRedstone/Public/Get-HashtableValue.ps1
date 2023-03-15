<#
.SYNOPSIS
This function is purely designed to make things easier when getting a value from a hashtable using a path in string form.
.DESCRIPTION
This function is purely designed to make things easier when getting a value from a hashtable using a path in string form.
It has the added benefit of returning a provided default value if the path doesn't exist.
.EXAMPLE
Get-HashtableValue -Hashtable $vars -Path 'Thing2.This2.That1' -Default 'nope'

Returns `221` from the following `$vars` hashtable:

```powershell
$vars = @{
    Thing1 = 1
    Thing2 = @{
        This1 = 21
        This2 = @{
            That1 = 221
            That2 = 222
            That3 = 223
            That4 = $null
        }
        This3 = 23
    }
    Thing3 = 3
}
```
.EXAMPLE
Get-HashtableValue -Hashtable $vars -Path 'Thing2.This2.That4' -Default 'nope'

Returns `$null` from the following `$vars` hashtable:

```powershell
$vars = @{
    Thing1 = 1
    Thing2 = @{
        This1 = 21
        This2 = @{
            That1 = 221
            That2 = 222
            That3 = 223
            That4 = $null
        }
        This3 = 23
    }
    Thing3 = 3
}
```
.EXAMPLE
Get-HashtableValue -Hashtable $vars -Path 'Thing2.This4' -Default 'nope'

Returns `"nope"` from the following `$vars` hashtable:

```powershell
$vars = @{
    Thing1 = 1
    Thing2 = @{
        This1 = 21
        This2 = @{
            That1 = 221
            That2 = 222
            That3 = 223
            That4 = $null
        }
        This3 = 23
    }
    Thing3 = 3
}
```
.EXAMPLE
$redstone.GetVar('Thing2.This2.That4', 'nope')

When being used to access `$redstone.Vars` there's a built-in method that calls this function a bit easier.
Returns `$null` from the following `$redstone.Vars` hashtable:

```powershell
$redstone.Vars = @{
    Thing1 = 1
    Thing2 = @{
        This1 = 21
        This2 = @{
            That1 = 221
            That2 = 222
            That3 = 223
            That4 = $null
        }
        This3 = 23
    }
    Thing3 = 3
}
```
.LINK
https://github.com/VertigoRay/PSRedstone/wiki/Functions#get-hashtablevalue
#>
function Get-HashtableValue([hashtable] $Hashtable, [string] $Path, $Default = $null) {
    $parent, $leaf = $Path.Split('.', 2)

    if ($leaf) {
        return (Get-HashtableValue $Hashtable.$parent $leaf $Default)
    } elseif ($Hashtable.Keys -contains $parent) {
        return $Hashtable.$parent
    } else {
        return $Default
    }
}
