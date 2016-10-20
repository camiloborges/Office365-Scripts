$UserCredential = Get-Credential camilo.migration@fivep.onmicrosoft.com

Connect-MsolService -Credential $UserCredential

$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection

Import-PSSession $Session -AllowClobber

$Records = Get-mailbox | where {$_.emailaddresses -like "smtp:*@fivep.com.au"} | Select-Object DisplayName,@{Name=“EmailAddresses”;Expression={$_.EmailAddresses |Where-Object {$_ -like “smtp:*fivep.com.au”}}}

break
foreach ($record in $Records)
{
    write-host "Removing Alias" $record.EmailAddresses "for" $record.DisplayName
    Set-Mailbox $record.DisplayName -EmailAddresses @{Remove=$record.EmailAddresses}
}