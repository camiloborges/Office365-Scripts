#option 1: selected lists

$locations = (
   @{ Url = "http://contoso"
  Libraries = @("Documents","Pages")
},
@{Url = "http://contoso/sites"
  Libraries = @("Documents","Pages")
})

$locations | % { 
    $web = Get-SPWeb  $_.Url

    $libraries = $_.Libraries
    $libraries | %{
        $_
        $web.Lists | where {$_.Name -eq $_} | % {
            $_.DefaultItemOpen =[Microsoft.Sharepoint.DefaultItemOpen]::PreferClient; 
            $_.ForceCheckOut = $false
            $_.Update()
        }
    }
}

#option 2: all libraries 

$locations = (
   @{ Url = "http://contoso"
},
@{Url = "http://contoso/sites"
})

$locations | % { 
    $web = Get-SPWeb  $_.Url

    $web.Lists | where {$_.BaseTemplate -eq "DocumentLibrary" } | % {
            $_.DefaultItemOpen =[Microsoft.Sharepoint.DefaultItemOpen]::PreferClient; 
            $_.ForceCheckOut = $false
            $_.Update()
    }
}

break 
