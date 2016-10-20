$cred = Get-Credential camilo.borges@yokedesign.com.au

$session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell/ -Credential $cred -Authentication Basic -AllowRedirection

Import-PSSession $sessio

Set-TransportConfig -ExternalPostmasterAddress postmaster@yokedesign.com.au


Remove-PSSession $session

