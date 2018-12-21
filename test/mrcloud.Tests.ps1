param(
    $AccessKey,
    $SecretKey
)
#recommended usage : Invoke-Pester -script @{ Parameters = @{accesskey = 'your access key' ;secretkey = 'your secret key'};path='test file path'}
#Variable initialization
$ModuleManifestName = 'mrcloud.psd1'
$ModuleManifestPath = "$PSScriptRoot\..\$ModuleManifestName"
$global:instanceid = $null
$region = 'ap-south-1'

if (!$AccessKey -or !$SecretKey) {
    $AccessKey = Read-Host "Enter Access key for AWS" 
    $SecretKey = Read-Host "Enter Secret key for AWS"
}


Describe 'Module Manifest Tests' {
    It 'Passes Test-ModuleManifest' {
        Test-ModuleManifest -Path $ModuleManifestPath | Should Not BeNullOrEmpty
        $? | Should Be $true
    }
    It 'Passes import ModuleManifest' {
        Import-Module $ModuleManifestPath
        $? | Should Be $true
    }

}
Describe 'AWS VDC Tests' {
    Import-Module $ModuleManifestPath
    It 'Passes public VDC creation' {
        new-awsVDC -AccessKey $AccessKey -Secretkey $SecretKey -region $region -cidr 10.4.0.0/16 -subnetcidr 10.4.0.0/24 -public $true -name "VPC mark1"
        $? | Should Be $true
    }
    It 'Passes public and private VDC creation' {
        new-awsVDC -AccessKey $AccessKey -Secretkey $SecretKey -region $region -cidr 10.2.0.0/16 -subnetcidr 10.2.0.0/24, 10.2.2.0/24 -public $true, $false -name "VPC mark2"
        $? | Should Be $true
    }
}
Describe 'AWS VM tests' {
    Import-Module $ModuleManifestPath
    It 'Passes VM Creation' {

        $params = @{
            ImageId         = 'ami-fedb8f91'
            InstanceType    = 't2.micro' 
            SecurityGroupId = New-EC2SecurityGroup -GroupName (New-Guid).ToString() -GroupDescription test -AccessKey $AccessKey -SecretKey $Secretkey -Region $region
            KeyName         = 'sshkey' 
            AccessKey       = $AccessKey
            SecretKey       = $Secretkey
            region          = $region
            name            = "Salamander"
            ea              = "stop"
        }
        $VM = new-awsVM @params
        $? | Should Be $true
        $global:instanceid = $VM.RunningInstance.instanceid
        write-host "Waiting for instance to start $instanceid"
        while ((get-ec2instance -InstanceId $global:instanceid -Region $region -AccessKey $AccessKey -SecretKey $Secretkey).runninginstance.state.Name -ne 'running') {
            write-host -NoNewline "."
            Start-Sleep 10
        }
        
    }
    It 'Passes VM stop' {

        $params = @{
            instanceid = $global:instanceid
            AccessKey  = $AccessKey
            SecretKey  = $Secretkey
            region     = $region
            ea         = "stop"
        }
        stop-awsVM @params 
        $? | Should Be $true
        while ((get-ec2instance -InstanceId $global:instanceid -Region $region -AccessKey $AccessKey -SecretKey $Secretkey).runninginstance.state.Name -ne 'stopped') {
            write-host -NoNewline "."
            Start-Sleep 10
        }
    }
    It 'Passes VM start' {

        $params = @{
            instanceid = $global:instanceid
            AccessKey  = $AccessKey
            SecretKey  = $Secretkey
            region     = $region
            ea         = "stop"
        }
        start-awsVM @params
        $? | Should Be $true
        while ((get-ec2instance -InstanceId $global:instanceid -Region $region -AccessKey $AccessKey -SecretKey $Secretkey).runninginstance.state.Name -ne 'running') {
            write-host -NoNewline "."
            Start-Sleep 10
        }
    }
    It 'Passes VM delete' {

        $params = @{
            instanceid = $global:instanceid
            AccessKey  = $AccessKey
            SecretKey  = $Secretkey
            region     = $region
            ea         = "stop"
        }
        remove-awsVM @params 
        $? | Should Be $true
    }
}

