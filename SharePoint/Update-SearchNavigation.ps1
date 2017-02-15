$tenant = "https://contoso.sharepoint.com"
Connect-PnPOnline -Url $tenant 
$web = Get-PnPWeb
$context = Get-PnPContext
$navigation = $web.Navigation
$srchNav = $navigation.GetNodeById(1040);
[Microsoft.SharePoint.Client.NavigationNodeCollection] $sNodes = $srchNav.Children
$context.Load($srchnav)
$context.Load($sNodes)
$context.ExecuteQuery()

$sNodes | %{
    write-host $($_.Title + " : " + $_.Url);
}


