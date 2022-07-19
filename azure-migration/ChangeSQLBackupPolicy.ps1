# Changes SQL backup policy
$PolicyName = ""
$Subscription = ""
$vaultName = ""

$vault = Get-AzRecoveryServicesVault -Name $vaultName
Set-AzRecoveryServicesVaultContext -Vault $vault

$TargetPol1 = Get-AzRecoveryServicesBackupProtectionPolicy -Name $PolicyName
$backupitems = Get-AzRecoveryServicesBackupItem -WorkloadType MSSQL -BackupManagementType AzureWorkload

ForEach ($backupitem in $backupitems) {
	Enable-AzRecoveryServicesBackupProtection -Item $backupitem -Policy $TargetPol1
}
