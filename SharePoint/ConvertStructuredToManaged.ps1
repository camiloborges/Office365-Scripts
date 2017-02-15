$tenant = "https://kasa.sharepoint.com"
Connect-PnPOnline -Url $tenant 
$web = Get-PnPWeb
$context = Get-PnPContext
# $navSettings = [Microsoft.SharePoint.Client.NavigationExtensions]::GetNavigationSettings($web)
$navigation = $web.Navigation
#$topNav = [ Microsoft.SharePoint.Client.NavigationNodeCollection]$navigation.TopNavigationBar 
#$context.Load($topNav)
#$context.ExecuteQuery()


 $srchNav = $navigation.GetNodeById(1040);
[Microsoft.SharePoint.Client.NavigationNodeCollection] $sNodes = $srchNav.Children
$context.Load($srchnav)

$context.Load($sNodes)
$context.ExecuteQuery()

$sNodes | %{

write-host $($_.Title + " : " + $_.Url);
}

#}
 break;
$navigation | % {
$_.Context.Load($_.Children)
$_.Context.ExecuteQuery()
$_.Children.Count

}



foreach($node in $topNav) 
 {
     $node.Title
     write-host $node.Url
     $node.Context.Load($node.Children)
     $node.Context.ExecuteQuery()
     foreach($child in $node.Children){
     $child.Title
     
     }
     #//Your logic
 }