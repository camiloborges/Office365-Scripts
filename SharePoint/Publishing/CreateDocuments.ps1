function Get-WebSession($url )
{
  
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

function Create-POPContent( $siteUrl, $siteRelativeUrl, $content,$fileName)
{
    $webSessionTarget = GEt-WebSession $targetSiteUrl
    $webSessionTarget = Clean-WebSession $webSessionTarget
    $formDigest= Get-ContextInfo $tenantUrl $siteRelativeUrl $webSessionTarget
    if((get-date) -gt $formDigest.Expiry  ){
            $webSessionTarget = Get-WebSession -url $targetSiteUrl
            $formDigest = Get-ContextInfo $tenantUrl $siteRelativeUrl $webSessionTarget
        }
        $headers = @{"X-requestDigest"=$formDigest.FormDigest;
                        accept= "application/xml"
                    }
        $apiUrl = "$($siteUrl)_api/web/GetFolderByServerRelativeUrl('$($siteRelativeUrl)Pages/$($outlet)')/Files/add(url='$($fileName)',overwrite=true)?`$expand=ListItemAllFields"
        $addFileUrl = (get-apiurl $apiUrl)
        $fileAdded =  Invoke-RestMethodRetry -url $addFileUrl -Method "POST" -Body $content -session $webSessionTarget -Headers $headers 
        $link = ($fileAdded.entry.link | ? { $_.Rel -like "*ListItemAllFields"})
        $newitemFields = $link.inline.entry.content.properties
        $apiUrl = "$($targetSiteUrl)_api/web/lists/GetByTitle('Pages')/items("+$newitemFields.Id[0].'#text'+")"
        $jsonFields = @{    "__metadata"= @{"type"=  "SP.Data.PagesItem"                   }
                            "TextContent5"= $sourceUrl
                        } | ConvertTo-Json
        $webSessionTarget = Clean-WebSession $webSessionTarget 
        $updateHeaders =  Get-UpdateHeaders $formDigest.FormDigest
        $fieldsUpdated =  Invoke-RestMethodRetry -Url (get-apiurl $apiUrl) -Method POST  -body $jsonFields -session $webSessionTarget -Headers $updateHeaders 
       # //$apiUrl = "$($siteUrl)_api/web/GetFileByServerRelativeUrl('$($siteRelativeUrl)Pages/$($outlet)/$($fileName)')/checkin(comment='bulk upload',checkintype=1)"
        #$fieldsUpdated =  Invoke-RestMethodRetry -Url (get-apiurl $apiUrl) -Method POST  -body {} -session $webSessionTarget -Headers $updateHeaders 

        $processed++
        if($processed % 20 -eq 0)
        {
            write-host "$processed $outlet $(get-date)" 
        }
}

function Get-LoremIpsum()
{
[xml]$w = (new-object net.webclient).DownloadString("http://www.lipsum.com/feed/xml?amount=20&what=paras&start=yes&quot;")
#text output is in the following
$content = $w.feed.lipsum;#//.Replace("`n","<br>");

return $content
}

cls


$tenantUrl = "https://auspost.sharepoint.com"
$siteRelativeUrl= "/sites/popsupport/news/"

#$tenantUrl = "https://australiapost.sharepoint.com"
#$siteRelativeUrl= "/sites/PEP/news/"

#$tenantUrl = "https://auspost.sharepoint.com"
#$siteRelativeUrl= "/sites/popsupport/"
$targetSiteUrl =$("$($tenantUrl)$siteRelativeUrl")
Connect-SPOnline $targetSiteUrl | out-null

$rawFile= (get-content "C:\Code\Office365-Scripts\SharePoint\Publishing\BulkUpdateSample.aspx"-Raw)
#$publishingContent = Get-LoremIpsum 
#$expression = '(?<=<mso:PublishingPageContent msdt:dt="string">)(.*?)(?=</mso:PublishingPageContent>)'
#$rawFile = [RegEx]::Replace($rawFile,$expression,$publishingContent)  
#$expression = '(?<=<title>)(.*?)(?=</title>)'
#$rawFile = [RegEx]::Replace($rawFile,$expression,$publishingContent)  

#$targetRelativeUrl ="$tenantUrl/sites/PEP"
#$targetSiteUrl = "https://australiapost.sharepoint.com$($targetRelativeUrl)"
#$rawFile = $rawFile.Replace("https://kasa.sharepoint.com/sites/AusPostPEPCI/", $targetSiteUrl)
#$rawFile = $rawFile.Replace("/sites/AusPostPEPCI/", "$siteRelativeUrl")

$rawFile = $rawFile.Replace("https://australiapost.sharepoint.com/sites/PEP/", "https://auspost.sharepoint.com/sites/popsupport/")
$rawFile = $rawFile.Replace("/sites/PEP/", "$siteRelativeUrl")

$outlet = "Published"

for($i=0;$i -lt 200;$i++){
$publishingContent = Get-LoremIpsum 

$expression = '(?<=<mso:PublishingPageContent msdt:dt="string">)(.*?)(?=</mso:PublishingPageContent>)'
$newFile = [RegEx]::Replace($rawFile,$expression,$publishingContent)  

$fileName = "BulkUpload$i.aspx"

$expression = '(?<=<title>)(.*?)(?=</title>)'
$newTitle = "bulk upload $i"
$newFile = [RegEx]::Replace($newFile,$expression,$newTitle)  

$fileName = "BulkUpload$i.aspx"

#$tenantUrl = "https://australiapost.sharepoint.com"
#$siteRelativeUrl= "/sites/PEP/news/"
$targetSiteUrl =$("$($tenantUrl)$siteRelativeUrl")

Create-POPContent -siteUrl $targetSiteUrl -siteRelativeUrl $siteRelativeUrl -content $newFile -fileName $fileName
}