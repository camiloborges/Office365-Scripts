<#
The sample scripts are not supported under any Microsoft standard support 
program or service. The sample scripts are provided AS IS without warranty  
of any kind. Microsoft further disclaims all implied warranties including,  
without limitation, any implied warranties of merchantability or of fitness for 
a particular purpose. The entire risk arising out of the use or performance of  
the sample scripts and documentation remains with you. In no event shall 
Microsoft, its authors, or anyone else involved in the creation, production, or 
delivery of the scripts be liable for any damages whatsoever (including, 
without limitation, damages for loss of business profits, business interruption, 
loss of business information, or other pecuniary loss) arising out of the use 
of or inability to use the sample scripts or documentation, even if Microsoft 
has been advised of the possibility of such damages.
#>

#requires -Version 2

#Import Localized Data
Import-LocalizedData -BindingVariable Messages
#Load .NET Assembly for Windows PowerShell V2
Add-Type -AssemblyName System.Core

$webSvcInstallDirRegKey = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Exchange\Web Services\2.2" -PSProperty "Install Directory" -ErrorAction:SilentlyContinue
if ($webSvcInstallDirRegKey -ne $null) {
	$moduleFilePath = $webSvcInstallDirRegKey.'Install Directory' + 'Microsoft.Exchange.WebServices.dll'
	Import-Module $moduleFilePath
} else {
	$errorMsg = $Messages.InstallExWebSvcModule
	throw $errorMsg
}

Function New-OSCPSCustomErrorRecord
{
	#This function is used to create a PowerShell ErrorRecord
	[CmdletBinding()]
	Param
	(
		[Parameter(Mandatory=$true,Position=1)][String]$ExceptionString,
		[Parameter(Mandatory=$true,Position=2)][String]$ErrorID,
		[Parameter(Mandatory=$true,Position=3)][System.Management.Automation.ErrorCategory]$ErrorCategory,
		[Parameter(Mandatory=$true,Position=4)][PSObject]$TargetObject
	)
	Process
	{
		$exception = New-Object System.Management.Automation.RuntimeException($ExceptionString)
		$customError = New-Object System.Management.Automation.ErrorRecord($exception,$ErrorID,$ErrorCategory,$TargetObject)
		return $customError
	}
}

Function Connect-OSCEXOWebService
{
	#.EXTERNALHELP Connect-OSCEXOWebService-Help.xml

    [cmdletbinding()]
	Param
	(
		#Define parameters
		[Parameter(Mandatory=$true,Position=1)]
		[System.Management.Automation.PSCredential]$Credential,
		[Parameter(Mandatory=$false,Position=2)]
		[Microsoft.Exchange.WebServices.Data.ExchangeVersion]$ExchangeVersion="Exchange2010_SP2",
		[Parameter(Mandatory=$false,Position=3)]
		[string]$TimeZoneStandardName,
		[Parameter(Mandatory=$false)]
		[switch]$Force
	)
	Process
	{
        #Get specific time zone info
        if (-not [System.String]::IsNullOrEmpty($TimeZoneStandardName)) {
            Try
            {
                $tzInfo = [System.TimeZoneInfo]::FindSystemTimeZoneById($TimeZoneStandardName)
            }
            Catch
            {
                $PSCmdlet.ThrowTerminatingError($_)
            }
        } else {
            $tzInfo = $null
        }

		#Create the callback to validate the redirection URL.
		$validateRedirectionUrlCallback = {
            param ([string]$Url)
			if ($Url -eq "https://autodiscover-s.outlook.com/autodiscover/autodiscover.xml") {
            	return $true
			} else {
				return $false
			}
        }	
	
		#Try to get exchange service object from global scope
		$existingExSvcVar = (Get-Variable -Name exService -Scope Global -ErrorAction:SilentlyContinue) -ne $null
		
		#Establish the connection to Exchange Web Service
		if ((-not $existingExSvcVar) -or $Force) {
			$verboseMsg = $Messages.EstablishConnection
			$PSCmdlet.WriteVerbose($verboseMsg)
            if ($tzInfo -ne $null) {
                $exService = New-Object Microsoft.Exchange.WebServices.Data.ExchangeService(`
				    		 [Microsoft.Exchange.WebServices.Data.ExchangeVersion]::$ExchangeVersion,$tzInfo)			
            } else {
                $exService = New-Object Microsoft.Exchange.WebServices.Data.ExchangeService(`
				    		 [Microsoft.Exchange.WebServices.Data.ExchangeVersion]::$ExchangeVersion)
            }
			
			#Set network credential
			$userName = $Credential.UserName
			$exService.Credentials = $Credential.GetNetworkCredential()
			Try
			{
				#Set the URL by using Autodiscover
				$exService.AutodiscoverUrl($userName,$validateRedirectionUrlCallback)
				$verboseMsg = $Messages.SaveExWebSvcVariable
				$PSCmdlet.WriteVerbose($verboseMsg)
				Set-Variable -Name exService -Value $exService -Scope Global -Force
			}
			Catch [Microsoft.Exchange.WebServices.Autodiscover.AutodiscoverRemoteException]
			{
				$PSCmdlet.ThrowTerminatingError($_)
			}
			Catch
			{
				$PSCmdlet.ThrowTerminatingError($_)
			}
		} else {
			$verboseMsg = $Messages.FindExWebSvcVariable
            $verboseMsg = $verboseMsg -f $exService.Credentials.Credentials.UserName
			$PSCmdlet.WriteVerbose($verboseMsg)            
		}
	}
}

Function Search-OSCEXOEmailMessage
{
	#.EXTERNALHELP Search-OSCEXOEmailMessage-Help.xml

	[cmdletbinding()]
	Param
	(
		#Define parameters
		[Parameter(Mandatory=$false,Position=1)]
        [ValidateSet("Inbox","SentItems","DeletedItems")]
		[string]$WellKnownFolderName="Inbox",		
		[Parameter(Mandatory=$false,Position=2)]
		[datetime]$StartDate=(Get-Date).AddDays(-30),
		[Parameter(Mandatory=$false,Position=3)]
		[datetime]$EndDate=(Get-Date),
		[Parameter(Mandatory=$false,Position=4)]
		[string]$Subject,
		[Parameter(Mandatory=$false,Position=5)]
		[string]$From,
		[Parameter(Mandatory=$false,Position=6)]
		[string]$DisplayTo,
		[Parameter(Mandatory=$false,Position=7)]
		[string]$DisplayCc,
		[Parameter(Mandatory=$false,Position=8)]
		[int]$PageSize=100
	)
	Begin
	{
        #Verify the existence of exchange service object
        if ($exService -eq $null) {
			$errorMsg = $Messages.RequireConnection
			$customError = New-OSCPSCustomErrorRecord `
			-ExceptionString $errorMsg `
			-ErrorCategory NotSpecified -ErrorID 1 -TargetObject $PSCmdlet
			$PSCmdlet.ThrowTerminatingError($customError)
        }
	}
	Process
	{   
        #Define base property sets that are used as the base for custom property sets
        $itemPropertySet = New-Object Microsoft.Exchange.WebServices.Data.PropertySet(`
                       	   [Microsoft.Exchange.WebServices.Data.BasePropertySet]::IdOnly)

		#Define FolderView and ItemView
		$itemView = New-Object Microsoft.Exchange.WebServices.Data.ItemView($PageSize)
		$itemView.PropertySet = $itemPropertySet
               
        #Prepare search filter for searching emails
        $searchFilterCollection = New-Object Microsoft.Exchange.WebServices.Data.SearchFilter+SearchFilterCollection(`
                                  [Microsoft.Exchange.WebServices.Data.LogicalOperator]::And)
		$startDateFilter = New-Object Microsoft.Exchange.WebServices.Data.SearchFilter+IsGreaterThanOrEqualTo(`
						   [Microsoft.Exchange.WebServices.Data.EmailMessageSchema]::DateTimeCreated,$StartDate)
		$endDateFilter = New-Object Microsoft.Exchange.WebServices.Data.SearchFilter+IsLessThanOrEqualTo(`
						 [Microsoft.Exchange.WebServices.Data.EmailMessageSchema]::DateTimeCreated,$endDate)
		$itemClassFilter = New-Object Microsoft.Exchange.WebServices.Data.SearchFilter+IsEqualTo(`
						   [Microsoft.Exchange.WebServices.Data.EmailMessageSchema]::ItemClass,"IPM.Note")						 
		$searchFilterCollection.Add($startDateFilter)
		$searchFilterCollection.Add($endDateFilter)
		$searchFilterCollection.Add($itemClassFilter)
		
        if (-not [System.String]::IsNullOrEmpty($Subject)) {
            $subjectFilter = New-Object Microsoft.Exchange.WebServices.Data.SearchFilter+ContainsSubString(`
                             [Microsoft.Exchange.WebServices.Data.EmailMessageSchema]::Subject,$Subject)  
            $searchFilterCollection.Add($subjectFilter)
        }

        if (-not [System.String]::IsNullOrEmpty($From)) {
            $fromFilter = New-Object Microsoft.Exchange.WebServices.Data.SearchFilter+ContainsSubString(`
                             [Microsoft.Exchange.WebServices.Data.EmailMessageSchema]::From,$From)  
            $searchFilterCollection.Add($fromFilter)
        }

        if (-not [System.String]::IsNullOrEmpty($DisplayTo)) {
            $displayToFilter = New-Object Microsoft.Exchange.WebServices.Data.SearchFilter+ContainsSubString(`
                             [Microsoft.Exchange.WebServices.Data.EmailMessageSchema]::DisplayTo,$DisplayTo)  
            $searchFilterCollection.Add($displayToFilter)
        }

        if (-not [System.String]::IsNullOrEmpty($DisplayCc)) {
            $displayCcFilter = New-Object Microsoft.Exchange.WebServices.Data.SearchFilter+ContainsSubString(`
                             [Microsoft.Exchange.WebServices.Data.EmailMessageSchema]::DisplayCc,$DisplayCc)  
            $searchFilterCollection.Add($displayCcFilter)
        }

        $parentFolder = [Microsoft.Exchange.WebServices.Data.Folder]::Bind($exService,`
                        [Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::$WellKnownFolderName)
		
        do
        {
            $findResults = $parentFolder.FindItems($searchFilterCollection,$itemView)
            foreach ($findResult in $findResults) {
                $PSCmdlet.WriteObject($findResult.Id)
            }
        } while ($findResults.MoreAvailable)
        
        $verboseMsg = $Messages.FoundEmails
        $verboseMsg = $verboseMsg -f $findResults.TotalCount
        $PSCmdlet.WriteVerbose($verboseMsg)

        if ($findResults.TotalCount -eq 0) {
            return $null
        }
	}
	End {}
}

Function Get-OSCEXOMailFolder
{
	[cmdletbinding()]
	Param
	(
		#Define parameters
		[Parameter(Mandatory=$true,Position=1)]
		[string]$DisplayName
	)
	Begin
	{
        #Verify the existence of exchange service object
        if ($exService -eq $null) {
			$errorMsg = $Messages.RequireConnection
			$customError = New-OSCPSCustomErrorRecord `
			-ExceptionString $errorMsg `
			-ErrorCategory NotSpecified -ErrorID 1 -TargetObject $PSCmdlet
			$PSCmdlet.ThrowTerminatingError($customError)
        }
	}
	Process
	{   
        #Define the view settings in a folder search operation.
        $folderView = New-Object Microsoft.Exchange.WebServices.Data.FolderView(100)
        $folderView.Traversal = [Microsoft.Exchange.WebServices.Data.FolderTraversal]::Deep

        #Bind Default Root Folder (Top of Information Store)
        $rootFolder = [Microsoft.Exchange.WebServices.Data.Folder]::Bind(`
                         $exService,[Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::Root)
        
        #Prepare search filter to find folder with specific display name
        $searchFilter = New-Object Microsoft.Exchange.WebServices.Data.SearchFilter+IsEqualTo(`
						[Microsoft.Exchange.WebServices.Data.FolderSchema]::DisplayName,$DisplayName)
        
        #Begin to find folders
        do
        {
            $findResults = $rootFolder.FindFolders($searchFilter,$folderView)
        } while ($findResults.MoreAvailable)

        #Return message folder
        Switch ($findResults.TotalCount) {
            0 {
                return $null
            }
            1 {
                return $findResults.Id      
            }
            Default {
                $warningMsg = $Messages.FoundDupFolder
                $PSCmdlet.WriteWarning($warningMsg)
                return $null
            }
        }
	}
	End {}
}

Function Move-OSCEXOEmailMessage
{
	#.EXTERNALHELP Move-OSCEXOEmailMessage-Help.xml

	[cmdletbinding()]
	Param
	(
		#Define parameters
		[Parameter(Mandatory=$true,Position=1, ValueFromPipeline=$true)]
        [Microsoft.Exchange.WebServices.Data.ItemId]$MessageID,
		[Parameter(Mandatory=$true,Position=2)]
        [Microsoft.Exchange.WebServices.Data.ItemId]$DestinationFolderDisplayName
	)
	Begin
	{
        #Verify the existence of exchange service object
        if ($exService -eq $null) {
			$errorMsg = $Messages.RequireConnection
			$customError = New-OSCPSCustomErrorRecord `
			-ExceptionString $errorMsg `
			-ErrorCategory NotSpecified -ErrorID 1 -TargetObject $PSCmdlet
			$PSCmdlet.ThrowTerminatingError($customError)
        }

        #Get destination folder ID
        $destFolderID = Get-OSCEXOMailFolder -DisplayName $DestinationFolderDisplayName
        if ($destFolderID -eq $null) {
			$errorMsg = $Messages.CannotFindDestFolder
            $errorMsg = $errorMsg -f $DestinationFolderDisplayName
			$customError = New-OSCPSCustomErrorRecord `
			-ExceptionString $errorMsg `
			-ErrorCategory NotSpecified -ErrorID 1 -TargetObject $PSCmdlet
			$PSCmdlet.ThrowTerminatingError($customError)
        }
	}
	Process
	{
        Try
        {
            #Get email message
            $message = [Microsoft.Exchange.WebServices.Data.EmailMessage]::Bind($exService,$MessageID)

            $verboseMsg = $Messages.MoveEmailMsg
            $verboseMsg = $verboseMsg -f $message.Subject
            $PSCmdlet.WriteVerbose($verboseMsg)

            #Move email message to the destination folder
            $newMsg = $message.Move($destFolderID)
        }
        Catch
        {
            $PSCmdlet.WriteError($_)
        }
	}
	End {}
}

Export-ModuleMember -Function "Connect-OSCEXOWebService","Search-OSCEXOEmailMessage","Move-OSCEXOEmailMessage"