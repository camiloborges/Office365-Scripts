param(
$url,
$group
)

Connect-PnPOnline -Url $url
$web = get-pnpweb
Remove-PnPGroup -Identity $group -Web $web