param(
    $sourceTenant = "https://kasa.sharepoint.com" ,
    $targetTenant = "https://fivep.sharepoint.com",
    $company = "Yoke Design"
)
$sourceCredential = Get-Credential -Message "Please type in credentials for source tenant $sourceTenant "
$targetCredential = Get-Credential -Message "Please type in credentials for target tenant  $targetTenant "

#Capture administrative credential for future connections.
$credential = $targetCredential 

#Imports the installed Azure Active Directory module.
Import-Module MSOnline -ErrorAction SilentlyContinue

#Establishes Online Services connection to Office 365 Management Layer.
Connect-MsolService -Credential $sourceCredential

$sourceUsers = Get-MsolUser -All 

$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $targetCredential -Authentication Basic -AllowRedirection
Import-PSSession $Session

$sourceUsers | % {
$user = $_
$upn = $user.UserPrincipalName
$contact = Get-Contact -ResultSize unlimited |  ? { $_.WindowsEmailAddress -eq $upn  } 
if($contact -eq $null)
{
    $contact = New-MailContact -Name $user.DisplayName -ExternalEmailAddress $user.UserPrincipalName 
}


Set-Contact -Identity $contact.Id `
            -City $user.City`
            -Company $company `
            -Confirm:$false  `
            -CountryOrRegion $user.Country`
            -Department  $user.Department  `
            -DisplayName $user.DisplayName `
            -Fax $user.Fax `
            -FirstName $user.FirstName `
            -Initials $user.Initials `
            -LastName $user.LastName `
            -Manager $user.Manager `
            -MobilePhone $user.MobilePhone `
            -Phone $user.PhoneNumber `
            -PostalCode $user.PostalCode `
            -StateOrProvince $user.State `
            -StreetAddress  $user.StreetAddress `
            -Title $user.Title `
}
Remove-PSSession $Session 

