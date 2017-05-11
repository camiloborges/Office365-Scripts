
<#
Connect-MsolService 
Connect-PNPOnline -url https://quaycleanaustralia.sharepoint.com
 $msolusers =Get-MsolUser -all
 $users = $msolusers | %{ 
     $pnpUser = Get-PnPUserProfileProperty -Account $_.UserPrincipalName
     if($pnpUser.UserProfileProperties.'SPS-HideFromAddressLists' -ne $null){
        $pnpUser
    }
}
#>
$colAverages = @()
foreach ($objBatter in $users)
  {
    $objAverage = New-Object System.Object
    $objAverage | Add-Member -type NoteProperty -name FullName -value $objBatter.DisplayName
    $objAverage | Add-Member -type NoteProperty -name AccountName -value $objBatter.AccountName
    $objAverage | Add-Member -type NoteProperty -name Email -value $objBatter.Email

    $objAverage | Add-Member -type NoteProperty -name Hide -value $objBatter.UserProfileProperties.'SPS-HideFromAddressLists'

    $colAverages += $objAverage
  }

$colAverages | Sort-Object BattingAverage -descending
$filtered = $users | %{
    
    
    @{
        FullName = $_.DisplayName;
        AccountName = $_.AccountName;
        Email= $_.Email;
        Hide = $_.UserProfileProperties.'SPS-HideFromAddressLists'
    }
}
 #-SPSHideFromAddressLists

 $msolusers | ?{$_.DisplayName -eq ""} |  %{$_.DisplayName} 
 $user = $msolusers | ?{$_.DisplayName -eq ""}

 $pnpUser = Get-PnPUserProfileProperty -Account $user.UserPrincipalName
