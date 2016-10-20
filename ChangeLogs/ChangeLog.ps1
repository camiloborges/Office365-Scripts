


set-location $defaultLocation
Add-Type -Path "C:\Program Files (x86)\OfficeDevPnP.PowerShell.V16.Commands\Modules\OfficeDevPnP.PowerShell.V16.Commands\Microsoft.SharePoint.Client.dll" 



. .\IntranetNow.Deployment.Functions.ps1

function ProcessChanges($changeable)
{
$qry = new-object Microsoft.Sharepoint.Client.ChangeQuery($true,$true)
$changes = $changeable.GetChanges($qry)
$changeable.context.Load($changes)
$changeable.context.ExecuteQuery()


$changes | %{ 
$spocChange = $_
#select ChangeType, Time
       Write-Host "Change Type: " $spocChange.ChangeType " - Object Type: " $spocChange.TypedObject " - Change Date: " $spocChange.Time  -Foregroundcolor White
    } 

}
####  NEEDS UPDATE - not really, you can update in the dialog
$user = "cborges@bom.gov.au"
$Pass =  "CafeLatte123"
$Global:creds = New-Object System.Management.Automation.PSCredential($User,(ConvertTo-SecureString $Pass -AsPlainText -Force));

$tenant = "bom365"

$Global:rootRelativeUrl = ""
$Global:adminUrl = "https://$($tenant)-admin.sharepoint.com"
$rootFullUrl  = "https://$($tenant).sharepoint.com$($($Global:rootRelativeUrl))"
$Global:rootFullUrl  = "https://$($tenant).sharepoint.com$($($Global:rootRelativeUrl))"

Connect-SPOnline -Url $Global:rootFullUrl  -Credential $Global:creds

$context = Get-SPOContext

$web = Get-SPOWeb

ProcessChanges $web


ProcessChanges $context.Site



$listTitle = "Documents"
$list = $context.Web.Lists.GetByTitle($listTitle)

ProcessChanges $list

$qry = new-object Microsoft.Sharepoint.Client.ChangeQuery($true,$true)
$changes = $list.GetChanges($qry)
$context.Load($changes)
$context.ExecuteQuery()
$items = $changes | ? {$_.TypedObject.ToString() -eq "Microsoft.SharePoint.Client.ChangeItem"}
$items[0]
$items = $changes | ? {$_.TypedObject.ToString() -eq "Microsoft.SharePoint.Client.ChangeFile"}
$items[0]


$changes | select ChangeType, Time







