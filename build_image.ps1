param (
    [string]$username = $( Read-Host "Input os user, please" ),
	[string]$git_useremail = $( Read-Host "Input git user email, please" ),
	[string]$git_username = $( Read-Host "Input git user name, please" )
 )
docker build --build-arg username=$username --build-arg git_useremail=$git_useremail --build-arg git_username="$git_username" -t devbox .

Write-Host "Press any key to continue ..."

$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")