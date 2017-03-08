param(
$url,
$group,
$force = $false
)

Connect-PnPOnline -Url $url
$web = get-pnpweb
Remove-PnPGroup -Identity $group -Web $web -Force:$force