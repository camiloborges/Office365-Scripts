set-Location "C:\Users\CamiloBorges\OneDrive for Business\Fusion"
#needs extra permnissions, check https://social.technet.microsoft.com/Forums/exchange/en-US/581cf80b-d88d-4265-b0ee-9400e035abdd/exchange-powershell-command-not-recognized?forum=exchangesvrgeneral
###     "Compliance Management", "Organization Management" and "Records Management".

## user running needs roles "ApplicationImpersonation" and "Import Export Emails"
$credential = Get-Credential -Message "Please type in credentials for tenant kasa "

#.\Wipe-EXOMailbox.ps1 -Credential $credential -Identity "camilo.borges@yokedesign.com.au"

function GetDelete-Mailbox ($identity)
{

    $mailbox = Get-Mailbox -ResultSize unlimited  -Identity $identity  
if($mailbox -ne $null)
{
    Remove-Mailbox -Identity  $mailbox.Identity 
    Clean-MailboxDatabase -Identity $mailbox.Identity

    Restore-MsolUser -UserPrincipalName $mailbox.identity -AutoReconcileProxyConflicts
}
}

$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $credential -Authentication Basic -AllowRedirection
Import-PSSession $Session

GetDelete-Mailbox -identity "pauline@yokedesign.com.au"

Remove-PSSession $Session 

