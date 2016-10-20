Connect-MsolService camilo.migration@fivep.onmicrosoft.com

Get-MsolUser | Where { 
        (-Not $_.UserPrincipalName.ToLower().StartsWith("admin@")) -and (-not $_.USerPrincipalName.ToLower().Contains("@fivep.onmicrosoft.com" )) 
        }| ForEach { 
            Set-MsolUserPrincipalName -ObjectId $_.ObjectId -NewUserPrincipalName ($_.UserPrincipalName.Split("@")[0] + "@fivep.onmicrosoft.com")
            
            }


