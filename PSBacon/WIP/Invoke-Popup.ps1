<#
.SYNOPSIS
Creates a popup message for the user.
.DESCRIPTION
Creates a popup message for the user. Returns the result of which button they clicked. This uses the [Popup Method](https://msdn.microsoft.com/en-us/library/x83z1d9f(v=vs.84).aspx).

Here's a table of the possible return values and their meanings:

| Integer Value          | Description |
|------------------------|-------------|
| -1                     | User did not click a button before *n* seconds elapsed. |
| 1                      | User Clicked: OK button. |
| 2                      | User Clicked: Cancel button. |
| 3                      | User Clicked: Abort button. |
| 4                      | User Clicked: Retry button. |
| 5                      | User Clicked: Ignore button. |
| 6                      | User Clicked: Yes button. |
| 7                      | User Clicked: No button. |
| 10                     | User Clicked: Try Again button. |
| 11                     | User Clicked: Continue button. |
.PARAMETER Text
String value that contains the text you want to appear in the pop-up message box.
.PARAMETER SecondsToWait
Optional. Default: 0

Numeric value indicating the maximum number of seconds you want the pop-up message box displayed. If `SecondsToWait` is zero (the default), the pop-up message box remains visible until closed by the user.
.PARAMETER Title
Optional. Default: $null

String value that contains the text you want to appear as the title of the pop-up message box.
.PARAMETER ButtonType
Optional. Default: Ok

Specifies the button(s) to present on the popup message box. Here's a table of the acceptable values and their meanings:

| String Value           | Description |
|------------------------|-------------|
| Ok                     | Show OK button. |
| OkCancel               | Show OK and Cancel buttons. |
| AbortRetryIgnore       | Show Abort, Retry, and Ignore buttons. |
| YesNoCancel            | Show Yes, No, and Cancel buttons. |
| YesNo                  | Show Yes and No buttons. |
| RetryCancel            | Show Retry and Cancel buttons. |
| CancelTryAgainContinue | Show Cancel, Try Again, and Continue buttons. |
.PARAMETER IconType
Optional. Default: $null (will not show any icon)

Specifies the icon to present in the popup message box. Here's a table of the acceptable values and their meanings:

| String Value           | Description |
|------------------------|-------------|
| Stop                   | Show "Stop Mark" icon. |
| Question               | Show "Question Mark" icon. |
| Exclamation            | Show "Exclamation Mark" icon. |
| Information            | Show "Information Mark" icon. |
.PARAMETER DefaultButton
Optional. Default: $null (The first button is the default button.)

Specifies which button will be default (just press `Enter`) in the popup message box. Here's a table of the acceptable values and their meanings:

| String Value           | Description |
|------------------------|-------------|
| Second                 | The second button is the default button. |
| Third                  | The third button is the default button. |
.PARAMETER SystemModal
The message box is a system modal message box and appears in a topmost window.
.PARAMETER RightJustified
The text is right-justified.
.PARAMETER RightToLeftReadingOrder
The message and caption text display in right-to-left reading order, which is useful for some languages.
.PARAMETER TextSignature
Default: `$global:Winstall.Settings.Functions.InvokePopup.TextSignature`

This is the custom signature to append to the `Text` parameter; after two newlines. This is really meant to be set globally with custom contact information for the User's IT Support department.
.OUTPUTS
[int]
.EXAMPLE
Invoke-Popup "Hello World!"
1
.EXAMPLE
Invoke-Popup "Hello World!" -Title "Test"
1
.EXAMPLE
Invoke-Popup "Hello World!" -Title "Test" -ButtonType 'YesNo'
6
.EXAMPLE
Invoke-Popup "Hello World!" -Title "Test" -ButtonType 'YesNo' -DefaultButton 'Second'
7
.EXAMPLE
Invoke-Popup "Hello World!" -Title "Test" -ButtonType 'YesNo' -DefaultButton 'Second' -IconType 'Exclamation'
7
.EXAMPLE
Invoke-Popup "Hello World!" -Title "Test" -ButtonType 'YesNo' -DefaultButton 'Second' -IconType 'Exclamation' -SystemModal
7
#>
function Invoke-Popup {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Text
        ,
        [Parameter(Mandatory=$false)]
        [int]
        $SecondsToWait = 0
        ,
        [Parameter(Mandatory=$false)]
        [string]
        $Title = $null
        ,
        [Parameter(Mandatory=$false)]
        [ValidateSet('Ok','OkCancel','AbortRetryIgnore','YesNoCancel','YesNo','RetryCancel','CancelTryAgainContinue')] 
        [string]
        $ButtonType = 'Ok'
        ,
        [Parameter(Mandatory=$false)]
        [ValidateSet('Stop','Question','Exclamation','Information')] 
        [string]
        $IconType = $null
        ,
        [Parameter(Mandatory=$false)]
        [ValidateSet('Second','Third')] 
        [string]
        $DefaultButton = $null
        ,
        [Parameter(Mandatory=$false)]
        [switch]
        $SystemModal
        ,
        [Parameter(Mandatory=$false)]
        [switch]
        $RightJustified
        ,
        [Parameter(Mandatory=$false)]
        [switch]
        $RightToLeftReadingOrder
        ,
        [Parameter(Mandatory=$false)]
        [string[]]
        $TextSignature = $global:Winstall.Settings.Functions.InvokePopup.TextSignature
    )

    if ($TextSignature) {
        $Text = @("${Text}$([Environment]::NewLine)$([Environment]::NewLine)$($TextSignature -join [Environment]::NewLine)")
    }
    [System.Collections.ArrayList] $popup_params = @($Text)

    if ($ButtonType -or $IconType -or $DefaultButton -or $SystemModal -or $RightJustified -or $RightToLeftReadingOrder) {
        $popup_params.Add($SecondsToWait) | Out-Null
        $popup_params.Add($Title) | Out-Null
        
        $Type = 0

        switch ($ButtonType) {
            'Ok'                        { $Type += 0 }
            'OkCancel'                  { $Type += 1 }
            'AbortRetryIgnore'          { $Type += 2 }
            'YesNoCancel'               { $Type += 3 }
            'YesNo'                     { $Type += 4 }
            'RetryCancel'               { $Type += 5 }
            'CancelTryAgainContinue'    { $Type += 6 }
        }

        switch ($IconType) {
            'Stop'                      { $Type += 16 }
            'Question'                  { $Type += 32 }
            'Exclamation'               { $Type += 48 }
            'Information'               { $Type += 64 }
        }

        switch ($DefaultButton) {
            'Second'                    { $Type += 256 }
            'Third'                     { $Type += 512 }
        }

        if ($SystemModal)               { $Type += 4096 }
        if ($RightJustified)            { $Type += 524288 }
        if ($RightToLeftReadingOrder)   { $Type += 1048576 }

        $popup_params.Add($Type) | Out-Null
    } elseif ($Title) {
        $popup_params.Add($SecondsToWait) | Out-Null
        $popup_params.Add($Title) | Out-Null
    } elseif ($SecondsToWait) {
        $popup_params.Add($SecondsToWait) | Out-Null
    }

    $wshell = New-Object -ComObject Wscript.Shell

    if ($popup_params.Count -eq 1) {
        Write-Information "Popup Message presented:$([Environment]::NewLine)Text: $($popup_params[0])"
        $response = $wshell.Popup($popup_params[0])
    } elseif ($popup_params.Count -eq 2) {
        Write-Information "Popup Message presented:$([Environment]::NewLine)Text: $($popup_params[0])$([Environment]::NewLine)SecondsToWait: $($popup_params[1])"
        $response = $wshell.Popup($popup_params[0], $popup_params[1])
    } elseif ($popup_params.Count -eq 3) {
        Write-Information "Popup Message presented:$([Environment]::NewLine)Text: $($popup_params[0])$([Environment]::NewLine)SecondsToWait: $($popup_params[1])$([Environment]::NewLine)Title: $($popup_params[2])"
        $response = $wshell.Popup($popup_params[0], $popup_params[1], $popup_params[2])
    } else {
        Write-Information "Popup Message presented:$([Environment]::NewLine)Text: $($popup_params[0])$([Environment]::NewLine)SecondsToWait: $($popup_params[1])$([Environment]::NewLine)Title: $($popup_params[2])$([Environment]::NewLine)Type: $($popup_params[3])"
        $response = $wshell.Popup($popup_params[0], $popup_params[1], $popup_params[2], $popup_params[3])
    }

    switch ($response) {
        -1  { Write-Information ('User did not click a button before {0} seconds elapsed.' -f $SecondsToWait) }
        1   { Write-Information 'User Clicked: OK button.' }
        2   { Write-Information 'User Clicked: Cancel button.' }
        3   { Write-Information 'User Clicked: Abort button.' }
        4   { Write-Information 'User Clicked: Retry button.' }
        5   { Write-Information 'User Clicked: Ignore button.' }
        6   { Write-Information 'User Clicked: Yes button.' }
        7   { Write-Information 'User Clicked: No button.' }
        10  { Write-Information 'User Clicked: Try Again button.' }
        11  { Write-Information 'User Clicked: Continue button.' }
    }

    return $response
}