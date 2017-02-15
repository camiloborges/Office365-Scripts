Connect-PnPOnline -Url $tenant 
$web = Get-PnPWeb
$context = Get-PnPContext
# $navSettings = [Microsoft.SharePoint.Client.NavigationExtensions]::GetNavigationSettings($web)
$navigation = $web.Navigation
$topNav = [ Microsoft.SharePoint.Client.NavigationNodeCollection]$navigation.TopNavigationBar 
$context.Load($topNav)
$context.ExecuteQuery()

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

 $srchNav = $navigation.GetNodeById(2034);
[Microsoft.SharePoint.Client.NavigationNodeCollection] $sNodes = $srchNav.Children
$context.Load($srchnav)
$context.Load($sNodes)
$context.ExecuteQuery()
 break;
$navigation | % {
$_.Context.Load($_.Children)
$_.Context.ExecuteQuery()
$_.Children.Count

}