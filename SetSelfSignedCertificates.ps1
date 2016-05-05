$creds = Get-Credential "camilob@gmail.com"
Login-AzureRmAccount # -SubscriptionName "Visual Studio Enterprise with MSDN"
Select-AzureRmSubscription -SubscriptionName "Visual Studio Enterprise with MSDN"
$resourceGroupName = "xSharePoint"
$serverName =($env:COMPUTERNAME).ToLower()
$vm = GEt-AzureRMVM  -NAme $serverName  -ResourceGroupName $resourceGroupName

$publicIPAddress = ($vm| Get-AzureRmPublicIpAddress)
$DNSNAme = $publicIPAddress.DnsSettings.FQDN
$DNSName 
$certificate = (Get-ChildItem cert:\LocalMachine\My -DnsName $DNSName )
if($certificate -eq $null){
    $certificate = (New-SelfSignedCertificate -DnsName $DNSName -CertStoreLocation Cert:\LocalMachine\My)
}
 $thumbprint = $certificate.Thumbprint
$certificate | Import-Certificate -CertStoreLocation cert:\LocalMachine\Root 
Export-Certificate -Cert $certificate -FilePath C:\Temp\SelfSignedCert.cer -Type CERT
Sleep -Seconds 1
Import-Certificate -FilePath: c:\temp\SelfSignedCert.cer -CertStoreLocation cert:\LocalMachine\Root   

New-AzureRmAutomationCertificate -AutomationAccountName "xSharePointAutomation"  -ResourceGroupName "xSharepoint" -Name $serverName  -Path C:\Temp\SelfSignedCert.cer
# Run WinRM configuration on command line. DNS name set to computer hostname, you may wish to use a FQDN
try{
    $cmd = "winrm delete winrm/config/Listener?Address=*+Transport=HTTPS "
    cmd.exe /C $cmd
}catch{
#ignores if there is an issue
}
 
$cmd = "winrm create winrm/config/Listener?Address=*+Transport=HTTPS @{Hostname=""$DNSName""; CertificateThumbprint=""$thumbprint""}"
cmd.exe /C $cmd

 