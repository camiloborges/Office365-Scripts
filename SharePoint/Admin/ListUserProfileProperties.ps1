Add-Type -Path "C:\Program Files\WindowsPowerShell\Modules\SharePointPnPPowerShellOnline\2.5.1606.3\Microsoft.SharePoint.Client.dll" 
#Add-Type -Path "C:\Program Files\WindowsPowerShell\Modules\SharePointPnPPowerShellOnline\2.5.1606.3\Microsoft.SharePoint.Client.dll" 
Import-Module 'C:\Program Files\WindowsPowerShell\Modules\SharePointPnPPowerShellOnline\2.5.1606.3\Microsoft.SharePoint.Client.UserProfiles.dll'

#Mysite URL
$site = 'https://commonequityhousinglimited-my.sharepoint.com/'

#Admin User Principal Name
$admin = '5p@cehl.com.au'
#5p@cehl.com.au

#Get Password as secure String
$password = Read-Host 'Enter Password' -AsSecureString

#Get the Client Context and Bind the Site Collection
$context = New-Object Microsoft.SharePoint.Client.ClientContext($site)

#Authenticate
$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($admin , $password)
$context.Credentials = $credentials

Connect-MsolService  # -Credential $credentials
$users = Get-MsolUser

#Create an Object [People Manager] to retrieve profile information
$people = New-Object Microsoft.SharePoint.Client.UserProfiles.PeopleManager($context)
$collection = @()
Foreach($user in $users)
{
                   
    $userprofile = $people.GetPropertiesFor("i:0#.f|membership|$($user.UserPrincipalName )")
    $context.Load($userprofile)
    $context.ExecuteQuery()
    if($userprofile.Email -ne $null)
    {
        $upp = $userprofile.UserProfileProperties

        $profileData = "" | Select "FirstName" , "LastName" , "WorkEmail" , "Title" , "Responsibility"
        $profileData.FirstName = $upp.FirstName
        $profileData.LastName = $upp.LastName
        $profileData.WorkEmail = $upp.WorkEmail
        $profileData.Responsibility = $upp.'SPS-Responsibility'
        $collection += $profileData

    }
}