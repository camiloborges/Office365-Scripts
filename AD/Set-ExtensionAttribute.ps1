function GetAuthToken
{
       param
       (
              [Parameter(Mandatory=$true)]
              $TenantName
       )
       $adal = "${env:ProgramFiles(x86)}\Microsoft SDKs\Azure\PowerShell\ServiceManagement\Azure\Services\Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
       $adalforms = "${env:ProgramFiles(x86)}\Microsoft SDKs\Azure\PowerShell\ServiceManagement\Azure\Services\Microsoft.IdentityModel.Clients.ActiveDirectory.WindowsForms.dll"
       [System.Reflection.Assembly]::LoadFrom($adal) | Out-Null
       [System.Reflection.Assembly]::LoadFrom($adalforms) | Out-Null
       $clientId = "1950a258-227b-4e31-a9cf-717495945fc2" 
       $redirectUri = "urn:ietf:wg:oauth:2.0:oob"
       $resourceAppIdURI = "https://graph.windows.net"
       $authority = "https://login.windows.net/$TenantName"
       $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority
       $authResult = $authContext.AcquireToken($resourceAppIdURI, $clientId,$redirectUri, "Always")
       return $authResult
}

$tenant = ”kasa.onmicrosoft.com” 
$token = GetAuthToken -TenantName $tenant
# Building Rest Api header with authorization token
$authHeader = @{
   'Content-Type'='application\json'
   'Authorization'=$token.CreateAuthorizationHeader()
}

<#

$resource = "tenantDetails"
$uri = "https://graph.windows.net/$tenant/$($resource)?api-version=1.6"
$tenantInfo = (Invoke-RestMethod -Uri $uri –Headers $authHeader –Method Get –Verbose).value
$tenantInfo

#>
$resource = "users"
$uri = "https://graph.windows.net/$tenant/$($resource)?api-version=1.6`&`$filter=startswith(displayName,'Paul Culbert')"
$users = (Invoke-RestMethod -Uri $uri –Headers $authHeader –Method Get –Verbose).value 
$users | select userPrincipalName, displayName
#>
#$photoUri = "https://graph.windows.net/$tenant/users/mayura.edirisinghe@open.edu.au/thumbnailPhoto?api-version=1.6" 
#$photo = Invoke-RestMethod -Uri $photoUri –Headers $authHeader –Method Get –Verbose -OutFile "c:\temp\mayura.jpg"

#$photoUri = "https://graph.windows.net/$tenant/users/thomas.luu@open.edu.au/thumbnailPhoto?api-version=1.6" 
#$photo = Invoke-RestMethod -Uri $photoUri –Headers $authHeader –Method Get –Verbose  -OutFile "c:\temp\thomas.jpg"


$photoUri = "https://graph.windows.net/$tenant/users/FivePAdmin@open.edu.au/thumbnailPhoto?api-version=1.6" 
$photo = Invoke-RestMethod -Uri $photoUri –Headers $authHeader –Method PUT –Verbose  -InFile "c:\temp\thomas.jpg" -ContentType 'multipart/form-data' 


$photoUri = "https://graph.windows.net/$tenant/users/FivePAdmin@open.edu.au/thumbnailPhoto?api-version=1.6" 
$photo = Invoke-RestMethod -Uri $photoUri –Headers $authHeader –Method Get –Verbose  -OutFile "c:\temp\fivepAdmin.jpg"

-ContentType 'multipart/form-data'
break



Connect-PnPOnline
Get-PnPUserProfileProperty  -Account 