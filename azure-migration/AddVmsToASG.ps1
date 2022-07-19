# Adds NIC to ASG using a CSV

$vmRg = "Apps-Data-Prod-RG"
$subscriptionId = ""
$vms = import-csv ./asg.csv

set-azcontext -SubscriptionId $subscriptionId

ForEach ($vm in $vms) {
    $index = 0
    $azvm = Get-AzVM -Name $vm.vmname
    $nic = Get-AzNetworkInterface -ResourceId $azVm.NetworkProfile.NetworkInterfaces.id
    $ipconfigs = ($nic.Ipconfigurations).count
    $asg = Get-AzApplicationSecurityGroup -Name $vm.asg -ResourceGroupName $vm.asgRg
    while ($index -lt $ipconfigs) {
        $check = $nic.IpConfigurations[$index].ApplicationSecurityGroups.id
        if ($check -ne $asg.id) {
            $nic.IpConfigurations[$index].ApplicationSecurityGroups = $asg
            Write-host "Adding ASG to" $vm.vmname
        }
        else {
            Write-host "NOT adding ASG to" $vm.vmname
        }
        $index++
    } 
    $nic | Set-AzNetworkInterface -AsJob
}