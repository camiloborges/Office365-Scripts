param(
$url,
$group,
$force
)

Connect-PnPOnline -Url $url
$web = get-pnpweb
Remove-PnPGroup -Identity $group -Web $web -Force:$force