

function Add-IndexesToLists($web, $context)
{
    $lists = $web.Lists
    $context.Load($lists)
    $context.ExecuteQuery()
    $lists | %{
        $list = $_
        $list.Context.Load($list.RootFolder)
        $fields = $list.fields
        $context.Load($fields)
        $context.ExecuteQuery()
        $indexedFields = $fields | ?{$fieldsOfInterest -contains $_.StaticName} 
        if($indexedFields.Count -gt 0)
        {
            write-host "$($list.Title ) url: $($list.RootFolder.ServerRelativeUrl)"
            $indexedFields| %{
                $field = $_
                write-host "$($field.StaticName) $($field.Indexed)"
                $field.Indexed =$true;
                $field.Update();
            }
            $context.ExecuteQuery() 
        }
    }
}
function Process-Web ($web, $context)
{
$webs = $Web.Webs
$context.Load($Webs)
$context.ExecuteQuery()
Add-IndexesToLists $web $context
$webs |% {
    $w = $_
    Process-Web $w $context

}

}

$fieldsOfInterest = $("Document_x0020_Type","Topic","Month","Year" )
$tenant = "https://contoso.sharepoint.com"
Connect-PnPOnline -Url $tenant
$web = Get-PnPWeb
$context = Get-PnPContext
Process-Web $web $context 
