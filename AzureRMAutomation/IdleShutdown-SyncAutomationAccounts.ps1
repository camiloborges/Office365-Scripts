
$automationAccountName="xSharePointAutomation" 
$resourceGroupNAme ="xsharepoint"
Login-AzureRmAccount -SubscriptionName $automationAccount
Select-AzureRmSubscription -SubscriptionName "Visual Studio Enterprise with MSDN"

$automationAccount = Get-AzureRmAutomationAccount -name $automationAccountName  -ResourceGroupName $resourceGroupNAme
$certificates = $automationAccount | Get-AzureRmAutomationCertificate 
$variables = $automationAccount | Get-AzureRmAutomationVariable
$credentials = $automationAccount | Get-AzureRmAutomationCredential
$runbooks = $automationAccount | Get-AzureRmAutomationRunbook


$replicas=4

$parsed=0;
do{
$parsed = $parsed + 1
$replicaAccountName = $automationAccountName +"_" + $parsed.ToString() 
$replicaAccount = Get-AzureRmAutomationAccount -name $replicaAccountName  -ResourceGroupName $resourceGroupNAme



}while ($parsed -lt $replicas)


