function CreateOrUpdateProperties($url, [int]$NavOrder, $hide= $false)

{
    Connect-SPOnline $url #/teamsites
    $web = get-pnpweb
    write-host $web.Url
    Get-PnPPropertyBag -Key "TopNavigationOrder" -Web $web
    Set-PnPPropertyBagValue -Key "TopNavigationOrder" -Value $NavOrder -Indexed:$true  -Web $web
    $web.Update();
    Get-PnPPropertyBag -Key "TopNavigationOrder" -Web $web

$web.Context.ExecuteQuery()
    Set-PnPPropertyBagValue -Key "HideFromTopNavigation" -Value $hide  -Indexed:$true -Web $web

Get-PnPPropertyBag -Key "HideFromTopNavigation" -Web $web
$web.Update();

$web.Context.ExecuteQuery()
}


CreateOrUpdateProperties -url https://lochardenergy.sharepoint.com/News -NavOrder 1 
CreateOrUpdateProperties -url https://lochardenergy.sharepoint.com/HSE -NavOrder 2 
CreateOrUpdateProperties -url https://lochardenergy.sharepoint.com/Resources -NavOrder 3 
CreateOrUpdateProperties -url https://lochardenergy.sharepoint.com/TeamSites -NavOrder 4 
CreateOrUpdateProperties -url https://lochardenergy.sharepoint.com/aboutus -NavOrder 5 
CreateOrUpdateProperties -url https://lochardenergy.sharepoint.com/SearchCentre -NavOrder 5 -hide:$true


