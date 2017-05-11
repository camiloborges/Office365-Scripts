Import-Module WebAdministration;Get-ChildItem -Path IIS:\AppPools\ | 
Select-Object name, @{e={$_.processModel.username};l="username"}, @{e={$_.processModel.password};l="password"}, @{e={$_.processModel.identityType};l="identityType"} |
format-table -AutoSize