# Use this script to create a policy exemption from a list of VMs
$Date = Get-Date -Format "MM-dd-yyyy-HH-mm-ss"
$PolicyExemptionName = "vm-exemption-$Date"
$PolicyExemptionDesc = "These VMs are exempt from endpoint protection checks"
$PolicyExemptionDisplayName = "Endpoint protection exemption - $Date"
$PolicyExemptionCategory = "waiver"
$ExpireOn = "2023-12-23T00:00:00"
#$PolicyExemptionMetadata = "RequestedBy=ts" "ApprovedBy=azsec" "ApprovedOn=18/07/2022" "TicketRef=123456789"
$PolicyAssignmentName = "fa57ee6c7928459e927993df"
$ManagementGroupID = "198d43e1-63f3-4d39-87bd-9a99b4598f8b"
# policy definition reference id is only needed for policy initiative
$PolicyDefinitionReferenceId = "installEndpointProtection"
$PolicyExemptionScope = "/subscriptions/c624c6dc-826d-47e9-879a-d1ec7af0c4e1/resourceGroups/dns/providers/Microsoft.Compute/virtualMachines/vm9345345"


#Get the Policy Assignment
$PolicyAssignment = Get-AzPolicyAssignment -Name $PolicyAssignmentName -Scope "/providers/Microsoft.Management/managementGroups/$ManagementGroupID"

New-AzPolicyExemption -name $PolicyExemptionName `
                        -Description $PolicyExemptionDesc `
                        -DisplayName $PolicyExemptionDisplayname `
                        -ExemptionCategory $PolicyExemptionCategory `
                        -ExpiresOn $ExpireOn `
                        -PolicyAssignment $PolicyAssignment `
                        -PolicyDefinitionReferenceId $PolicyDefinitionReferenceId `
                        -Scope $PolicyExemptionScope
                        #-Metadata $PolicyExemptionMetadata[@] `
