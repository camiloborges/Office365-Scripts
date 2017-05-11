$account = ""
$cred = Get-Credential $account

$session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell/ -Credential $cred -Authentication Basic -AllowRedirection

Import-PSSession $session

Get-OrganizationalUnit


Remove-PSSession $session