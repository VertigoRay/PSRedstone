$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"



$PSDefaultParameterValues.Set_Item('Assert-WinstallCacheIsValid:Folder', $env:Temp)

$winstall_cache = @(
    @{
        'Name' = "${sut}-SimpleContent";
        'Content' = '2xOm3wyh3WndvsaDeb6a5dDjhcF^b&%3n9LzGQkADBjRoC#9mQCYI!Ez^lg$h*Jjkxq#qM&6YX4*e*yw#tcLgR8IonLPo#u7a@uP'
        'SizeBytes' = 102;
        'SHA512' = 'B333B056B60380A72F8ACDD82DC77B5050F560434718D620C5FB063D0C5142D39A922E03A9A31749541984023AADD11ECAE0D50555F38779754E9BAD2CD0CBFB';
    }
)



Describe $sut {
    foreach ($cache in $winstall_cache) {
        Context $cache.Name {
            $local_zip = "{0}\{1}.zip" -f $env:Temp, $cache.Name
            $cache.Content | Out-File $local_zip -Encoding 'ascii'

            It 'Is Valid' {
                Assert-WinstallCacheIsValid -Name $cache.Name -SizeBytes $cache.SizeBytes -SHA512 $cache.SHA512
            }

            It 'File does not exist: check return' {
                Assert-WinstallCacheIsValid -Name ('Foo{0}' -f $cache.Name) -SizeBytes $cache.SizeBytes -SHA512 $cache.SHA512 | Should Be $false
            }

            It 'File does not exist: validate' {
                $information = Assert-WinstallCacheIsValid -Name ('Foo{0}' -f $cache.Name) -SizeBytes $cache.SizeBytes -SHA512 $cache.SHA512 6>&1
                $information[2] | Should Be "Local Zip File: doesn't exist."
            }

            It 'File size wrong: check return' {
                Assert-WinstallCacheIsValid -Name ('Foo{0}' -f $cache.Name) -SizeBytes ($cache.SizeBytes + 1) -SHA512 $cache.SHA512 | Should Be $false
            }

            It 'File size wrong: validate' {
                $information = Assert-WinstallCacheIsValid -Name $cache.Name -SizeBytes ($cache.SizeBytes + 1) -SHA512 $cache.SHA512 6>&1
                $information[3] | Should Be "Local Zip File Size: $($cache.SizeBytes)"
            }

            It 'File SHA512 wrong: check return' {
                Assert-WinstallCacheIsValid -Name $cache.Name -SizeBytes $cache.SizeBytes -SHA512 ('Foo{0}' -f $cache.SHA512) | Should Be $false
            }

            It 'File SHA512 wrong: validate' {
                $information = Assert-WinstallCacheIsValid -Name $cache.Name -SizeBytes $cache.SizeBytes -SHA512 ('Foo{0}' -f $cache.SHA512) 6>&1
                $information[5] | Should Be "Local Zip SHA512: $($cache.SHA512)"
            }
        }
    }
}
