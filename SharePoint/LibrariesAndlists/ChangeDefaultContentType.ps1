no
#$creds = New-Object System.Management.Automation.PSCredential($User,(ConvertTo-SecureString $Pass -AsPlainText -Force))
#Set-PnPTraceLog -on -Level Debug

Connect-PnPOnline "https://kasa.sharepoint.com/sites/AusPostPEPCI/news/authoring"
Set-PnPDefaultContentTypeToList -list "Workflow Tasks" -ContentType "Workflow Task (SharePoint 2013)"


Connect-PnPOnline "https://kasa.sharepoint.com/sites/AusPostPEPCI/news/directauthoring"
Set-PnPDefaultContentTypeToList -list "Workflow Tasks" -ContentType "Workflow Task (SharePoint 2013)"

#Set-PnPDefaultContentTypeToList 