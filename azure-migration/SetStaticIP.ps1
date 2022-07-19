
# Set all VMs in a resource group to static Ips on all ipconfigurations

$vmRg = ""
$subscriptionId = ""

set-azcontext -SubscriptionId $subscriptionId

$nics = Get-AzNetworkInterface -ResourceGroupName $vmrg

ForEach ($nic in $nics) {
    $index = 0
    $ipconfigs = ($nic.Ipconfigurations).count
    while ($index -lt $ipconfigs) {
        $check = $nic.IpConfigurations[$index].PrivateIpAllocationMethod
        if ($check -eq "Dynamic") {
            $nic.IpConfigurations[$index].PrivateIpAllocationMethod = "Static"
        } 
        $index++
    } 
    $nic | Set-AzNetworkInterface -AsJob
}