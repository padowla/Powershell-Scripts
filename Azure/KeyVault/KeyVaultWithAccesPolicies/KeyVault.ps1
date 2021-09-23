
Param
(
    [Parameter(Mandatory=$true)][String]
    $NameKeyVault,

    [Parameter(Mandatory=$true)][String]
    $ResourceGroupName,

    [String]
    $Location = "westeurope",

    [Parameter(Mandatory=$true)][String]
    [ValidateSet('Standard','Premium')]
    $Sku,

    [Parameter(Mandatory=$true)][String]
    $KAPP,

    [Parameter(Mandatory=$true)][String]
    $ApplicationName,

    [Parameter(Mandatory=$true)][String]
    [ValidateSet('DEV','TEST','PREPROD','PROD')]
    $Environment,

    # Path to file with Access Policy info
    [Parameter(Mandatory=$true)][String]
    $AccessPolicyInputFile,

    # Info required to enable Private Endpoint

    [Parameter(Mandatory=$true)][String]
    $PrivateEndpointName,

    [Parameter(Mandatory=$true)][String]
    $VNetName,

    [Parameter(Mandatory=$true)][String]
    $VNetResourceGroupName,

    [Parameter(Mandatory=$true)][String]
    $SubnetName

)

$Tags = @{KAPP=$KAPP;APPLICATION_NAME=$ApplicationName;ENV=$Environment}
$GroupIds = "vault"

$ErrorActionPreference = "Stop"
#Verify resource group name parameter
$null = Get-AzResourceGroup -Name $ResourceGroupName -ErrorVariable notPresent -ErrorAction SilentlyContinue
if ($notPresent)
{
    # ResourceGroup doesn't exist
    Write-Output "Resource Group $ResourceGroupName doesn't exist!"
}


#Verify resource vnet group name parameter
$null = Get-AzResourceGroup -Name $VNetResourceGroupName -ErrorVariable notPresent -ErrorAction SilentlyContinue
if ($notPresent)
{
    # ResourceGroup doesn't exist
    Write-Output "Resource Group $VNetResourceGroupName doesn't exist!"
}


#Verify location parameter
$LocationsWithAllInfos = Get-AzLocation #array with all available locations
[System.Collections.ArrayList]$AvailableLocations = @() #must be modifiable in lenght
foreach ($loc in $LocationsWithAllInfos){
    $null = $AvailableLocations.Add($loc.Location)
}
if(! $AvailableLocations.Contains($Location)){
    # Location doesn't exist
    Write-Output "Location $Location doesn't exist!"
}


#Verify virtual network name parameter
$VNet = Get-AzVirtualNetwork -Name $VNetName -ResourceGroupName $VNetResourceGroupName -ErrorVariable notPresent -ErrorAction SilentlyContinue
if ($notPresent)
{
    # Virtual network doesn't exist
    Write-Output "Virtual network $VNetName doesn't exist!"
}
#Verify subnet name parameter
$Subnet = Get-AzVirtualNetworkSubnetConfig -Name $SubnetName -VirtualNetwork $VNet -ErrorVariable notPresent -ErrorAction SilentlyContinue
if ($notPresent)
{
    # Subnet doesn't exist
    Write-Output "Subnet $SubnetName doesn't exist!"
}


# 1. Create the Key Vault
Write-Output "################# STEP 1: Create the Key Vault ###################"
$KeyVault = New-AzKeyVault -VaultName $NameKeyVault -ResourceGroupName $ResourceGroupName -Location $Location -Sku $Sku -Tag $Tags
$KeyVaultId = $KeyVault.resourceId
Write-Output "Created Key Vault $NameKeyVault [ID: $KeyVaultId] in resource group $ResourceGroupName with SKU $Sku"

# 2. Set Access Policy entries
Write-Output "################# STEP 2: Set Access Policy entries ###################"

$Policies = Import-Csv -Path $AccessPolicyInputFile -Delimiter ';'

foreach ($Policy in $Policies)
{

    $EntityType = $Policy.EntityType
    $Entity = $Policy.Entity
    $PermissionsToKeys = $Policy.PermissionsToKeys.Split(",") -replace '\s',''
    $PermissionsToSecrets = $Policy.PermissionsToSecrets.Split(",") -replace '\s',''
    $PermissionsToCertificates = $Policy.PermissionsToCertificates.Split(",") -replace '\s',''
    
    # Must distinguish between User and Service Principal
    switch ($EntityType)
    {
        'User' {
                Set-AzKeyVaultAccessPolicy -VaultName $NameKeyVault -UserPrincipalName $Entity -PermissionsToKeys $PermissionsToKeys -PermissionsToSecrets $PermissionsToSecrets -PermissionsToCertificates $PermissionsToCertificates
                Write-Output "Access Policy for user $Entity applied"
        }
        'ServicePrincipal' {
                # Get AD application ID
                $application = Get-AzADApplication -DisplayName $Entity
                $applicationId = $application.ApplicationId
                $applicationObjectId = $application.ObjectId
                #with object id of service principal seems to work
                #use -ObjectId and -ApplicationId create access policy for application with Unknown in "Current Access Policies"
                #Set-AzKeyVaultAccessPolicy -VaultName $NameKeyVault -ObjectId $applicationObjectId -ApplicationId $applicationId -PermissionsToKeys $PermissionsToKeys -PermissionsToSecrets $PermissionsToSecrets -PermissionsToCertificates $PermissionsToCertificates
                #use -ServicePrincipalName parameter with application ID value only if you are user administrator in AzureAD
                Set-AzKeyVaultAccessPolicy -VaultName $NameKeyVault -ServicePrincipalName $applicationId -PermissionsToKeys $PermissionsToKeys -PermissionsToSecrets $PermissionsToSecrets -PermissionsToCertificates $PermissionsToCertificates
                Write-Output "Access Policy for service principal $Entity [applicationID:$applicationId] applied"
        }
    }

}

# 3. Enable Private Endpoint
Write-Output "################# STEP 3: Create Private Link Service Connection ###################"
$privateLinkServiceConnection = New-AzPrivateLinkServiceConnection -Name $NameKeyVault -PrivateLinkServiceId $KeyVaultId -GroupId $GroupIds
$privateLinkResourceId= $privateLinkServiceConnection.Id
Write-Output "Create Private Link Service Connection with name $NameKeyVault bound to Key Vault $KeyVaultId"

# 4. Disable network policies to avoid ErrorCode: PrivateEndpointCannotBeCreatedInSubnetThatHasNetworkPoliciesEnabled
<#
Network policies like NSGs (Network security groups) previously weren't supported for private endpoints.
To deploy a private endpoint on a given subnet, an explicit disable setting was required on that subnet.
This setting is only applicable for the private endpoint.
For other resources in the subnet, access is controlled based on security rules in the network security group.
https://docs.microsoft.com/en-us/azure//private-link/disable-private-endpoint-network-policy
#>
Write-Output "################# STEP 4: Disable Network Policies ###################"
($VNet | Select -ExpandProperty subnets | Where-Object {$_.Name -eq $SubnetName}).PrivateEndpointNetworkPolicies = "Disabled"
$result = $VNet | Set-AzVirtualNetwork
Write-Output "Disabled network policies"

# 5. Create private endpoint
Write-Output "################# STEP 5: Create Private Endpoint ###################"
$privateEndpoint = New-AzPrivateEndpoint -ResourceGroupName $ResourceGroupName -Location $Location -Name $PrivateEndpointName -Subnet $Subnet -PrivateLinkServiceConnection $privateLinkServiceConnection
Write-Output "Created Private Endpoint with name $PrivateEndpointName bound to subnet $SubnetName in VNet $VNetName"

# 6. Enable access to keyvault only through private endpoints and selected virtual networks
Write-Output "################# STEP 6: Enable access to keyvault through private endpoints and selected vnets ###################" 
$updateNetworkRule = Update-AzKeyVaultNetworkRuleSet -InputObject $KeyVault -DefaultAction Deny -Bypass AzureServices
$updateNetworkRule
Write-Output "Enabled firewall access through private endpoint and selected virtual networks"
