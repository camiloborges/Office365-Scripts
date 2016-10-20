$cred = Get-Credential camilo.borges@yokedesign.com.au

$session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell/ -Credential $cred -Authentication Basic -AllowRedirection

Import-PSSession $session


#Get-Mailbox –Resultsize unlimited | Set-MailboxRegionalConfiguration –Language en-au –TimeZone "AUS Eastern Standard Time"
#https://outlook.office.com/owa/enquiries@fivep.com.au/?offline=disabled

Set-Mailbox -Identity "Douglas Kohn" -DeliverToMailboxAndForward $true -ForwardingSMTPAddress "douglaskohn.parents@fineartschool.net"

Remove-PSSession $session

