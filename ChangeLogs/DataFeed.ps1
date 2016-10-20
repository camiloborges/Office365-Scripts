####  NEEDS UPDATE - not really, you can update in the dialog
$user = "cborges@bom.gov.au"
$Pass =  "CafeLatte123"
$Global:creds = New-Object System.Management.Automation.PSCredential($User,(ConvertTo-SecureString $Pass -AsPlainText -Force));

$Global:rootFullUrl  = "https://bom365.sharepoint.com/TeamSites/edrms" 
Connect-SPOnline -Url $Global:rootFullUrl  -Credential $Global:creds

$context = Get-SPOContext

$web = Get-SPOWeb

$listTitle = "Board Documents"
$list = $context.Web.Lists.GetByTitle($listTitle)
$context.Load($list)
$context.ExecuteQuery()


$query = [Microsoft.SharePoint.Client.CamlQuery]::CreateAllItemsQuery()
#$spQuery.ViewAttributes = "Scope='Recursive'";
#$spQuery.RowLimit = 2000

$items = $list.GetItems($query)
$context.Load($items)
$context.ExecuteQuery()

$items

$item = $items[0]
$values = $item.FieldValuesAsText
 $context.Load($values)
 $context.ExecuteQuery()


 $values
