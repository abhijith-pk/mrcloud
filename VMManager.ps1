# Script VMManager
<# .SYNOPSIS
     Script to manage VM in a multi-cloud environment
.DESCRIPTION
     Script to manage VM lifecycle such as create,start,stop,delete VMs in a multi-cloud environment
.NOTES
     Author: Abhijith Nair 
#>

function new-awsVM {
    [CmdletBinding()]
    param(
        [parameter(mandatory = $true)]
        [string]
        $AccessKey,
        [parameter(mandatory = $true)]
        [string]
        $Secretkey,
        [parameter(mandatory = $true)]
        [string]
        $instancetype,
        [parameter(mandatory = $true)]
        [string]
        $imageid,
        [parameter(mandatory = $true)]
        [string]
        $KeyName,
        [string]
        $SecurityGroupId,
        [parameter(mandatory = $true)]
        [string]
        $region,
        [string]
        $name

    )
    try {
        if (!$SecurityGroupId) {
            $SecurityGroupId = New-EC2SecurityGroup -GroupName (New-Guid).ToString() -GroupDescription test -AccessKey $AccessKey -SecretKey $Secretkey
        }

        $params = @{
            ImageId         = $imageid
            InstanceType    = $instancetype 
            SecurityGroupId = $SecurityGroupId
            KeyName         = $KeyName 
            AccessKey       = $AccessKey
            SecretKey       = $Secretkey
            region          = $region

        }

        $instance = New-EC2Instance @params
        if($name){
            $tag = New-Object -TypeName Amazon.EC2.Model.Tag -ArgumentList @('Name', $name)
            New-EC2Tag -Tag $tag -Resource $instance.RunningInstance.instanceid -AccessKey $accesskey -SecretKey $secretkey -region $region
        }
        return $instance
    }
    catch {
        $PSCmdlet.WriteError($_)
    }
}

function remove-awsVM {
    [CmdletBinding()]
    param(
        [parameter(mandatory = $true)]
        [string]
        $AccessKey,
        [parameter(mandatory = $true)]
        [string]
        $Secretkey,
        [parameter(mandatory = $true)]
        [string]
        $instanceid,
        [parameter(mandatory = $true)]
        [string]
        $region

    )
    try {
        $params = @{
            instanceid = $instanceid
            AccessKey  = $AccessKey
            SecretKey  = $Secretkey
            confirm    = $false
            force      = $true
            region     = $region
        }

        Remove-EC2Instance  @params
    }
    catch {
        $PSCmdlet.WriteError($_)
    }
}
function stop-awsVM {
    [CmdletBinding()]
    param(
        [parameter(mandatory = $true)]
        [string]
        $AccessKey,
        [parameter(mandatory = $true)]
        [string]
        $Secretkey,
        [parameter(mandatory = $true)]
        [string]
        $instanceid,
        [parameter(mandatory = $true)]
        [string]
        $region

    )
    try {
        $params = @{
            instanceid = $instanceid
            AccessKey  = $AccessKey
            SecretKey  = $Secretkey
            region     = $region
        }

        stop-EC2Instance  @params
    }
    catch {
        $PSCmdlet.WriteError($_)
    }
}

function start-awsVM {
    [CmdletBinding()]
    param(
        [parameter(mandatory = $true)]
        [string]
        $AccessKey,
        [parameter(mandatory = $true)]
        [string]
        $Secretkey,
        [parameter(mandatory = $true)]
        [string]
        $instanceid,
        [parameter(mandatory = $true)]
        [string]
        $region

    )
    try {
        $params = @{
            instanceid = $instanceid
            AccessKey  = $AccessKey
            SecretKey  = $Secretkey
            region     = $region
        }

        start-EC2Instance  @params
    }
    catch {
        $PSCmdlet.WriteError($_)
    }
}

function start-AzrVM {
    [CmdletBinding()]
    param(
        [parameter(mandatory = $true)]
        [string]
        $username,      
        [parameter(mandatory = $true)]
        [string]
        $password,
        [parameter(mandatory = $true)]
        [string]
        $subscription,      
        [parameter(mandatory = $true)]
        [string]
        $name,      
        [parameter(mandatory = $true)]
        [string]
        $resgrp
    )
    try {
        connect-azr -username $username -password $password -Subscription $subscription -ea stop
        Start-AzureRmVM -Name $name -ResourceGroupName $resgrp -Confirm:$false
    }
    catch {
        $PSCmdlet.WriteError($_)
    }
}
function stop-AzrVM {
    [CmdletBinding()]
    param(
        [parameter(mandatory = $true)]
        [string]
        $username,      
        [parameter(mandatory = $true)]
        [string]
        $password,
        [parameter(mandatory = $true)]
        [string]
        $subscription,      
        [parameter(mandatory = $true)]
        [string]
        $name,      
        [parameter(mandatory = $true)]
        [string]
        $resgrp
    )
    try {
        connect-azr -username $username -password $password -Subscription $subscription -ea stop
        stop-AzureRmVM -Name $name -ResourceGroupName $resgrp -Confirm:$false -Force
    }
    catch {
        $PSCmdlet.WriteError($_)
    }
}
function remove-AzrVM {
    [CmdletBinding()]
    param(
        [parameter(mandatory = $true)]
        [string]
        $username,      
        [parameter(mandatory = $true)]
        [string]
        $password,
        [parameter(mandatory = $true)]
        [string]
        $subscription,      
        [parameter(mandatory = $true)]
        [string]
        $name,      
        [parameter(mandatory = $true)]
        [string]
        $resgrp,
        [switch]
        $removeDependency
    )
    try {
        connect-azr -username $username -password $password -Subscription $subscription -ea stop
        $vm = Get-AzureRmVm -Name $name -ResourceGroupName $resgrp
        #Remove VM
        remove-AzureRmVM -Name $name -ResourceGroupName $resgrp -Confirm:$false -Force
        if ($removeDependency) {
            #Remove associated NICs
            foreach ($nicUri in $vm.NetworkInterfaceIDs) {
                $nic = Get-AzureRmNetworkInterface -ResourceGroupName $vm.ResourceGroupName -Name $nicUri.Split('/')[-1]
                Remove-AzureRmNetworkInterface -Name $nic.Name -ResourceGroupName $vm.ResourceGroupName -Force
                foreach ($ipConfig in $nic.IpConfigurations) {
                    if ($ipConfig.PublicIpAddress -ne $null) {
                        #Removing the Public IP Address
                        Remove-AzureRmPublicIpAddress -ResourceGroupName $vm.ResourceGroupName -Name $ipConfig.PublicIpAddress.Id.Split('/')[-1] -Force
                    } 
                }
            }
            #Remove storage
            $osDiskUri = $vm.StorageProfile.OSDisk.Vhd.Uri
            $osDiskContainerName = $osDiskUri.Split('/')[-2]
				
				
            $osDiskStorageAcct = Get-AzureRmStorageAccount | where { $_.StorageAccountName -eq $osDiskUri.Split('/')[2].Split('.')[0] }
            $osDiskStorageAcct | Remove-AzureStorageBlob -Container $osDiskContainerName -Blob $osDiskUri.Split('/')[-1] -ea Ignore
            $osDiskStorageAcct | Get-AzureStorageBlob -Container $osDiskContainerName -Blob "$($vm.Name)*.status" | Remove-AzureStorageBlob
				 
            # Remove any other attached disks
            if ($vm.DataDiskNames.Count -gt 0) {
                foreach ($uri in $vm.StorageProfile.DataDisks.Vhd.Uri) {
                    $dataDiskStorageAcct = Get-AzureRmStorageAccount -Name $uri.Split('/')[2].Split('.')[0]
                    $dataDiskStorageAcct | Remove-AzureStorageBlob -Container $uri.Split('/')[-2] -Blob $uri.Split('/')[-1] -ea Ignore
                }
            }

        }
    }
    catch {
        $PSCmdlet.WriteError($_)
    }
}