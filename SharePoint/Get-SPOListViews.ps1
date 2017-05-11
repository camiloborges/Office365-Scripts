
$user ="cborges@bom.gov.au" 
$pass=  read-host "Password" 
$verbose = $false
$Global:creds = New-Object System.Management.Automation.PSCredential($User,(ConvertTo-SecureString $Pass -AsPlainText -Force));
$Global:rootRelativeUrl = ""

$Global:adminUrl = "https://bom365.sharepoint.com/TeamSites/Template"
Connect-SPOnline -Url $Global:adminUrl  -Credential $Global:creds

$list = Get-SPOList "Documents" 

$list.Context.Load($list.Views)
$list.Context.ExecuteQuery()

$list.Views
