# Finds App Proxy Connector Group based on name like.. E.G DMZ

Connect-AzureAD

$apps = Get-AzureADApplication

foreach ($app in $apps)
{
    $appdetails = Get-AzureADApplication -ObjectId $app.ObjectId | Format-Table objectid, AppId, Displayname
    $group = Get-AzureADApplicationProxyApplicationConnectorGroup -ObjectId $app.ObjectId -ErrorAction SilentlyContinue

    If ($group.name -like "DMZ*"){
        $appdetails
        $group
    }
}