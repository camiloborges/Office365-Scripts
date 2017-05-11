$user ="configsp@mips.com.au"
$pass = ""

$creds = New-Object System.Management.Automation.PSCredential($User,(ConvertTo-SecureString $Pass -AsPlainText -Force))
Set-PnPTraceLog -on -Level Debug
Connect-PnPOnline "https://mipsgroup.sharepoint.com/teamsites/sandbox/5p-dev" -Credentials $creds


