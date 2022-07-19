# Sets an availabilty set to use a proximity placement group

$RG = ""
$Subscription_Id = ""
$ProximityPlacementGroupId = ""

set-azcontext -SubscriptionId $Subscription_id
Get-AzAvailabilitySet -ResourceGroupName $RG | Update-AzAvailabilitySet -ProximityPlacementGroupId $ProximityPlacementGroupId