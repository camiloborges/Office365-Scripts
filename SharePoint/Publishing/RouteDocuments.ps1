function Get-WebSession($url )
{
    Connect-SPOnline $url | out-null
    $uri = [System.Uri]$url
    # Retrieve the client credentials and the related Authentication Cookies
    $context = (Get-SPOWeb).Context
    $credentials = $context.Credentials
    $authenticationCookies = $credentials.GetAuthenticationCookie($uri, $true)
    # Set the Authentication Cookies and the Accept HTTP Header
    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $session.Cookies.SetCookies($uri, $authenticationCookies)

    return $session
}
function get-ApiUrl($url)
{
    return [RegEx]::Replace($url,"[^\x00-\x80]+","")
}
function Get-SourceFile ($sourceSiteUrl, $siteRelativeUrl, $fileName )
{
    $webSession = GEt-WebSession -url $sourceSiteUrl

    # Set request variables
    $apiUrl = "$($sourceSiteUrl)_api/web/getfilebyserverrelativeurl('‍$siteRelativeUrl‍Pages/$fileName')/`$value"
    $apiURl = [RegEx]::Replace($apiUrl,"[^\x00-\x80]+","")
    #https://kasa.sharepoint.com/sites/AusPostPEPCI/news/authoring/_api/web/getfilebyserverrelativeurl('/sites/AusPostPEPCI/news/authoring/Pages/TEstPost0329.aspx')/$value

    $fileFields = 
    # Make the REST request
    $content =  Invoke-RestMethod -Uri $apiUrl -Method Get -WebSession $webSession 
    $fileFieldsUrl = get-apiurl "$($sourceSiteUrl)_api/web/getfilebyserverrelativeurl('‍$siteRelativeUrl‍Pages/‍VolumeTest‍.aspx')"
    $response =  Invoke-RestMethod -Uri $fileFieldsUrl -Method Get -WebSession $webSession 
    $fileFields = $response.entry.content.properties

    $listItemAllFieldsUrl = get-apiurl "$($sourceSiteUrl)_api/web/getfilebyserverrelativeurl('‍$siteRelativeUrl‍Pages/‍VolumeTest‍.aspx')/ListItemAllFields"
    $response =  Invoke-RestMethod -Uri $listItemAllFieldsUrl -Method Get -WebSession $webSession 
    $listItemAllFields = $response.entry.content.properties
    if($listItemAllFields.WorkCentreDistributionList -ne $null)
    {
        $distributionGroups = ($listItemAllFields.WorkCentreDistributionList | ConvertFrom-Json).workCentreIds
        $distributionGroupsFixed = $distributionGroups.Trim(";").Split(";")
    }



    return @{"FileFields" = $fileFields;
             "ListItemAllFields" = $listItemAllFields
             "Content"= $content
             "DistributionGroupOutlets"=$distributionGroupsFixed 
             }

}

function Get-ContextInfo($tenantUrl, $siteRelativeUrl,$session)
{
    $targetSiteUrl =$("$tenantUrl$siteRelativeUrl")
    $apiUrl = "$($targetSiteUrl)_api/contextinfo"
    $contextInfo =  Invoke-RestMethod -Uri (get-apiurl $apiUrl) -Method POST -Body "" -WebSession $session 
    $formDigest= $contextInfo.GetContextWebInformation.FormDigestValue
    return @{FormDigest= $formDigest;
        Expiry = (get-date).AddMinutes(28)}

} 
function Invoke-RestMethodRetry($url, $method="GET", $session, $headers, $body=$null, $retryCount=0, $returnNullUponException =$false )
{
    try{
        $session = Clean-WebSession $session
        $response=  Invoke-RestMethod -Uri $url -Method $method -WebSession $session -Headers $headers -Body $body
        return $response
    }catch{
        if($returnNullUponException)
        {
            return;
        } 
        if($retryCount -gt 10)
        {
            $throw;
            return;
        }    
        $retryCount ++
        Sleep -Milliseconds 50
        return Invoke-RestMethodRetry  -url $url -method $method -session $session -headers $headers -retryCount $retryCount -body $body

    
    }
}
function Clean-WebSession($session){
  #$session.Headers.Remove("X-requestDigest") | Out-Null
  #$session.Headers.Remove("X-HTTP-Method")| Out-Null
  #$session.Headers.Remove("if-match")| Out-Null
  #$session.Headers.Remove("content-type")| Out-Null
   $session.Headers.Clear()

  return $session

}
function Get-AddHeaders($digest)
{
 $headers = @{"X-requestDigest"=$formDigest.FormDigest;
                    accept= "application/xml"
                }
                return $headers
}
function Get-UpdateHeaders($digest){
    @{"X-requestDigest"=$digest;
                        "IF-MATCH"="*";
                        "X-HTTP-Method"="MERGE";
                        "content-type"= "application/json;odata=verbose";
                        "accept"="application/json";
    } 
}
function Ensure-POPFolders($distributionGroupsFixed, $targetSiteUrl, $siteRelativeUrl,$webSessionTarget, $formDigest)
{
    $resultarray= @()
    foreach($outlet in $distributionGroupsFixed)
    {
        $apiUrl = "$($targetSiteUrl)_api/web/GetFolderByServerRelativeUrl('$($siteRelativeUrl)Pages/$($outlet)')"
        $headers = @{
                        accept= "application/json"
                    }
        $addFileUrl = (get-apiurl $apiUrl)
        $folder =  Invoke-RestMethodRetry -url $addFileUrl  -session $webSessionTarget -Headers $headers -returnNullUponException:$true
        if($folder.Exists -eq $false -or $folder -eq $null)
        {
            #$apiUrl = "$($targetSiteUrl)_api/web/GetFolderByServerRelativeUrl('$($siteRelativeUrl)Pages')/Folders/add('$($outlet)')'"
            #$folder =  Invoke-RestMethodRetry -url $apiUrl -method "POST"  -session $webSessionTarget -Headers (Get-AddHeaders $formDigest.FormDigest) -returnNullUponException:$true
            write-host "couldn't find folder $outlet"
        }else{
            $resultarray += $outlet
        }
    }
return $resultarray
}
function Distribute-POPContent( $targetSiteUrl, $siteRelativeUrl, $distributionGroupsList)
{
    $webSessionTarget = GEt-WebSession $targetSiteUrl
    $webSessionTarget = Clean-WebSession $webSessionTarget
    $formDigest= Get-ContextInfo $tenantUrl $siteRelativeUrl $webSessionTarget
    foreach($outlet in $distributionGroupsList )
    {
        if((get-date) -gt $formDigest.Expiry  ){
            $webSessionTarget = Get-WebSession -url $targetSiteUrl
            $formDigest = Get-ContextInfo $tenantUrl $siteRelativeUrl $webSessionTarget
        }
        $headers = @{"X-requestDigest"=$formDigest.FormDigest;
                        accept= "application/xml"
                    }
        $apiUrl = "$($targetSiteUrl)_api/web/GetFolderByServerRelativeUrl('$($siteRelativeUrl)Pages/$($outlet)')/Files/add(url='$($fileName)',overwrite=true)?`$expand=ListItemAllFields"
        $addFileUrl = (get-apiurl $apiUrl)
        $fileAdded =  Invoke-RestMethodRetry -url $addFileUrl -Method "POST" -Body $file.Content -session $webSessionTarget -Headers $headers 
        $link = ($fileAdded.entry.link | ? { $_.Rel -like "*ListItemAllFields"})
        $newitemFields = $link.inline.entry.content.properties
        $apiUrl = "$($targetSiteUrl)_api/web/lists/GetByTitle('Pages')/items("+$newitemFields.Id[0].'#text'+")"
        $jsonFields = @{    "__metadata"= @{"type"=  "SP.Data.PagesItem"                   }
                            "TextContent5"= $sourceUrl
                        } | ConvertTo-Json
        $webSessionTarget = Clean-WebSession $webSessionTarget 
        $updateHeaders =  Get-UpdateHeaders $formDigest.FormDigest
        $fieldsUpdated =  Invoke-RestMethodRetry -Url (get-apiurl $apiUrl) -Method POST  -body $jsonFields -session $webSessionTarget -Headers $updateHeaders 
        $processed++
        if($processed % 20 -eq 0)
        {
            write-host "$processed $outlet $(get-date)" 
        }
    }
}
cls
$tenantUrl = "https://kasa.sharepoint.com"
$siteRelativeUrl= "/sites/AusPostPEPCI/news/authoring/"
$sourceSiteUrl =$("$tenantUrl$siteRelativeUrl")
$sourceSiteUri = [System.Uri]$sourceSiteUrl

$file= Get-SourceFile $sourceSiteUrl $siteRelativeUrl "VolumeTest.aspx"
$siteRelativeUrl= "/sites/AusPostPEPCI/news/"
$targetSiteUrl =$("$tenantUrl$siteRelativeUrl")
$webSessionTarget = GEt-WebSession $targetSiteUrl
$formDigest= Get-ContextInfo $tenantUrl $siteRelativeUrl $webSessionTarget
$sourceUrl = $tenantUrl + $file.FileFields.ServerRelativeUrl
$fileName = $file.FileFields.Name 
$fileName =[IO.Path]::GetFileNameWithoutExtension($filename) + $file.ListItemAllFields.Id[1].'#text'  + [IO.Path]::GetExtension($filename) 
$distributionGroupsList =Ensure-POPFolders $file.DistributionGroupOutlets $targetSiteUrl $siteRelativeUrl $webSessionTarget $formDigest
$processed = 0

Distribute-POPContent -targetSiteUrl $targetSiteUrl -siteRelativeUrl $siteRelativeUrl -distributionGroupsList $distributionGroupsList