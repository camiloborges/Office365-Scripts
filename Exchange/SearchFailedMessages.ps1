<#
$cred = Get-Credential camilo.borges@yokedesign.com.au

$session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell/ -Credential $cred -Authentication Basic -AllowRedirection

Import-PSSession $session
#>

$dateStart = get-date -Day 18 -Month 2 -Year 2016 -hour 20 -Minute 0
$dateEnd =  get-date -Day 23 -Month 2 -Year 2016 -hour 10 -Minute 30
$recipient = "jobs@yokedesign.com.au" 
$msgs = Get-MessageTrace -StartDate $dateStart -EndDate $dateEnd -Verbose -RecipientAddress $recipient |   Select-Object Received, SenderAddress, RecipientAddress, Subject, Status, ToIP, FromIP, Size, MessageID, MessageTraceID | ? {($_.Status -ne "Delivered") -and $_.SenderAddress -ne "support@panthur.com.au"}  

$msgs | %{
 $trace = $_      
 $msg=  $trace |Get-MessageTraceDetail 

}

<#
Remove-PSSession $session
#>
