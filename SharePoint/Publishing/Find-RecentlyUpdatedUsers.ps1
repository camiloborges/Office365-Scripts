function Update-Property($adProperty, $upsProperty,  $adUser, $properties)
{
    $extensionAttribute  = $adUser.ExtensionProperty.Keys | ?{$_ -like "*$($adProperty)"}
    if($null -ne $extensionAttribute -and $properties.$upsProperty -ne $adUser.ExtensionProperty.$extensionAttribute){
        Set-PnPUserProfileProperty -Account $adUser.UserPrincipalName -PropertyName $upsProperty -Value $adUser.ExtensionProperty.$extensionAttribute  
    }
}
$url = "https://kasa.sharepoint.com"
$creds = GEt-StoredCredential -Target $url 
Connect-AzureAD -Credential $creds | Out-Null
Connect-PnPOnline -Credentials $creds -Url $url | Out-Null
$users= (Get-AzureADUser -Top 100000  
            #| ?{$_.LastDirSyncTime -gt ((get-date).AddDays(-20))}
            ) 

$users | %{
    $user = $_
        $properties = (Get-PnPUserProfileProperty -Account $user.UserPrincipalName ).UserProfileProperties
    Update-Property -adProperty "extensionAttribute10" -upsProperty "WorkCentreCode" -adUser $user  -properties $properties
    Update-Property -adProperty "extensionAttribute11" -upsProperty "OutletType" -adUser $user  -properties $properties
    Update-Property -adProperty "extensionAttribute12" -upsProperty "PositionProfile" -adUser $user  -properties $properties
}