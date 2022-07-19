# Exports list of Azure AD App Certs

Connect-AzureAD

$apps = Get-AzureADApplication
$returnObj = @()
foreach ($app in $apps)
{
    # Fetch certificate info
    $certinfo = Get-AzureADApplicationProxyApplication -ObjectId $app.objectid

    # Create objects based on required info
    $obj = new-object psobject -Property @{
        InternalURL = $certinfo.InternalURL
        ExternalURL = $certinfo.ExternalURL
        Thumbprint = $certinfo.VerifiedCustomDomainCertificatesMetadata.Thumbprint
        SubjectName = $certinfo.VerifiedCustomDomainCertificatesMetadata.SubjectName
        IssueDate  = $certinfo.VerifiedCustomDomainCertificatesMetadata.IssueDate
        ExpiryDate  = $certinfo.VerifiedCustomDomainCertificatesMetadata.ExpiryDate
    }
    if ($obj.Thumbprint) {
        $returnobj += $obj | Select-Object InternalURL,ExternalURL,Thumbprint,SubjectName,IssueDate,ExpiryDate
    }
}

$returnObj | Export-CSV .\AzurADAppCerts.csv -NoTypeInformation