#Connect-AzureAD
#Connect-MsolService 
# Connect-PnPOnline
$unlicensedusers = get-msoluser  -UnlicensedUsersOnly
$unlicensedusers | % {
$user = $_
try{
set-azureaduser -ObjectId $USER.ObjectId -ShowInAddressList $false
}catch{
write-host $user.UserPrincipalName
}
}
#showInAddressList