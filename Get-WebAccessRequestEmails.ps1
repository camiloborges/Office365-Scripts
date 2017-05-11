

$adminUPN="admin@prixcar.onmicrosoft.com"
$orgName="Prixcar"
$userCredential = Get-Credential -UserName $adminUPN -Message "Password"
Connect-SPOService -Url https://$orgName-admin.sharepoint.com -Credential $userCredential
Connect-SPOnline -Url https://$orgName.sharepoint.com -Credential $userCredential

$sites = Get-SPOTenantSite

$sites |Where-Object {$_.Url -match ".sharepoint.com"} | ForEach-Object {
    Connect-SPOnline -Url $_.Url -Credential $userCredential
    $site = get-sposite 

    $rootweb = $site.RootWeb
    $site.Context.Load($site.Owner);
    $site.Context.ExecuteQuery()
     $site.Owner.Email; 
    $site.Context.Load($rootWeb.Webs);
    $site.Context.ExecuteQuery();
    $rootweb.Webs | ForEach-Object{
        $web = $_
        Write-Host ("{0} {1}" -f $web.ServerRelativeUrl, $web.RequestAccessEmail)
    }

}