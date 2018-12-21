# Script VDCManager
<# .SYNOPSIS
     Script to manage VDC in a multi-cloud environment
.DESCRIPTION
     Script to manage VDC lifecycle such as create,start,stop,delete VMs in a multi-cloud environment
.NOTES
     Author: Abhijith Nair
#>
function new-AzrVDC {
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
        [parameter(mandatory = $true)]
        [string]
        $region,
        [parameter(mandatory = $true)]
        [string]
        $cidr,
        [parameter(mandatory = $true)]
        [string[]]
        $subnetcidr,
        [parameter(mandatory = $true)]
        [string[]]
        $subnetnames
    )
    try{
    connect-azr -username $username -password $password -Subscription $subscription -ea stop

    if (-not (Get-AzureRmResourceGroup -Name $resgrp -ErrorAction SilentlyContinue)) {
        New-AzureRmResourceGroup -Name $resgrp -Location $region
    }
    $subnets = @()
    for ($count = 0; $count -lt $subnetcidr.Count; $count++) {
        $subnets += New-AzureRmVirtualNetworkSubnetConfig -Name $subnetnames[$count] -AddressPrefix $subnetcidr[$count]
    }
    New-AzureRmVirtualNetwork -Name $name -ResourceGroupName $resgrp -Location centralus -AddressPrefix $cidr -Subnet $subnets
    }
    catch{
        $PSCmdlet.WriteError($_)
}
}
function new-awsVDC {
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
        $region,
        [parameter(mandatory = $true)]
        [string]
        $cidr,
        [parameter(mandatory = $true)]
        [string[]]
        $subnetcidr,
        [bool[]]
        $public,
        [string]
        $name
    )
    try{
    $vpc = New-ec2vpc -cidrblock $cidr -AccessKey $accesskey -SecretKey $secretkey -Region $region
    if($name){
        $tag = New-Object -TypeName Amazon.EC2.Model.Tag -ArgumentList @('Name', $name)
        New-EC2Tag -Tag $tag -Resource $vpc.VpcId -AccessKey $accesskey -SecretKey $secretkey -region $region
    } 
    if ($public -contains $true) {
        $igw = New-EC2InternetGateway -Region $region -AccessKey $accesskey -SecretKey $secretkey
        Add-EC2InternetGateway -InternetGatewayId $igw.InternetGatewayId -VpcId $vpc.VpcId -Region $region -AccessKey $accesskey -SecretKey $secretkey
    }
    for ($count = 0; $count -lt $subnetcidr.Count; $count++) {
        $subnet = New-EC2Subnet -VpcId  $vpc.VpcId -CidrBlock $subnetcidr[$count] -Region $region -AccessKey $accesskey -SecretKey $secretkey
        if ($public[$count]) {
           
            $routetable = New-EC2RouteTable -VpcId  $vpc.VpcId -Region $region -AccessKey $accesskey -SecretKey $secretkey 
            New-EC2Route -RouteTableId $routetable.RouteTableId -DestinationCidrBlock 0.0.0.0/0 -GatewayId $igw.InternetGatewayId -AccessKey $accesskey -SecretKey $secretkey -Region $region
            Register-EC2RouteTable -RouteTableId $routetable.RouteTableId -SubnetId $subnet.SubnetId -AccessKey $accesskey -SecretKey $secretkey -Region $region
        }
    }
}
catch{
    $PSCmdlet.WriteError($_)
}
}