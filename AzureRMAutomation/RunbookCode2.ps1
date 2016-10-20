$GetRDPInfoBlock = {
	$TimeOut=15
    $Computer = $env:COMPUTERNAME
    $Started = Get-Date
	try{

           # quser /server:$Computer 2>&1 | Select-Object -Skip 1 
            #| ForEach-Object {
            #    $CurrentLine = $_.Trim() -Replace '\s+',' ' -Split '\s'
    $sessions =  quser /server:$Computer 2>&1 | Select-Object -Skip 1      # (. cmd.exe /c query user )

	}catch{}
    try {
        quser /server:$Computer 2>&1 | Select-Object -Skip 1 | ForEach-Object {
            $CurrentLine = $_.Trim() -Replace '\s+',' ' -Split '\s'
            $HashProps = @{
                UserName = $CurrentLine[0]
                ComputerName = $Computer
            }

            try{
                # If session is disconnected different fields will be selected
                if ($CurrentLine[2] -eq 'Disc') {
                    $HashProps.SessionName = $null
                    $HashProps.Id = $CurrentLine[1]
                    $HashProps.State = $CurrentLine[2]
                    $HashProps.IdleTime = $CurrentLine[3]
                    $HashProps.LogonTime = $CurrentLine[4..6] -join ' '
                    $HashProps.LogonTime = $CurrentLine[4..($CurrentLine.GetUpperBound(0))] -join ' '                    try
                    {
                        $temp.LogonTime = Get-Date $($fields[5] + " " + $fields[6] + " " + $fields[7]) -ErrorAction stop
                    }
                    catch
                    {
                        $temp.LogonTime = ($fields[5] + " " + $fields[6] + " " + $fields[7]).trim()
                    }
                } else {
                    $HashProps.SessionName = $CurrentLine[1]
                    $HashProps.Id = $CurrentLine[2]
                    $HashProps.State = $CurrentLine[3]
                    $HashProps.IdleTime = $CurrentLine[4]
                    $HashProps.LogonTime = $CurrentLine[5..($CurrentLine.GetUpperBound(0))] -join ' '                }

                #quick function to handle minutes or hours:minutes
                function Convert-ShortIdle {
                    param($string)
                    if($string -match "\:"){
                        [timespan]$string
                    }
                    else{
					    try{
                        New-TimeSpan -Minutes $string
					    }catch{
						    Write-Verbose "Invalid String $string "
							    Write-Error "Invalid String $string "
						    New-TimeSpan -Minutes 1 
							
					    }
                    }
                }
                $string = $HashProps.idletime

                #to the left of + is days
                if($string -match "\+"){
                    $days = New-TimeSpan -days ($string -split "\+")[0]
                    $hourMin = Convert-ShortIdle ($string -split "\+")[1]
                    $HashProps.idletime = $days + $hourMin
                }
                #. means less than a minute
                elseif($string -like "." -or $string -like "none"){
                    $HashProps.idletime = [timespan]"0:00"
                }
                #hours and minutes
                else{
                    $HashProps.idletime = Convert-ShortIdle $string
                }
                #Output the result
                $HashProps
            }catch{
    <#                        New-Object -TypeName PSCustomObject -Property @{
                ComputerName = $Computer
                Error = $_.Exception.Message
            } | Select-Object -Property UserName,ComputerName,SessionName,Id,State,IdleTime,LogonTime,Error
            #>
            
            
            }
       }
    }catch{}
}

function Get-UpTime($servers, $uri, $creds)
{
	#-Cn $servers 
$result =  Invoke-Command  -ConnectionUri $uri  -credential  $Creds `
  -Command { 
        $os = Get-WmiObject win32_operatingsystem
       $uptime = (Get-Date) - ($os.ConvertToDateTime($os.lastbootuptime))
       return $uptime
   } -ErrorAction SilentlyContinue
return $result
}

function Get-RDPSessions( $uri, $creds)
{
$result =  Invoke-Command  -ConnectionUri $uri  -credential  $Creds `
  -Command $GetRDPInfoBlock -ErrorAction SilentlyContinue
return $result
}

$ADCreds = Get-AutomationPSCredential -Name 'ADAccount'
$subscriptionName =  Get-AutomationVariable -Name 'SubscriptionName' # "Visual Studio Enterprise with MSDN"
$resourceGroupName =  Get-AutomationVariable -Name 'ResourceGroupName' # "xsharepoint"

$subscriptionID = Get-AutomationVariable -Name 'SubscriptionID'
$azureCred = Get-AutomationPSCredential -Name 'AzureSubscriptionADAdmin'

Login-AzureRMAccount -Credential $azureCred  
Select-AzureRmSubscription -SubscriptionName $subscriptionName
$vms = GEt-AzureRMVM -ResourceGroupName $resourceGroupName
$nics = Get-AzureRmNetworkInterface  -ResourceGroupName $resourceGroupName

$currentState =	 $vms| %{
	$vm = $_
	$vmName = $_.Name
	$status = (Get-AzureRMVM -name $_.Name -ResourceGroupName $resourceGroupName -status )
	$PowerState = (get-culture).TextInfo.ToTitleCase(($status.statuses)[1].code.split("/")[1])
	if($PowerState-eq "running"){
        if($publicAddress = $vm | Get-AzureRmPublicIpAddress){
			$publicAddressID = $publicAddress.ID
	        $idEnd = $publicAddressID.SubString($publicAddressID.LastIndexOf("/")+1)
	     	#$publicAddress =    Get-AzureRmPublicIpAddress | ? {$_.ID -like "*$idEnd" }
	    	$vmFQDN =  $publicAddress.DnsSettings.FQDN
			if($vmFQDN -ne $null){
				$uri = "https://$($vmFQDN):5986/"
				$uptime = Get-UpTime( "spfarm-ad2.australiasoutheast.cloudapp.azure.com") $uri $ADCreds 
				$rdpSessions = Get-RDPSessions $uri $ADCreds 
				if($uptime -ne $null  ){
					@{
						"Name" = $vmName
						"Uptime" = $uptime
						"RDPSessions"= $rdpSessions
						"VM" = $vm 
					}
				}
			}
		}
	}
}
#$sessions = $currentState | %{$_.RDPSessions} 
$minumumLiveTime = [int] (Get-AutomationVariable -Name 'MinumumLiveTime') #10
$maximumIdleTime = [int] (Get-AutomationVariable -Name 'MaximumIdleTime') #10
$liveVMS = $currentState | % {
	$vm = $_	
	if( $_.Uptime.TotalMinutes -lt $minumumLiveTime )
	{
		$vm
	}else{
		$sessions =$vm.RDPSessions | ? {$_.IdleTime.TotalMinutes -lt $maximumIdleTime}
		if($sessions -ne $null){
            $vm	
        }
	}
}
$liveVMS

$currentState
#if any live vm then leave
if($liveVms -ne $null -and $liveVMS.Count -gt 0){
	break
}
$currentState | %{ $_.VM }| Stop-AzureRmVM -Force
