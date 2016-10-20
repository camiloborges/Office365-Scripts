$cred = Get-Credential camilo.borges@fivep.com.au

$session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell/ -Credential $cred -Authentication Basic -AllowRedirection

Import-PSSession $session


Get-Mailbox –Resultsize unlimited | %{
#| Set-MailboxRegionalConfiguration –Language en-au –TimeZone "AUS Eastern Standard Time"
$mailbox = $_
Set-MailboxFolderPermission "$($mailbox.Id):\Calendar" -User Default -AccessRights   LimitedDetails     


}
#Set-MailboxFolderPermission Boardroom:\Calendar -User Default -AccessRights Reviewer
#Set-MailboxFolderPermission Fishbowl:\Calendar -User Default -AccessRights Reviewer
#Set-MailboxFolderPermission Basement:\Calendar -User Default -AccessRights Reviewer


Remove-PSSession $session
