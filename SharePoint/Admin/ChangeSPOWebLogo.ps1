

$user = "5p@cehl.com.au"
$Pass =  read-host "Password"
cls
$verbose = $false
$Global:creds = New-Object System.Management.Automation.PSCredential($User,(ConvertTo-SecureString $Pass -AsPlainText -Force));

$tenant ="commonequityhousinglimited"
$Global:adminUrl = "https://$($tenant)-admin.sharepoint.com"

$Global:rootFullUrl  = "https://$($tenant).sharepoint.com"


Connect-SPOService -Url $Global:adminUrl  -Credential $Global:creds
Connect-SPOnline -Url $Global:rootFullUrl  -Credential $Global:creds
write-host "authenticated " (Get-Date).ToLongTimeString()

$rootWeb = Get-SPOWeb
$webs = $web.Webs
$web.Context.Load($webs)
$web.Context.ExecuteQuery()
$webs | % {

$web = $_

if($web.Url -ne "https://commonequityhousinglimited.sharepoint.com")
{

    $web.SiteLogoUrl ="/SiteAssets/CR%20V7.jpg"
    $web.Update()
    $web.Context.ExecuteQuery()
    $web.Url
}
}