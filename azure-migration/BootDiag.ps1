# Adds a storage account to the boot diagnostic setting for a list of VMs
# Doesn't seem to update boot diag after a migration using Azure migrate

$rg = "Apps-Data-Prod-RG"
$subscription_id = ""
$storage_account = ""

set-azcontext -SubscriptionId $subscription_id
$vm_list = Get-AzVM -ResourceGroupName $rg

foreach ($vm in $vm_list) {
    Set-AzVMBootDiagnostic -VM $vm -Enable -ResourceGroupName $rg -StorageAccountName $storage_account
}