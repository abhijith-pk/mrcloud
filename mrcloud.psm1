function connect-Azr {
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
        $subscription)
        try{
        $azurePassword = ConvertTo-SecureString $password -AsPlainText -Force
        $psCred = New-Object System.Management.Automation.PSCredential($username, $azurePassword)
        Login-AzureRmAccount -Credential $psCred
        Select-AzureRmSubscription -Subscription $subscription
        }
        catch{
            $PSCmdlet.WriteError($_.exception.message)
        }
    }      
Export-ModuleMember -Function *-*
