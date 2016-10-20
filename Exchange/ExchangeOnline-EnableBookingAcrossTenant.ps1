$cred = Get-Credential camilo.borges@yokedesign.com.au

$session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell/ -Credential $cred -Authentication Basic -AllowRedirection

Import-PSSession $session

 Set-CalendarProcessing –Identity “Boardroom” -ProcessExternalMeetingMessages $true
 Set-CalendarProcessing –Identity “Fishbowl” -ProcessExternalMeetingMessages $true
 Set-CalendarProcessing –Identity “Basement” -ProcessExternalMeetingMessages $true

Remove-PSSession $session

