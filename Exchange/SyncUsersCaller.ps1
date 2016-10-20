set-Location "C:\Users\CamiloBorges\OneDrive for Business\Fusion"
powershell.exe -Command ". (resolve-path .\SyncUsersAsContacts.ps1).Path -sourceTenant 'https://kasa.sharepoint.com' -targetTenant 'https://fivep.sharepoint.com' -company 'Yoke Design'"

  
powershell.exe -Command ". (resolve-path .\SyncUsersAsContacts.ps1).Path -sourceTenant 'https://fivep.sharepoint.com' -targetTenant 'https://kasa.sharepoint.com' -company 'FiveP Australia'"