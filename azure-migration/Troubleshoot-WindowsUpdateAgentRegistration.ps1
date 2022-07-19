
<#PSScriptInfo
 
.VERSION 1.0
 
.GUID fa3f8397-9d89-4f06-985c-2dfffcfd5520
 
.AUTHOR Stas Kuvshinov
 
.COMPANYNAME Microsoft Corporation
 
.COPYRIGHT © 2018 Microsoft Corporation. All rights reserved.
 
.TAGS Automation UpdateManagement HybridRunbookWorker Troubleshoot
 
.LICENSEURI
 
.PROJECTURI
 
.ICONURI
 
.EXTERNALMODULEDEPENDENCIES
 
.REQUIREDSCRIPTS
 
.EXTERNALSCRIPTDEPENDENCIES
 
.RELEASENOTES
Original set of troubleshooting checks for Update Management Agent (Automation Hybrid Runbook Worker) on Windows machines
 
.PRIVATEDATA
 
#>

<#
 
.DESCRIPTION
 Troubleshooting utility for Update Management Agent (Automation Hybrid Runbook Worker) on Windows machines
 
#> 
param(
    [string]$automationAccountLocation,
    [switch]$returnCompactFormat,
    [switch]$returnAsJson
)

$location = switch ( $automationAccountLocation ) {
        "australiasoutheast"{ "ase"  }
        "canadacentral"     { "cc"   }
        "centralindia"      { "cid"  }
        "eastus2"           { "eus2" }
        "japaneast"         { "jpe"  }
        "northeurope"       { "ne"   }
        "southcentralus"    { "scus" }
        "southeastasia"     { "sea"  }
        "uksouth"           { "uks"  }
        "westcentralus"     { "wcus" }
        "westeurope"        { "we"   }

        default             { "eus2" }
}

$validationResults = @()
[string]$CurrentResult = ""
[string]$CurrentDetails = ""
function New-RuleCheckResult
{
    [CmdletBinding()]
    param(
        [string][Parameter(Mandatory=$true)]$ruleId,
        [string]$ruleName,
        [string]$ruleDescription,
        [string][ValidateSet("Passed","PassedWithWarning", "Failed", "Information")]$result,
        [string]$resultMessage,
        [string]$ruleGroupId = $ruleId,
        [string]$ruleGroupName,
        [string]$resultMessageId = $ruleId,
        [array]$resultMessageArguments = @()
    )

    if ($returnCompactFormat.IsPresent) {
        $compactResult = [pscustomobject] [ordered] @{
            'RuleId'= $ruleId
            'RuleGroupId'= $ruleGroupId
            'CheckResult'= $result
            'CheckResultMessageId'= $resultMessageId
            'CheckResultMessageArguments'= $resultMessageArguments
        }
        return $compactResult
    }

    $fullResult = [pscustomobject] [ordered] @{
        'RuleId'= $ruleId
        'RuleGroupId'= $ruleGroupId
        'RuleName'= $ruleName
        'RuleGroupName' = $ruleGroupName
        'RuleDescription'= $ruleDescription
        'CheckResult'= $result
        'CheckResultMessage'= $resultMessage
        'CheckResultMessageId'= $resultMessageId
        'CheckResultMessageArguments'= $resultMessageArguments
    }
    return $fullResult
}

function checkRegValue
{
    [CmdletBinding()]
    param(
        [string][Parameter(Mandatory=$true)]$path,
        [string][Parameter(Mandatory=$true)]$name,
        [int][Parameter(Mandatory=$true)]$valueToCheck
    )

    $val = Get-ItemProperty -path $path -name $name -ErrorAction SilentlyContinue
    if($val.$name -eq $null) {
        return $null
    }

    if($val.$name -eq $valueToCheck) {
        return $true
    } else {
        return $false
    }
}

function Validate-OperatingSystem {
    $osRequirementsLink = "https://docs.microsoft.com/azure/automation/automation-update-management#supported-client-types"

    $ruleId = "OperatingSystemCheck"
    $ruleName = "Operating System"
    $ruleDescription = "The Windows Operating system must be version 6.1.7601 (Windows Server 2008 R2 SP1) or higher"
    $result = $null
    $resultMessage = $null
    $ruleGroupId = "prerequisites"
    $ruleGroupName = "Prerequisite Checks"
    $resultMessageArguments = @()

    if([System.Environment]::OSVersion.Version -ge [System.Version]"6.1.7601") {
        $result = "Passed"
        $resultMessage = "Operating System version is supported"
    } else {
        $result = "Failed"
        $resultMessage = "Operating System version is not supported. Supported versions listed here: $osRequirementsLink"
        $resultMessageArguments += $osRequirementsLink
    }
    $resultMessageId = "$ruleId.$result"

    return New-RuleCheckResult $ruleId $ruleName $ruleDescription $result $resultMessage $ruleGroupId $ruleGroupName $resultMessageId $resultMessageArguments
}

function Validate-NetFrameworkInstalled {
    $netFrameworkDownloadLink = "https://www.microsoft.com/net/download/dotnet-framework-runtime"

    $ruleId = "DotNetFrameworkInstalledCheck"
    $ruleName = ".Net Framework 4.5+"
    $ruleDescription = ".NET Framework version 4.5 or higher is required"
    $result = $null
    $resultMessage = $null
    $ruleGroupId = "prerequisites"
    $ruleGroupName = "Prerequisite Checks"
    $resultMessageArguments = @()

    # https://docs.microsoft.com/dotnet/framework/migration-guide/how-to-determine-which-versions-are-installed
    $dotNetFullRegistryPath = "HKLM:SOFTWARE\\Microsoft\\NET Framework Setup\\NDP\\v4\\Full"
    if((Get-ChildItem $dotNetFullRegistryPath -ErrorAction SilentlyContinue) -ne $null) {
        $versionCheck = (Get-ChildItem $dotNetFullRegistryPath) | Get-ItemPropertyValue -Name Release | ForEach-Object { $_ -ge 378389 }
        if($versionCheck -eq $true) {
            $result = "Passed"
            $resultMessage = ".NET Framework version 4.5+ is found"
        } else {
            $result = "Failed"
            $resultMessage = ".NET Framework version 4.5 or higher is required: $netFrameworkDownloadLink"
            $resultMessageArguments += $netFrameworkDownloadLink
        }
    } else{
        $result = "Failed"
        $resultMessage = ".NET Framework version 4.5 or higher is required: $netFrameworkDownloadLink"
        $resultMessageArguments += $netFrameworkDownloadLink
    }
    $resultMessageId = "$ruleId.$result"

    return New-RuleCheckResult $ruleId $ruleName $ruleDescription $result $resultMessage $ruleGroupId $ruleGroupName $resultMessageId $resultMessageArguments
}

function Validate-WmfInstalled {
    $wmfDownloadLink = "https://www.microsoft.com/download/details.aspx?id=54616"
    $ruleId = "WindowsManagementFrameworkInstalledCheck"
    $ruleName = "WMF 5.1"
    $ruleDescription = "Windows Management Framework version 4.0 or higher is required (version 5.1 or higher is preferable)"
    $result = $null
    $resultMessage = $null
    $ruleGroupId = "prerequisites"
    $ruleGroupName = "Prerequisite Checks"   

    $psVersion = $PSVersionTable.PSVersion
    $resultMessageArguments = @() + $psVersion

    if($psVersion -ge 5.1) {
        $result = "Passed"
        $resultMessage = "Detected Windows Management Framework version: $psVersion"
    } elseif($psVersion.Major -ge 4) {
        $result = "PassedWithWarning"
        $resultMessage = "Detected Windows Management Framework version: $psVersion. Consider upgrading to version 5.1 or higher for increased reliability: $wmfDownloadLink"
        $resultMessageArguments += $wmfDownloadLink
    } else {
        $result = "Failed"
        $resultMessage = "Detected Windows Management Framework version: $psVersion. Version 4.0 or higher is required (version 5.1 or higher is preferable): $wmfDownloadLink"
        $resultMessageArguments += $wmfDownloadLink
    }
    $resultMessageId = "$ruleId.$result"

    return New-RuleCheckResult $ruleId $ruleName $ruleDescription $result $resultMessage $ruleGroupId $ruleGroupName $resultMessageId $resultMessageArguments
}

function Validate-TlsEnabled {
    $ruleId = "TlsVersionCheck"
    $ruleName = "TLS 1.2"
    $ruleDescription = "Client and Server connections must support TLS 1.2"
    $result = $null
    $reason = ""
    $resultMessage = $null
    $ruleGroupId = "prerequisites"
    $ruleGroupName = "Prerequisite Checks"

    $tls12RegistryPath = "HKLM:\\SYSTEM\\CurrentControlSet\\Control\\SecurityProviders\\SCHANNEL\\Protocols\\TLS 1.2\\"
    $serverEnabled =     checkRegValue ([System.String]::Concat($tls12RegistryPath, "Server")) "Enabled" 1
    $ServerNotDisabled = checkRegValue ([System.String]::Concat($tls12RegistryPath, "Server")) "DisabledByDefault" 0
    $clientEnabled =     checkRegValue ([System.String]::Concat($tls12RegistryPath, "Client")) "Enabled" 1
    $ClientNotDisabled = checkRegValue ([System.String]::Concat($tls12RegistryPath, "Client")) "DisabledByDefault" 0

    $ServerNotEnabled = checkRegValue ([System.String]::Concat($tls12RegistryPath, "Server")) "Enabled" 0
    $ServerDisabled =   checkRegValue ([System.String]::Concat($tls12RegistryPath, "Server")) "DisabledByDefault" 1
    $ClientNotEnabled = checkRegValue ([System.String]::Concat($tls12RegistryPath, "Client")) "Enabled" 0
    $ClientDisabled =   checkRegValue ([System.String]::Concat($tls12RegistryPath, "Client")) "DisabledByDefault" 1

    if ($validationResults[0].CheckResult -ne "Passed" -and [System.Environment]::OSVersion.Version -ge [System.Version]"6.0.6001") {
        $result = "Failed"
        $resultMessageId = "$ruleId.$result"
        $resultMessage = "TLS 1.2 is not enabled by default on the Operating System. Follow the instructions to enable it: https://support.microsoft.com/help/4019276/update-to-add-support-for-tls-1-1-and-tls-1-2-in-windows"
    } elseif([System.Environment]::OSVersion.Version -ge [System.Version]"6.1.7601" -and [System.Environment]::OSVersion.Version -le [System.Version]"6.1.8400") {
        if($ClientNotDisabled -and $ServerNotDisabled -and !($ServerNotEnabled -and $ClientNotEnabled)) {
            $result = "Passed"
            $resultMessage = "TLS 1.2 is enabled on the Operating System."
            $resultMessageId = "$ruleId.$result"
        } else {
            $result = "Failed"
            $reason = "NotExplicitlyEnabled"
            $resultMessageId = "$ruleId.$result.$reason"
            $resultMessage = "TLS 1.2 is not enabled by default on the Operating System. Follow the instructions to enable it: https://docs.microsoft.com/windows-server/security/tls/tls-registry-settings#tls-12"
        }
    } elseif([System.Environment]::OSVersion.Version -ge [System.Version]"6.2.9200") {
        if($ClientDisabled -or $ServerDisabled -or $ServerNotEnabled -or $ClientNotEnabled) {
            $result = "Failed"
            $reason = "ExplicitlyDisabled"
            $resultMessageId = "$ruleId.$result.$reason"
            $resultMessage = "TLS 1.2 is supported by the Operating System, but currently disabled. Follow the instructions to re-enable: https://docs.microsoft.com/windows-server/security/tls/tls-registry-settings#tls-12"
        } else {
            $result = "Passed"
            $reason = "EnabledByDefault"
            $resultMessageId = "$ruleId.$result.$reason"
            $resultMessage = "TLS 1.2 is enabled by default on the Operating System."
        }
    } else {
        $result = "Failed"
        $reason = "NoDefaultSupport"
        $resultMessageId = "$ruleId.$result.$reason"
        $resultMessage = "Your OS does not support TLS 1.2 by default."
    }

    return New-RuleCheckResult $ruleId $ruleName $ruleDescription $result $resultMessage $ruleGroupId $ruleGroupName $resultMessageId
}

function Validate-EndpointConnectivity {
    [CmdletBinding()]
    param(
        [string][Parameter(Mandatory=$true)]$endpoint,
        [string][Parameter(Mandatory=$true)]$ruleId,
        [string][Parameter(Mandatory=$true)]$ruleName,
        [string]$ruleDescription = "Proxy and firewall configuration must allow Automation Hybrid Worker agent to communicate with $endpoint"
    )

    $result = $null
    $resultMessage = $null
    $ruleGroupId = "connectivity"
    $ruleGroupName = "connectivity"
    $resultMessageArguments = @() + $endpoint

    if((Test-NetConnection -ComputerName $endpoint -Port 443 -WarningAction SilentlyContinue).TcpTestSucceeded) {
        $result = "Passed"
        $resultMessage = "TCP Test for $endpoint (port 443) succeeded"
    } else {
        $result = "Failed"
        $resultMessage = "TCP Test for $endpoint (port 443) failed"
    }

    $resultMessageId = "$ruleId.$result"

    return New-RuleCheckResult $ruleId $ruleName $ruleDescription $result $resultMessage $ruleGroupId $ruleGroupName $resultMessageId $resultMessageArguments
}

function Validate-RegistrationEndpointsConnectivity {
    $validationResults = @()

    $managementGroupRegistrations = Get-ChildItem 'HKLM:\\SYSTEM\\CurrentControlSet\\Services\\HealthService\\Parameters\\Management Groups' -ErrorAction SilentlyContinue | select -ExpandProperty PSChildName
    $managementGroupRegistrations | foreach {$i=1} {
        $prefix = "AOI-"
        if ($_ -match "$prefix*") {            
            $workspaceId = $_.Substring($prefix.Length)
            $endpoint = "$workspaceId.agentsvc.azure-automation.net"
            $ruleId = "AutomationAgentServiceConnectivityCheck$i"
            $ruleName = "Registration endpoint"

            $validationResults += Validate-EndpointConnectivity $endpoint $ruleId $ruleName

            $i++
        }
    }

    if($validationResults.Count -eq 0) {
        $ruleId = "AutomationAgentServiceConnectivityCheck1"
        $ruleName = "Registration endpoint"

        $result = "Failed"
        $reason = "NoRegistrationFound"
        $resultMessage = "Unable to find Workspace registration information in registry"

        $ruleGroupId = "connectivity"
        $ruleGroupName = "connectivity"
        $resultMessageId = "$ruleId.$result.$reason"

        $validationResults += New-RuleCheckResult $ruleId $ruleName $ruleDescription $result $resultMessage $ruleGroupId $ruleGroupName $resultMessageId
    }

    return $validationResults
}

function Validate-OperationsEndpointConnectivity {
    $endpoint = "$location-jobruntimedata-prod-su1.azure-automation.net"
    $ruleId = "AutomationJobRuntimeDataServiceConnectivityCheck"
    $ruleName = "Operations endpoint"

    return Validate-EndpointConnectivity $endpoint $ruleId $ruleName
}

function Validate-MmaIsRunning {
    $mmaServiceName = "HealthService"
    $mmaServiceDisplayName = "Microsoft Monitoring Agent"

    $ruleId = "MonitoringAgentServiceRunningCheck"
    $ruleName = "Monitoring Agent service status"
    $ruleDescription = "$mmaServiceName must be running on the machine"
    $result = $null
    $resultMessage = $null
    $ruleGroupId = "servicehealth"
    $ruleGroupName = "VM Service Health Checks"
    $resultMessageArguments = @() + $mmaServiceDisplayName + $mmaServiceName

    if(Get-Service -Name $mmaServiceName -ErrorAction SilentlyContinue| Where-Object {$_.Status -eq "Running"} | Select-Object) {
        $result = "Passed"
        $resultMessage = "$mmaServiceDisplayName service ($mmaServiceName) is running"
    } else {
        $result = "Failed"
        $resultMessage = "$mmaServiceDisplayName service ($mmaServiceName) is not running"
    }
    $resultMessageId = "$ruleId.$result"

    return New-RuleCheckResult $ruleId $ruleName $ruleDescription $result $resultMessage $ruleGroupId $ruleGroupName $resultMessageId $resultMessageArguments
}

function Validate-MmaEventLogHasNoErrors {
    $mmaServiceName = "Microsoft Monitoring Agent"
    $logName = "Operations Manager"
    $eventId = 4502

    $ruleId = "MonitoringAgentServiceEventsCheck"
    $ruleName = "Monitoring Agent service events"
    $ruleDescription = "Event Log must not have event 4502 logged in the past 24 hours"
    $result = $null
    $reason = ""
    $resultMessage = $null
    $ruleGroupId = "servicehealth"
    $ruleGroupName = "VM Service Health Checks"
    $resultMessageArguments = @() + $mmaServiceName + $logName + $eventId

    $OpsMgrLogExists = [System.Diagnostics.EventLog]::Exists($logName);
    if($OpsMgrLogExists) {
        $event = Get-EventLog -LogName "Operations Manager" -Source "Health Service Modules" -After (Get-Date).AddHours(-24) | where {$_.eventID -eq $eventId}
        if($event -eq $null) {
            $result = "Passed"
            $resultMessageId = "$ruleId.$result"
            $resultMessage = "$mmaServiceName service Event Log ($logName) does not have event $eventId logged in the last 24 hours."
        } else {
            $result = "Failed"
            $reason = "EventFound"
            $resultMessageId = "$ruleId.$result.$reason"
            $resultMessage = "$mmaServiceName service Event Log ($logName) has event $eventId logged in the last 24 hours. Look at the results of other checks to troubleshoot the reasons."
        }
    } else {
        $result = "Failed"
        $reason = "NoLog"
        $resultMessageId = "$ruleId.$result.$reason"
        $resultMessage = "$mmaServiceName service Event Log ($logName) does not exist on the machine"
    }

    return New-RuleCheckResult $ruleId $ruleName $ruleDescription $result $resultMessage $ruleGroupId $ruleGroupName $resultMessageId $resultMessageArguments
}

function Validate-MachineKeysFolderAccess {
    $folder = "C:\\ProgramData\\Microsoft\\Crypto\\RSA\\MachineKeys"

    $ruleId = "CryptoRsaMachineKeysFolderAccessCheck"
    $ruleName = "Crypto RSA MachineKeys Folder Access"
    $ruleDescription = "SYSTEM account must have WRITE and MODIFY access to '$folder'"
    $result = $null
    $resultMessage = $null
    $ruleGroupId = "permissions"
    $ruleGroupName = "Access Permission Checks"
    $resultMessageArguments = @() + $folder

    $User = $env:UserName
    $permission = (Get-Acl $folder).Access | ? {($_.IdentityReference -match $User) -or ($_.IdentityReference -match "Everyone")} | Select IdentityReference, FileSystemRights
    if ($permission) {
        $result = "Passed"
        $resultMessage = "Have permissions to access $folder"
    } else {
        $result = "Failed"
        $resultMessage = "Missing permissions to access $folder"
    }
    $resultMessageId = "$ruleId.$result"

    return New-RuleCheckResult $ruleId $ruleName $ruleDescription $result $resultMessage $ruleGroupId $ruleGroupName $resultMessageId $resultMessageArguments
}

$validationResults += Validate-OperatingSystem
$validationResults += Validate-NetFrameworkInstalled
$validationResults += Validate-WmfInstalled
Validate-RegistrationEndpointsConnectivity | % { $validationResults += $_ }
$validationResults += Validate-OperationsEndpointConnectivity
$validationResults += Validate-MmaIsRunning
$validationResults += Validate-MmaEventLogHasNoErrors
$validationResults += Validate-MachineKeysFolderAccess
$validationResults += Validate-TlsEnabled

if($returnAsJson.IsPresent) {
    return ConvertTo-Json $validationResults -Compress
} else {
    return $validationResults
}