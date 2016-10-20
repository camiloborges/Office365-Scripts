if($currentHTTPS = (Get-ChildItem WSMan:\Localhost\listener | Where -Property Keys -eq "Transport=HTTPS" ))
{

}

#| Remove-Item -Recurs
Set-Item WSMan:\localhost\Service\EnableCompatibilityHttpsListener -Value true


$vmName = $env:COMPUTERNAME
$path =  $env:TEMP # (resolve-path .\).Path

$creds = Get-Credential
$server = $env:COMPUTERNAME

$certificate = Invoke-Command -ComputerName $server `
                            -ScriptBlock {
                                $certificate = (Get-ChildItem cert:\LocalMachine\My -DnsName "spfarm-ad2.australiasoutheast.cloudapp.azure.com")
                                if($certificate -eq $null){
                                    $certficate = (New-SelfSignedCertificate -DnsName $DNSName -CertStoreLocation Cert:\LocalMachine\My)
                                }
                                $thumbprint = $certficate.Thumbprint
                                $certficate | Import-Certificate -CertStoreLocation cert:\LocalMachine\Root 
                                return $certificate
                            } -Credential $creds

Set-WSManInstance -ResourceURI winrm/config/Listener `
                  -SelectorSet @{Address="*";Transport="HTTPS"} `
                  -ComputerName $server `
                  -ValueSet @{CertificateThumbprint=$certificate.Thumbprint}


$automationAccountName="xSharePointAutomation" 
$resourceGroupNAme ="xsharepoint"
$vmName = $env:COMPUTERNAME
$path =  $env:TEMP # (resolve-path .\).Path
Login-AzureRmAccount
Select-AzureRmSubscription -SubscriptionName "Visual Studio Enterprise with MSDN"

$vm = GEt-AzureRMVM -ResourceGroupName $resourceGroupName -Name $vmName

if($publicAddress = $vm | Get-AzureRmPublicIpAddress)
{
    $dnsName =  $publicAddress.DnsSettings.FQDN
    $DNSName 
    $certificate = (Get-ChildItem cert:\LocalMachine\My -DnsName "spfarm-ad2.australiasoutheast.cloudapp.azure.com")
    if($certificate -eq $null){
        $certficate = (New-SelfSignedCertificate -DnsName $DNSName -CertStoreLocation Cert:\LocalMachine\My)
    }

    $thumbprint = $certficate.Thumbprint
    $certficate | Import-Certificate -CertStoreLocation cert:\LocalMachine\Root 

    # Run WinRM configuration on command line. DNS name set to computer hostname, you may wish to use a FQDN
    &"winrm.cmd " -p "delete" "winrm/config/Listener?Address=Address+Transport=HTTPS"
    # | Tee-Object -Variable scriptOutput | Out-Null

    &"winrm" -p create 'winrm/config/Listener?Address=*+Transport=HTTPS @{Hostname="' + $DNSName + '"; CertificateThumbprint="' + $thumbprint '"}'
    

    $cmd = "winrm create winrm/config/Listener?Address=*+Transport=HTTPS @{Hostname=""$DNSName""; CertificateThumbprint=""$thumbprint""}"
    cmd.exe /C $cmd

     if(-not (     $certificate = (Get-ChildItem cert:\LocalMachine\My -DnsName "spfarm-sql2.australiasoutheast.cloudapp.azure.com"))){
        $certificate = (New-SelfSignedCertificate -DnsName $DNSName -CertStoreLocation Cert:\LocalMachine\My)
    
    }
    $thumbprint = $certificate.Thumbprint
    $certPath =  "$path\SelfSignedCert.pfx"
    Export-Certificate -Cert $certificate -FilePath $certPath -Type CERT -Force -Confirm:$false |Out-Null
    Import-Certificate  -FilePath: $certPath -CertStoreLocation cert:\LocalMachine\Root 
    New-AzureRmAutomationCertificate -AutomationAccountName $automationAccountName  -ResourceGroupName $resourceGroupNAme -Name $vmName -Path $certPath
}