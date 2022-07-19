# Migration PreChecks. Written to be compatable with 2008R2. 
# Designed to be executed on servers without internet access. Copy locally together with the Azure Agent MSI to c:\users\$env:username\Documents\migrationfiles\

# Does not yet install .net
# Does not allow a single Windows firewall rule for RDP.

# Elevate
param([switch]$Elevated)
function Check-Admin {
$currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
$currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}
if ((Check-Admin) -eq $false)  {
if ($elevated)
{
# could not elevate, quit
}
 
else {
 
Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -noexit -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))
}
exit
}

# Checks begin

Read-host 'This script prepares a Windows server for migration to Azure. Press any key to continue'

"Checking SAN policy....."
$sanPolicy = "SAN" | diskpart

if ($sanPolicy -like "*Online All*") {
    write-host "Policy already set - no action needed" -ForegroundColor Green
}else {
    write-host "Policy not set. Changing SAN policy...."
    "SAN Policy=OnlineAll" | diskpart
    }

"`nSetting RDP Windows firewall rule....."

$os = (Get-WMIObject win32_operatingsystem).name
if ($os -like "*2008*") {
    netsh advfirewall firewall set rule name=”Remote Desktop (TCP-IN)” new enable=yes
}else{
    netsh advfirewall firewall set rule name="Remote Desktop - User Mode (TCP-IN)" new enable=yes
    }

"`nChecking .net Version....."
$dotNetVersions = Get-ChildItem HKLM:\SOFTWARE\WOW6432Node\Microsoft\Updates | Where-Object {$_.name -like "*.NET Framework 4*"}

if (!$dotNetVersions) {
    write-host ".Net version 4 not installed but is required to run the Azure Agent. Please install." -ForegroundColor Red
}

else {
    $dotNetVersions
    write-host "`nTest Complete .Net meets min requirements" -ForegroundColor Green
    $agentMsg = "`nInstall Azure Agent? [Y/N]"
    $response = Read-Host -Prompt $agentMsg
    if ($response -eq 'y') {
        msiexec.exe /i $HOME\Downloads\WindowsAzureVmAgent.2.7.41491.1009_210309-1520.fre.msi /passive
    }
}
Read-host "`nChecks Complete. Press any key to exit"