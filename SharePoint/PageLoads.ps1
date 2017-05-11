function test-Url($webSession,$url){
try{
$startTime = Get-Date
$webRequest = Invoke-WebRequest -Uri $url -Method Get -WebSession $webSession

$stopTime = Get-Date
  $object = New-Object PSObject -Property @{
                Url           = $url
                Duration      = (NEW-TIMESPAN –Start $startTime –End $stopTime).TotalMilliseconds
                StartTime     = $startTime
                EndTime       = $stopTime
                SPRequestDuration = $webRequest.Headers.SPRequestDuration
                SPRequestGuid = $webRequest.Headers.SPRequestGuid
            } | Select-Object Url, Duration, StartTime, EndTime  # to ensure order
        
        $object
        }catch{
        write-host $_
        }
}

function CallSites($url,$webSession){
write-host (get-date)
write-host $url 
$current = 0
    while($current -lt $executions)
    {
        $current = $current+1 
        test-Url $webSession $url
        sleep -Milliseconds 1000 #reduce when doing several hits
    }

}
$path = $PSScriptRoot
set-location $path
get-location
# Connect to SharePoint Online
$targetSite = "https://silkcontractlogistics.sharepoint.com"
$targetSiteUri = [System.Uri]$targetSite

Connect-SPOnline $targetSite

# Retrieve the client credentials and the related Authentication Cookies
$context = (Get-SPOWeb).Context
$credentials = $context.Credentials

$authenticationCookies = $credentials.GetAuthenticationCookie($targetSiteUri, $true)

# Set the Authentication Cookies and the Accept HTTP Header
$webSession = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$webSession.Cookies.SetCookies($targetSiteUri, $authenticationCookies)
#$webSession.Headers.Add(“Accept”, “application/json;odata=verbose”)
$webSession.UserAgent = "User-Agent:Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.103 Safari/537.36"
$executions = 3

$data = CallSites "https://.sharepoint.com/pages/home.aspx" $webSession

$progressPreference = 'silentlyContinue'    
$current = 0
    while($current -lt 100)
    {
        $current = $current+1 
        $data += CallSites "https://.sharepoint.com/pages/home.aspx" $webSession
        $data += CallSites "https://.sharepoint.com" $webSession
        $data += CallSites "https://.sharepoint.com/enterprise" $webSession
        $data += CallSites "https://.sharepoint.com/enterprise/Documents/Forms/Forms.aspx" $webSession
        $data += CallSites "https://.sharepoint.com/enterprise/Documents/Forms/Policies.aspx" $webSession

        sleep -Milliseconds 5000 #reduce when doing several hits
    }

$data | Export-CSV ("./performance" + (get-date).ToString("yyyyMMddHHmm") + ".csv")
$progressPreference = 'Continue'            