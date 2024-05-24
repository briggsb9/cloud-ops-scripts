# For Firewall in forced tunneling mode (with management IP)

# Firewall Variables
$FWName = "fw-lafwstortests"
$ResourceGroupName = "rg-lafwstor-test"
$VNetName = "vnet-lafwstor-tests-hub"
$FWPublicip = "pip-lafwstor-tests"
$MgmtPip = "pip-lafwstor-mgmt"


try {
    $azfwStatus = (Get-AzFirewall -Name $FWName -ResourceGroupName $ResourceGroupName).ProvisioningState

    if ($azfwStatus -eq "Succeeded") {
        Write-Output "Stopping Firewall..."
        try {
            # Stop an existing firewall
            $azfw = Get-AzFirewall -Name $FWName -ResourceGroupName $ResourceGroupName
            $azfw.Deallocate()
            Set-AzFirewall -AzureFirewall $azfw
            Write-Output "Firewall Stopped"
        }
        catch {
            Write-Error "Failed to stop the firewall. Error: $_"
        }
    }
    else {
        Write-Output "Starting Firewall..."
        try {
            # Start the firewall
            $azfw = Get-AzFirewall -Name $FWName -ResourceGroupName $ResourceGroupName
            $vnet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $VNetName
            $pip = Get-AzPublicIpAddress -ResourceGroupName $ResourceGroupName -Name $FWPublicip
            $mgmtPip2 = Get-AzPublicIpAddress -ResourceGroupName $ResourceGroupName -Name $MgmtPip
            $azfw.Allocate($vnet, $pip, $mgmtPip2)
            $azfw | Set-AzFirewall
            Write-Output "Firewall Started"
        }
        catch {
            Write-Error "Failed to start the firewall. Error: $_"
        }
    }
}
catch {
    Write-Error "Failed to get the firewall status. Error: $_"
}




