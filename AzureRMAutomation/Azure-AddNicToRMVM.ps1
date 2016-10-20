
$VMname = ‘spfarm-ad2’
$VMRG =  ‘xsharepoint’
$NICName = ‘spfarm-ad2-1’
#NIC Resource Group
$NICResourceGroup = ‘xsharepoint’

#Get the VM
$VM = Get-AzureRmVM -Name $VMname -ResourceGroupName $VMRG

#Add the second NIC
$NewNIC =  Get-AzureRmNetworkInterface -Name $NICName -ResourceGroupName $NICResourceGroup
Add-AzureRmVMNetworkInterface -VM $VM -Id $NewNIC.Id
# Show the Network interfaces
#$VM.NetworkProfile.NetworkInterfaces

#we have to set one of the NICs to Primary, i will set the first NIC in this example
#$VM.NetworkProfile.NetworkInterfaces.Item(0).Primary = $true

#Update the VM configuration (The VM will be restarted)
Update-AzureRmVM -VM $VM -ResourceGroupName $VMRG