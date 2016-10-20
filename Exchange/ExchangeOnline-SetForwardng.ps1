$cred = Get-Credential camilo.borges@fivep.com.au

$session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell/ -Credential $cred -Authentication Basic -AllowRedirection

Import-PSSession $session

Set-Mailbox -Identity Alias -DeliverToMailboxAndForward $true -ForwardingSMTPAddress lana.l@yokedesign.com.au

<#
Set-CASMailbox –Identity “user mailbox” –OwaMailboxPolicy “newpolicy”


Remove-PSSession $session

Set-DistributionGroup 'CamiloDG'  –SendOofMessageToOriginatorEnabled $True

Set-Mailbox -Identity jill -DeliverToMailboxAndForward $true -ForwardingSMTPAddress lana.l@yokedesign.com.au
#>
