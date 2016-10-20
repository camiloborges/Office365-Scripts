$credFiveP = Get-Credential camilo.borges@fivep.com.au


$sessionFiveP = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell/ -Credential $credFiveP -Authentication Basic -AllowRedirection

Import-PSSession $sessionFiveP
#Enable-OrganizationCustomization 
Get-FederationInformation -DomainName "kasa.onmicrosoft.com" | New-OrganizationRelationship -Name "Yoke-Federation" -Enabled $true -FreeBusyAccessEnabled $true -FreeBusyAccessLevel "LimitedDetails" -FreeBusyAccessScope $null

Remove-PSSession $sessionFiveP
#Set-OrganizationRelationship ‘FiveP-Federation’ -FreeBusyAccessLevel LimitedDetails
break




$cred = Get-Credential camilo.borges@yokedesign.com.au


$session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell/ -Credential $cred -Authentication Basic -AllowRedirection

Import-PSSession $session
Get-OrganizationConfig | fl  Identity, IsDehydrated

Enable-OrganizationCustomization
Get-FederationInformation -DomainName "fivep.onmicrosoft.com" | New-OrganizationRelationship -Name ‘FiveP-Federation’ -Enabled $true -FreeBusyAccessEnabled $true -FreeBusyAccessLevel "LimitedDetails" -FreeBusyAccessScope $null

Remove-PSSession $session

