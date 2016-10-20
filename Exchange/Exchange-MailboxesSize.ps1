$account = "camilo.borges@fivep.com.au"
$cred = Get-Credential $account

$session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell/ -Credential $cred -Authentication Basic -AllowRedirection

Import-PSSession $session

Get-Mailbox -ResultSize Unlimited | Get-MailboxStatistics |   Select DisplayName,StorageLimitStatus, `
  @{name=”TotalItemSize (MB)”; expression={[math]::Round( `
  ($_.TotalItemSize.Split(“(“)[1].Split(” “)[0].Replace(“,”,””)/1MB),2)}}, `
  ItemCount |  Sort “TotalItemSize (MB)” -Descending

Remove-PSSession $session