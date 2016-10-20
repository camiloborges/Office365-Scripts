  $uri = 'https://spfarm-ad2.australiasoutheast.cloudapp.azure.com:5986/'
  $Creds = Get-Credential
  Invoke-Command  -ConnectionUri $uri  -credential  $Creds `
  -Command { 
        $os = Get-WmiObject win32_operatingsystem
       $uptime = (Get-Date) - ($os.ConvertToDateTime($os.lastbootuptime))
       return $uptime
   }

   #$so = New-PsSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck

   #Enter-PSSession -UseSSL -ComputerName "spfarm-ad2.australiasoutheast.cloudapp.azure.com" -Credential $Creds  -SessionOption $so 

