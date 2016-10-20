<#
Wipe out all content in an Exchange Online mailbox.

All environments perform differently. Please test this code before using it
in production.

THIS CODE AND ANY ASSOCIATED INFORMATION ARE PROVIDED “AS IS” WITHOUT WARRANTY 
OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE 
IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK OF USE, INABILITY TO USE, OR RESULTS FROM THE USE OF 
THIS CODE REMAINS WITH THE USER.

Author: Aaron Guilmette
		aaron.guilmette@microsoft.com
#>

<#
.SYNOPSIS
Remove all contents in an Office 365 / Exchnge Online mailbox.

.DESCRIPTION
This script will attempt to remove all content in the specified Exchange Online
mailbox.

.EXAMPLE
.\Wipe-EXOMailbox.ps1 -Identity testuser@contoso.com
Remove mailbox contents for testuser@contoso.com

.EXAMPLE
.\Wipe-EXOMailbox.ps1 -Identity testuser@contoso.com -Credential $Cred
Remove mailbox contents for testuser@contoso.com using stored credential $cred

.LINK
For an updated version of this script, check the Technet
Gallery at https://gallery.technet.microsoft.com/Wipe-Exchange-Online-331ab4f4
#>
Param(
	[Parameter(Mandatory=$true,HelpMessage="Enter UPN of mailbox user")]
		[string]$Identity,
	[Parameter(Mandatory=$true,HelpMessage="Enter Admin Credential with ApplicationImpersonation and Mailbox Import Export roles")]
		[System.Management.Automation.CredentialAttribute()]$Credential = (Get-Credential)
	)

# Locating EWS Managed API and loading
Write-Host -Fore Yellow "Locating EWS installation ..."
If (Test-Path 'C:\Program Files\Microsoft\Exchange\Web Services\2.2\Microsoft.Exchange.WebServices.dll')
	{
		Write-Host -ForegroundColor Green "Found Exchange Web Services DLL."
		$WebServicesDLL = "C:\Program Files\Microsoft\Exchange\Web Services\2.2\Microsoft.Exchange.WebServices.dll"
		Import-Module $WebServicesDLL
	}
ElseIf
	( $filename = Get-ChildItem 'C:\Program Files' -Recurse -ea silentlycontinue | where { $_.name -eq 'Microsoft.Exchange.WebServices.dll' })
	{
		Write-Host -ForegroundColor Green "Found Exchange Web Services DLL at $filename.FullName."
		$WebServicesDLL = $filename.FullName
		Import-Module $WebServicesDLL
	}
ElseIf
	(!(Test-Path 'C:\Program Files\Microsoft\Exchange\Web Services\2.2\Microsoft.Exchange.WebServices.dll'))
	{
		Write-Host -ForegroundColor Yellow "This requires the Exchange Web Services Managed API. Attempting to download and install."
		wget http://download.microsoft.com/download/8/9/9/899EEF2C-55ED-4C66-9613-EE808FCF861C/EwsManagedApi.msi -OutFile ./EwsManagedApi.msi
		msiexec /i EwsManagedApi.msi /qb
		Sleep 60
		If (Test-Path 'C:\Program Files\Microsoft\Exchange\Web Services\2.2\Microsoft.Exchange.WebServices.dll')
		{
			Write-Host -ForegroundColor Green "Found Exchange Web Services DLL."
			$WebServicesDLL = "C:\Program Files\Microsoft\Exchange\Web Services\2.2\Microsoft.Exchange.WebServices.dll"
			Import-Module $WebServicesDLL
		}
		Else
			{ 
				Write-Host -ForegroundColor Red "Please download the Exchange Web Services API and try again."
				Break
			}
	}

If (!($Credential))
	{
	$Credential = Get-Credential -Message "Enter your Office 365 User Global Admin User Credential with the Mailbox Import/Export Role"
	}

If (!($Identity))
	{
	$Identity = Read-Host "Enter user mailbox to wipe"
	}

# Check Management Roles
$ManagementRoles = Get-ManagementRoleAssignment -AssignmentMethod Direct -RoleAssignee $Credential.UserName
If ($ManagementRoles -match "ApplicationImpersonation" -and $ManagementRoles -match "Mailbox Import Export")
	{
	Write-Host -ForegroundColor Green "Correct management roles are granted."
	}
Else
	{
	If (!($ManagementRoles -match "Mailbox Import Export"))
		{
		Write-Host -ForegroundColor Yellow "You do not currently have the Mailbox Import Export Role."
		New-ManagementRoleAssignment -User $Credential.UserName -Role "Mailbox Import Export" 
		}
	If (!($ManagementRoles -match "ApplicationImpersonation"))
		{
		Write-Host -ForegroundColor Yellow "You do not currently have the ApplicationImpersonation Role."
		New-ManagementRoleAssignment -User $Credential.UserName -Role "ApplicationImpersonation"
		}
	Write-Host -ForegroundColor Yellow "We have attempted to grant you the required roles. Please log out of your Office 365 session, log back in, and try again."
	Break
	}
	
Write-Host -Fore Green "Content from $Identity will be erased."

# Grant full mailbox access
Write-Host -Fore DarkGreen "   Granting mailbox access for $Identity to $($Credential.UserName) ...."
Add-MailboxPermission -Identity $Identity -User $Credential.UserName -AccessRights FullAccess -Automapping $false

## Create Exchange Service Object
Write-Host -ForegroundColor DarkGreen "   Connecting to AutoDiscover endpoint for $($Credential.UserName)."
$ExchangeVersion = [Microsoft.Exchange.WebServices.Data.ExchangeVersion]::Exchange2013 
$Service = New-Object Microsoft.Exchange.WebServices.Data.ExchangeService($ExchangeVersion)
$creds = New-Object System.Net.NetworkCredential($Credential.UserName.ToString(),$Credential.GetNetworkCredential().password.ToString())
$Service.Credentials = $creds 
$Service.AutodiscoverUrl($Credential.Username, {$true})

Write-Host -Fore Yellow "   Purging folders ..."
$Service.ImpersonatedUserId = New-Object Microsoft.Exchange.WebServices.Data.ImpersonatedUserId([Microsoft.Exchange.WebServices.Data.ConnectingIdType]::SmtpAddress,$Identity)
$Root = [Microsoft.Exchange.WebServices.Data.Folder]::Bind($service,[Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::Root)

$FolderView = New-Object Microsoft.Exchange.WebServices.Data.FolderView(1000)
$FolderView.Traversal = [Microsoft.Exchange.WebServices.Data.FolderTraversal]::Deep

$FolderList = $Root.FindFolders($FolderView)

ForEach ($Folder in $FolderList.Folders) 
	{ 
		Write-Host -Fore DarkYellow "     Processing $($Folder.DisplayName) ..."
		Try {
			$Folder.delete([Microsoft.Exchange.WebServices.Data.DeleteMode]::HardDelete) 
			}
		Catch
			{
			[System.Exception] | Out-Null
			}
		Finally
			{
			}
	}

# Deleting remaining inbox content via Search-Mailbox cmdlet
Write-Host -Fore Yellow "   Purging content ..."
Search-Mailbox -Identity $Identity -DeleteContent -Force