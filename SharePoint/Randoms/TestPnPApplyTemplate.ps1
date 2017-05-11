set-location C:\Users\CamiloBorges_k6a\Source\Repos\AusPost-PEP\PEPPA.SPInfrastructure\TemplateFiles\News

Connect-PnPOnline https://kasa.sharepoint.com/sites/AusPostPEPTemplate

Apply-PnPProvisioningTemplate (resolve-path .\03_NewsLists_Template.xml).Path -Verbose 



Get-PnPField -Identity "f247ed87-f425-4249-af8d-984c7a0dcb60"