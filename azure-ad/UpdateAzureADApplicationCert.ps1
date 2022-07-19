Write-host "This Script will update the certificate on all Azure AD Applications with the external URL *YOURURL. You will need to provide a wildcard certificate from a local path." -ForegroundColor Red

read-host "Press any key to connect to Azure AD"
#Connect-AzureAD

# Get cert path
$certpath = read-host "Enter local path to certificate in PFX format E.G .\wildcard.pfx"
$securePassword = Read-Host "Enter the certificate password" -AsSecureString

read-host "The script will now search for applications with https://*YOURHOSTNAME in the externalurl and apply the cert. You will see errors for applications not configured with an application proxy endpoint. Press any key to continue"

$apps = Get-AzureADApplication
foreach ($app in $apps)
{
    # Fetch certificate info
    $certinfo = Get-AzureADApplicationProxyApplication -ObjectId $app.objectid -ErrorAction SilentlyContinue

    if ($certinfo.externalurl -like "Https://*YOURHOSTNAME*") {
        
        # Apply Certificate
        write-host "Applying cert from $certpath to" $certinfo.externalurl
        # Set-AzureADApplicationProxyApplicationCustomDomainCertificate -ObjectId $app.objectid -PfxFilePath $certpath -Password $securePassword
    }
}

