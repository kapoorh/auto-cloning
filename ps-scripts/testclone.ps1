$j = Start-Job -ScriptBlock {
	param($sourceResourceGroupName, $targetResourceGroupName)
	Import-AzureRmContext -Path "./azureprofile.json"

	$debugpreference = "Continue"
    
   # $sourceSubscriptionId =  ''
    ##$data.selectsinglenode("/Configuration").SubscriptionId
    
    Select-AzureRmSubscription -SubscriptionId '25830b8d-9afb-493e-90ff-de7ac92b2494'
    
    

    $vmName = (get-azurermvm -resourcegroupname $sourceResourceGroupName).Name    
            
    $vmOSDiskName = ((get-azurermvm -resourcegroupname $sourceResourceGroupName -name $vmName).StorageProfile).OSDisk
    $vmAllDataDiskNames = (((get-azurermvm -resourcegroupname $sourceResourceGroupName -name $vmName).StorageProfile).DataDisks).Name
    $srcVMDetails = (get-azurermvm -resourcegroupname $sourceResourceGroupName -name $vmName)

    $sourceVMSize = ($srcVMDetails.HardwareProfile).VmSize
    $sourceVMOsType = $srcVMDetails.StorageProfile.OsDisk.osType

    $sourceManagedOSDisk = Get-AzureRMDisk -ResourceGroupName $sourceResourceGroupName -DiskName $vmOSDiskName.Name
    $diskConfig = New-AzureRmDiskConfig -SourceResourceId $sourceManagedOSDisk.Id -Location $sourceManagedOSDisk.Location -CreateOption Copy
  
    #Get-AzureRmResourceGroup -Name $targetResourceGroupName -ErrorVariable notPresent -ErrorAction SilentlyContinue
    #if ($notPresent)
    #{
        #Create new resource group with above mentioned name
        New-AzureRmResourceGroup -Name $targetResourceGroupName -Location $sourceManagedOSDisk.Location
    #}
    #else
    #{
     #   az group delete -n $targetResourceGroupName -y
      #  az group create -l $sourceManagedOSDisk.Location -n $targetResourceGroupName
    #}
    
	
    $targetOSDiskName = $sourceManagedOSDisk.Name
	
	#Copy OS disk from source to target disks (as many time as the for loop runs) 
	New-AzureRmDisk -Disk $diskConfig -DiskName $targetOSDiskName -ResourceGroupName $targetResourceGroupName

    $index = 0;
    $arrSourceDataDisks = 1..$vmAllDataDiskNames.Count
    $arrTargetDataDisks = 1..$vmAllDataDiskNames.Count
    $arrSourceDataDiskConfig = 1..$vmAllDataDiskNames.Count
    $arrTargetDataDiskNames = 1..$vmAllDataDiskNames.Count
    foreach($datadisk in $vmAllDataDiskNames)
	{		
		$arrTargetDataDiskNames[$index] = $datadisk
		$arrSourceDataDisks[$index]= Get-AzureRMDisk -ResourceGroupName $sourceResourceGroupName -DiskName $datadisk
		$arrSourceDataDiskConfig[$index] = New-AzureRmDiskConfig -SourceResourceId $arrSourceDataDisks[$index].Id -Location $arrSourceDataDisks[$index].Location -CreateOption Copy
		New-AzureRmDisk -Disk $arrSourceDataDiskConfig[$index] -DiskName $datadisk -ResourceGroupName $targetResourceGroupName
		$arrTargetDataDisks[$index] = Get-AzureRMDisk -ResourceGroupName $targetResourceGroupName -DiskName $datadisk
		$index = $index + 1
	}	

    #$usrpwd = 'Password123'
    #$usrname = 'demouser'
	
	$command = "az vm create -g $targetResourceGroupName -n $vmName  --attach-os-disk  $targetOSDiskName --os-type " + $sourceVMOsType + " --attach-data-disks "
	for($i=0; $i -le $vmAllDataDiskNames.Count; $i++){
		$command = $command + " " + $arrTargetDataDiskNames[$i]
	}

	$command  = $command + " " + " --size " + $sourceVMSize + " --subnet /subscriptions/25830b8d-9afb-493e-90ff-de7ac92b2494/resourceGroups/Cloning_BaseImage/providers/Microsoft.Network/virtualNetworks/Cloning_BaseImage-vnet/subnets/default"

    Write-Host $command
	Invoke-Expression $command 
    
   # $vm = Get-AzureRmVM -ResourceGroupName $targetResourceGroupName -Name $vmName
    #$vmnic = Get-AzureRmResource -ResourceId $vm.NetworkProfile.NetworkInterfaces[0].Id | Get-AzureRmNetworkInterface | Select Name
    #$nic = Get-AzureRmNetworkInterface -Name $vmnic.Name -ResourceGroup $targetResourceGroupName
    #$nic.IpConfigurations.publicipaddress.id = $null
    #Set-AzureRmNetworkInterface -NetworkInterface $nic
    
    #az vm start --name $vmName --resource-group $sourceResourceGroupName
    
    Start-Sleep -s 15
    
    } -ArgumentList("Cloning_BaseImage", "Cloning_BaseImage_1")
$j | Format-List -Property *
#Write-Host $j
$j | Receive-Job -Wait



