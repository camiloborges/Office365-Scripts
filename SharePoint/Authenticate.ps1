
Import-Module 'C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.UserProfiles.dll'
. .\Includes.ps1
#Mysite URL
$site = 'https://Domain-my.sharepoint.com/'

#Admin User Principal Name
$admin = 'Admin@Domain.OnMicrosoft.Com'

#Get Password as secure String
$password = Read-Host 'Enter Password' -AsSecureString

#Get the Client Context and Bind the Site Collection
$context = New-Object Microsoft.SharePoint.Client.ClientContext($site)

#Authenticate
$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($admin , $password)
$context.Credentials = $credentials