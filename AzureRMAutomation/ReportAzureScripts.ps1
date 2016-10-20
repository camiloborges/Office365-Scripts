Select-AzureRmSubscription -SubscriptionName $subscriptionName
$ScriptBlock = {
	
	$TimeOut=15
    $Computer = $env:COMPUTERNAME

    #Record date.  Start process to run query in cmd.  I use starttime independently of process starttime due to a few issues we ran into
    $Started = Get-Date
    $sessions =  (. cmd.exe /c query user )

    #handle no results
    if($sessions){

        1..($sessions.count - 1) | Foreach-Object {
            
            #Start to build the custom object
            $temp = "" | Select ComputerName, Username, SessionName, Id, State, IdleTime, LogonTime
            $temp.ComputerName = $computer

            #The output of query.exe is dynamic. 
            #strings should be 82 chars by default, but could reach higher depending on idle time.
            #we use arrays to handle the latter.

            if($sessions[$_].length -gt 5){
                        
                #if the length is normal, parse substrings
                if($sessions[$_].length -le 82){
                           
                    $temp.Username = $sessions[$_].Substring(1,22).trim()
                    $temp.SessionName = $sessions[$_].Substring(23,19).trim()
                    $temp.Id = $sessions[$_].Substring(42,4).trim()
                    $temp.State = $sessions[$_].Substring(46,8).trim()
                    $temp.IdleTime = $sessions[$_].Substring(54,11).trim()
                    $logonTimeLength = $sessions[$_].length - 65
                    try{
                        $temp.LogonTime = Get-Date $sessions[$_].Substring(65,$logonTimeLength).trim() -ErrorAction stop
                    }
                    catch{
                        #Cleaning up code, investigate reason behind this.  Long way of saying $null....
                        $temp.LogonTime = $sessions[$_].Substring(65,$logonTimeLength).trim() | Out-Null
                    }

                }
                        
                #Otherwise, create array and parse
                else{                                       
                    $array = $sessions[$_] -replace "\s+", " " -split " "
                    $temp.Username = $array[1]
                
                    #in some cases the array will be missing the session name.  array indices change
                    if($array.count -lt 9){
                        $temp.SessionName = ""
                        $temp.Id = $array[2]
                        $temp.State = $array[3]
                        $temp.IdleTime = $array[4]
                        try
                        {
                            $temp.LogonTime = Get-Date $($array[5] + " " + $array[6] + " " + $array[7]) -ErrorAction stop
                        }
                        catch
                        {
                            $temp.LogonTime = ($array[5] + " " + $array[6] + " " + $array[7]).trim()
                        }
                    }
                    else{
                        $temp.SessionName = $array[2]
                        $temp.Id = $array[3]
                        $temp.State = $array[4]
                        $temp.IdleTime = $array[5]
                        try
                        {
                            $temp.LogonTime = Get-Date $($array[6] + " " + $array[7] + " " + $array[8]) -ErrorAction stop
                        }
                        catch
                        {
                            $temp.LogonTime = ($array[6] + " " + $array[7] + " " + $array[8]).trim()
                        }
                    }
                }
            
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
                $string = $temp.idletime

                #to the left of + is days
                if($string -match "\+"){
                    $days = New-TimeSpan -days ($string -split "\+")[0]
                    $hourMin = Convert-ShortIdle ($string -split "\+")[1]
                    $temp.idletime = $days + $hourMin
                }
                #. means less than a minute
                elseif($string -like "." -or $string -like "none"){
                    $temp.idletime = [timespan]"0:00"
                }
                #hours and minutes
                else{
                    $temp.idletime = Convert-ShortIdle $string
                }
                #Output the result
                $temp
            }
        }
    }            
    else
    {
        Write-Warning "'$computer': No sessions found"
    }
}

function Get-UpTime($servers, $uri, $creds)
{
	#-Cn $servers 
$result =  Invoke-Command  -ConnectionUri $uri  -credential  $Creds `
  -Command { 
        $os = Get-WmiObject win32_operatingsystem
       $uptime = (Get-Date) - ($os.ConvertToDateTime($os.lastbootuptime))
       return $uptime
   }
return $result
}

function Get-RDPSessions( $uri, $creds)
{
	#-Cn $servers 
$result =  Invoke-Command  -ConnectionUri $uri  -credential  $Creds `
  -Command $ScriptBlock
return $result
}

#$ADCreds = Get-AutomationPSCredential -Name 'ContosoAdmin'
$subscriptionName =  "Visual Studio Enterprise with MSDN"
$resourceGroupName = "xsharepoint"

#$subscriptionID = Get-AutomationVariable -Name 'SubscriptionID'
#$azureCred = Get-AutomationPSCredential -Name 'AzureSubscriptionADAdmin'

#Login-AzureRMAccount 
#Select-AzureRmSubscription -SubscriptionName $subscriptionName
$vms = GEt-AzureRMVM -ResourceGroupName $resourceGroupName
$nics = Get-AzureRmNetworkInterface  -ResourceGroupName $resourceGroupName

$currentState =	 $vms| %{
	$vm = $_
	$vmName = $_.Name
	$status = (Get-AzureRMVM -name $_.Name -ResourceGroupName $resourceGroupName -status )
	$PowerState = (get-culture).TextInfo.ToTitleCase(($status.statuses)[1].code.split("/")[1])
	if($PowerState-eq "running"){
        $publicAddress = $vm | Get-AzureRmPublicIpAddress
        if($publicAddress -ne $null){
			$publicAddressID = $publicAddress.ID
	        $idEnd = $publicAddressID.SubString($publicAddressID.LastIndexOf("/")+1)
	     	$publicAddress =    Get-AzureRmPublicIpAddress | ? {$_.ID -like "*$idEnd" }
	    	$vmFQDN =  $publicAddress.DnsSettings.FQDN
			if($vmFQDN -ne $null){
				$uri = "https://$($vmFQDN):5986/"
				$uptime = Get-UpTime( "spfarm-ad2.australiasoutheast.cloudapp.azure.com") $uri $ADCreds 
				$rdpSessions = Get-RDPSessions $uri $ADCreds 
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
$sessions = $currentState | %{$_.RDPSessions} 

$minumumLiveTime = 10
$maximumIdleTime = 30
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
break;
#$liveVMS | % { $_.RDPSessions }
#$shutDownVMS = $liveVMS | ? { ($_.RDPSessions -eq $null -or $_.RDPSessions.Count -eq 0 )}
if($liveVms -eq $null){
    $shutDownVMS = $currentState | %{
	    $vm =  $_
#	    Write-Verbose $vm.Name

	    IF($vm.Uptime.TotalMinutes -gt 15 -and ($vm.RDPSessions -eq $null -or $vm.RDPSessions.Count -eq 0 )){
		    $vm
	    }else{
		    $sessions =$vm.RDPSessions | ? {$_.IdleTime.TotalMinutes -gt 0}
		    if($sessions -ne $null ){
			    $vm
		    }
	    }
    }

    #? { $_.RPDSessions| ?{$_.IdleTime.TotalMinutes -gt 0}}
    $shutDownVMS
    $shutDownVMS | %{
    $vm.VM | Stop-AzureRmVM # -Force 
    #	Stop-AzureRMVM
	
    }
    # $currentState | % {$_.VM.Tags}
    #$primaryVM = $currentState | ? {$_.VM.Tags}
}# $currentState | % {$_.VM.Tags}
#$primaryVM = $currentState | ? {$_.VM.Tags}
