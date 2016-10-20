# Get the VNET to which to connect the NIC
$resourceGroupName = "xsharepoint"
$VNETScript="spfarmvnet"
$VNET = Get-AzureRmVirtualNetwork -Name ‘spfarmvnet’ -ResourceGroupName $resourceGroupName
# Get the Subnet ID to which to connect the NIC
$SubnetID = (Get-AzureRmVirtualNetworkSubnetConfig -Name ‘adSubnet’ -VirtualNetwork $VNET).Id
# NIC Name
$NICName = ‘spfarm-ad2-1’
#NIC Resource Group
$NICResourceGroup = ‘xsharepoint’
#NIC creation location
$Location = ‘Australia Southeast’
#Enter the IP address
$IPAddress = ‘10.0.0.10’

#–> Create now the NIC Interface

New-AzureRmNetworkInterface -Name $NICName -ResourceGroupName $NICResourceGroup -Location $Location -SubnetId $SubnetID -PrivateIpAddress $IPAddress


