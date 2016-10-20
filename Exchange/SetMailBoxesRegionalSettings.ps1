$cred = Get-Credential camilo.borges@yokedesign.com.au

$session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell/ -Credential $cred -Authentication Basic -AllowRedirection

Import-PSSession $session


Get-Mailbox –Resultsize unlimited | Set-MailboxRegionalConfiguration –Language en-au –TimeZone "AUS Eastern Standard Time"

Remove-PSSession $session

