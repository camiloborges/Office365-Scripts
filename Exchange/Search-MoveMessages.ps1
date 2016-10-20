#set-location "C:\Users\CamiloBorges\OneDrive for Business\Fusion\Scripts"
# Fish*Five*81
#Import-Module "C:\Users\CamiloBorges\OneDrive for Business\Fusion\Scripts\MoveOSCEXOEmailMessage\MoveOSCEXOEmailMessage.psm1"
Connect-OSCEXOWebService -Credential (Get-Credential richie@yokedesign.com.au)

Search-OSCEXOEmailMessage -StartDate "2012/10/01" -EndDate "2012/12/31" | Move-OSCEXOEmailMessage -DestinationFolderDisplayName "2012"