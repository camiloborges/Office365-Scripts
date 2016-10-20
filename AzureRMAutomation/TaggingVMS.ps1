$resourceName = "spfarm-ad2"
$resourceGroupName = "xSharePoint"
$resource = Get-AzureRmResource -ResourceGroupName $resourceGroupName -name $resourceName -ResourceType Microsoft.Compute/virtualMachines
$tags = $resource.Tags
$tag = $tags | ?{$_.Name -eq "status"}| select -first 1
if($tag -ne $null)
{
	$tag.Value ="forced"
}else{
	$tags += @{Name="status";Value="approved"}
}
$resource | Set-AzureRmResource -Tag $tags -Confirm:$false -force