#Test cases for Azure components


#Variable initialization
$ModuleManifestName = 'mrcloud.psd1'
$ModuleManifestPath = "$PSScriptRoot\..\$ModuleManifestName"
$region = 'centralus'


$username = Read-Host "Enter username for Azure"
$password = Read-Host "Enter password for Azure" 
$subscription = Read-Host "Enter subscription for Azure" 

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

Describe 'Azure VDC tests' {
    It 'Passes VDC creation' {
        $params = @{
            username     = $username;
            password     = $password;
            subscription = $subscription;
            name         = "rajasingh";
            resgrp       = "RG36";
            region       = $region;
            cidr         = "10.0.0.0/16";
            subnetcidr   = "10.0.1.0/24", "10.0.2.0/24";
            subnetnames  = "test1", "test2";
            ea           = "stop";
   
        }
        new-azrVDC @params
        $? | Should be $true
    }
}
Describe 'Azure VM tests' {
    It 'Passes VM stop' {
        $params = @{
            username     = $username;
            password     = $password;
            subscription = $subscription;
            name         = "tesla";
            resgrp       = "RG36";
        }
        stop-azrVM @params
        $? | Should be $true
    }
    It 'Passes VM start' {
        $params = @{
            username     = $username;
            password     = $password;
            subscription = $subscription;
            name         = "tesla";
            resgrp       = "RG36";
        }
        start-azrVM @params
        $? | Should be $true
    }
    It 'Passes VM removal' {
        $params = @{
            username     = $username;
            password     = $password;
            subscription = $subscription;
            name         = "tesla";
            resgrp       = "RG36";
            removeDependency = $true
        }
        remove-azrVM @params
        $? | Should be $true
    }
}