$account = "camilo.migration@kasa.onmicrosoft.com"
$cred = Get-Credential $account

$session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell/ -Credential $cred -Authentication Basic -AllowRedirection

Import-PSSession $session

Get-Mailbox -ResultSize Unlimited | Add-MailboxPermission -AccessRights FullAccess -Automapping $false -User $account | Out-Null

Remove-PSSession $session