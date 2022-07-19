# Example script to create policy exemptions from a list of Resource IDs. 
# Usefull when bulk adding resources that belong to multiple subscriptions and/or resource groups. 
# Note: similar functionality available manually in the portal

# User variables - Replace example values as needed

$ResourceIDs = @( # This bit could be improved by accepting a list from a txt/csv file
    "/subscriptions/c624c6dc-826d-47e9-879a-d1ec7af0c4e1/resourceGroups/dns/providers/Microsoft.Compute/virtualMachines/vm9345345",
    "/subscriptions/293a7d3d-e947-4510-a3d5-a618c3657b84/resourceGroups/migrate-test/providers/Microsoft.Compute/virtualMachines/migrateSource"
)
$Date = Get-Date -Format "MM-dd-yyyy-HH-mm-ss"
$PolicyExemptionDisplayNamePrefix = "Endpoint protection exemption"
$PolicyExemptionDesc = "These resources are exempt from endpoint protection checks"
$PolicyExemptionCategory = "waiver"
$ExpireOn = "2023-12-23T00:00:00"
$PolicyExemptionMetadata = @"
{
    "RequestedBy":"ts", 
    "ApprovedBy":"azsec", 
    "ApprovedOn":"18/07/2022", 
    "TicketRef":"123456789"
}
"@
$PolicyAssignmentName = "fa57ee6c7928459e927993df" # Specify the name of the policy assignment containing the policy
$ManagementGroupID = "198d43e1-63f3-4d39-87bd-9a99b4598f8b" # Specify the ID of the management group to lookup the policy assignment. This scope will change to subscription or resource depending on the existing policy assignment scope
$PolicyDefinitionReferenceId = "installEndpointProtection" # Policy definition reference id is only needed for policy initiative
# End of user variables

# Get the Policy Assignment
$PolicyAssignment = Get-AzPolicyAssignment -Name $PolicyAssignmentName -Scope "/providers/Microsoft.Management/managementGroups/$ManagementGroupID"

# Loop through each resource and create exemptions
foreach ($ResourceID in $ResourceIDs) {

    $ResourceName = $resourceid.split('/')[-1]
    $PolicyExemptionName = "$ResourceName-$Date"
    $PolicyExemptionDisplayName = "$PolicyExemptionDisplayNamePrefix $ResourceName - $Date"
    $PolicyExemptionScope = $ResourceID

    New-AzPolicyExemption -name $PolicyExemptionName `
                            -Description $PolicyExemptionDesc `
                            -DisplayName $PolicyExemptionDisplayname `
                            -ExemptionCategory $PolicyExemptionCategory `
                            -ExpiresOn $ExpireOn `
                            -PolicyAssignment $PolicyAssignment `
                            -PolicyDefinitionReferenceId $PolicyDefinitionReferenceId `
                            -Scope $PolicyExemptionScope `
                            -Metadata $PolicyExemptionMetadata

}