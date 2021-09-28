$ErrorActionPreference = "Stop"
# Path to file with KeyVault info
$KeyVaultInputFile = "KeyVault.csv"
# Path to file with Access Policy info
$AccessPolicyInputFile = "AccessPolicyEntries.csv"
# Path to file with IPs for Firewall
$IPsFirewallInputFile = "Firewall.csv"
# Path to file with VNets for Firewall
$VNetsFirewallInputFile = "VirtualNetworks.csv"
# Service Endpoint Value for KeyVault
$ServiceEndpointValue = "Microsoft.KeyVault"

# 1. Get KeyVault infos
Write-Host "################# STEP 1: Get KeyVault infos ###################"  -ForegroundColor White -BackgroundColor DarkGreen
$KeyVaultInfosFromFile = Import-Csv -Path $KeyVaultInputFile -Delimiter ';'
$KeyVaultName = $KeyVaultInfosFromFile.Name
$KeyVaultResourceGroupName = $KeyVaultInfosFromFile.ResourceGroupName
$KeyVaultLocation = $KeyVaultInfosFromFile.Location
$KeyVaultSKU = $KeyVaultInfosFromFile.SKU
$KAPP = $KeyVaultInfosFromFile.KAPP
$ApplicationName = $KeyVaultInfosFromFile.ApplicationName
$Environment = $KeyVaultInfosFromFile.Environment
$Tags = @{KAPP=$KAPP;APPLICATION_NAME=$ApplicationName;ENV=$Environment}
$GroupIds = "vault"
$PrivateEndpointName = $KeyVaultInfosFromFile.PrivateEndpointName
$KeyVaultVNetName = $KeyVaultInfosFromFile.VNetName
$KeyVaultVNetResourceGroupName = $KeyVaultInfosFromFile.VNetResourceGroupName
$KeyVaultSubnetName = $KeyVaultInfosFromFile.SubnetName
$BypassMSServices = $KeyVaultInfosFromFile.BypassMSServices # Allow trusted Microsoft services to bypass this firewall?
Write-Host "- Name: $KeyVaultName"
Write-Host "- Resource group: $KeyVaultResourceGroupName"
Write-Host "- Location: $KeyVaultLocation"
Write-Host "- SKU: $KeyVaultSKU"
Write-Host "- Tags: KAPP=$KAPP;APPLICATION_NAME=$ApplicationName;ENV=$Environment"

#Verify resource group name parameter
$null = Get-AzResourceGroup -Name $KeyVaultResourceGroupName -ErrorVariable notPresent
if ($notPresent)
{
    # ResourceGroup doesn't exist
    Write-Host "Resource Group $KeyVaultResourceGroupName doesn't exist!"
}


#Verify resource vnet group name parameter
$null = Get-AzResourceGroup -Name $KeyVaultVNetResourceGroupName -ErrorVariable notPresent
if ($notPresent)
{
    # ResourceGroup doesn't exist
    Write-Host "Resource Group $KeyVaultVNetResourceGroupName doesn't exist!"
}


#Verify location parameter
$KeyVaultLocationsWithAllInfos = Get-AzLocation #array with all available locations
[System.Collections.ArrayList]$AvailableLocations = @() #must be modifiable in lenght
foreach ($loc in $KeyVaultLocationsWithAllInfos){
    $null = $AvailableLocations.Add($loc.Location)
}
if(! $AvailableLocations.Contains($KeyVaultLocation)){
    # Location doesn't exist
    Write-Host "Location $KeyVaultLocation doesn't exist!"
}

#Verify SKU parameter
[System.Collections.ArrayList]$AvailableSKUs = @('Standard','Premium') 

if(! $AvailableSKUs.Contains($KeyVaultSKU)){
    # SKU doesn't exist
    Write-Host "SKU $KeyVaultSKU doesn't exist!"
}

#Verify Environment parameter
[System.Collections.ArrayList]$AvailableEnvs = @('DEV','TEST','PREPROD','PROD') 

if(! $AvailableEnvs.Contains($Environment)){
    # Environment doesn't exist
    Write-Host "Environment $Environment doesn't exist!"
}

#Verify virtual network name parameter
$VNet = Get-AzVirtualNetwork -Name $KeyVaultVNetName -ResourceGroupName $KeyVaultVNetResourceGroupName -ErrorVariable notPresent
if ($notPresent)
{
    # Virtual network doesn't exist
    Write-Host "Virtual network $KeyVaultVNetName doesn't exist!"
}

#Verify subnet name parameter
$Subnet = Get-AzVirtualNetworkSubnetConfig -Name $KeyVaultSubnetName -VirtualNetwork $VNet -ErrorVariable notPresent
if ($notPresent)
{
    # Subnet doesn't exist
    Write-Host "Subnet $KeyVaultSubnetName doesn't exist!"
}


# 2. Create the Key Vault 
Write-Host "################# STEP 2: Create the Key Vault ###################"  -ForegroundColor White -BackgroundColor DarkGreen
$KeyVault = New-AzKeyVault -VaultName $KeyVaultName -ResourceGroupName $KeyVaultResourceGroupName -Location $KeyVaultLocation -Sku $KeyVaultSKU -Tag $Tags
$KeyVaultId = $KeyVault.resourceId
Write-Host "Created Key Vault $KeyVaultName [ID: $KeyVaultId] in resource group $KeyVaultResourceGroupName with SKU $KeyVaultSKU"

# 3. Set Access Policy entries
Write-Host "################# STEP 3: Set Access Policy entries ###################"

$PoliciesFromFile = Import-Csv -Path $AccessPolicyInputFile -Delimiter ';'

foreach ($Policy in $PoliciesFromFile)
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
                Set-AzKeyVaultAccessPolicy -VaultName $KeyVaultName -UserPrincipalName $Entity -PermissionsToKeys $PermissionsToKeys -PermissionsToSecrets $PermissionsToSecrets -PermissionsToCertificates $PermissionsToCertificates
                Write-Host "Access Policy for user $Entity applied"
        }
        'ServicePrincipal' {
                # Get AD application ID
                $application = Get-AzADApplication -DisplayName $Entity
                $applicationId = $application.ApplicationId
                $applicationObjectId = $application.ObjectId
                #with object id of service principal seems to work
                #use -ObjectId and -ApplicationId create access policy for application with Unknown in "Current Access Policies"
                #Set-AzKeyVaultAccessPolicy -VaultName $KeyVaultName -ObjectId $applicationObjectId -ApplicationId $applicationId -PermissionsToKeys $PermissionsToKeys -PermissionsToSecrets $PermissionsToSecrets -PermissionsToCertificates $PermissionsToCertificates
                #use -ServicePrincipalName parameter with application ID value only if you are user administrator in AzureAD
                Set-AzKeyVaultAccessPolicy -VaultName $KeyVaultName -ServicePrincipalName $applicationId -PermissionsToKeys $PermissionsToKeys -PermissionsToSecrets $PermissionsToSecrets -PermissionsToCertificates $PermissionsToCertificates
                Write-Host "Access Policy for service principal $Entity [applicationID:$applicationId] applied"
        }
    }

}

# 4. Get allowed virtual networks
Write-Host "################# STEP 4: Get allowed virtual networks ###################"  -ForegroundColor White -BackgroundColor DarkGreen

$VNetsFromFile = Import-Csv -Path $VNetsFirewallInputFile -Delimiter ';'
[System.Collections.ArrayList]$VNetsIdsForFirewall = @() #will contains all VNets IDs (for each subnet) to set in Firewall section
Write-Host "VNets/Subnet Allowed:"
foreach ($VNetForFirewallFromFile in $VNetsFromFile)
{
    $VNetNameForFirewall = $VNetForFirewallFromFile.VirtualNetworkName
    $VNetResourceGroupNameForFirewall = $VNetForFirewallFromFile.ResourceGroupName
    $VNetSubnetNameForFirewall = $VNetForFirewallFromFile.SubnetName

    #Verify virtual network name parameter
    $VNetForFirewall = Get-AzVirtualNetwork -Name $VNetNameForFirewall -ResourceGroupName $VNetResourceGroupNameForFirewall -ErrorVariable notPresent
    if ($notPresent)
    {
        # Virtual network doesn't exist
        Write-Host "Virtual network $VNetNameForFirewall doesn't exist!"
    }

    #Verify subnet name parameter
    $VNetSubnetForFirewall = Get-AzVirtualNetworkSubnetConfig -Name $VNetSubnetNameForFirewall -VirtualNetwork $VNetForFirewall -ErrorVariable notPresent
    if ($notPresent)
    {
        # Subnet doesn't exist
        Write-Host "Subnet $VNetSubnetNameForFirewall doesn't exist!"
    }

    # Enable ServiceEndpoint of KeyVault for allowed VNet/Subnet
    $null = Set-AzVirtualNetworkSubnetConfig -Name $VNetSubnetNameForFirewall -VirtualNetwork $VNetForFirewall -ServiceEndpoint $ServiceEndpointValue -AddressPrefix $VNetSubnetForFirewall.AddressPrefix | Set-AzVirtualNetwork

    $null = $VNetsIdsForFirewall.Add($VNetSubnetForFirewall.Id)
    Write-Host "- $VNetNameForFirewall/$VNetSubnetNameForFirewall"
}

# 5. Enable Private Endpoint
Write-Host "################# STEP 5: Create Private Link Service Connection ###################"  -ForegroundColor White -BackgroundColor DarkGreen
$privateLinkServiceConnection = New-AzPrivateLinkServiceConnection -Name $KeyVaultName -PrivateLinkServiceId $KeyVaultId -GroupId $GroupIds
$privateLinkResourceId= $privateLinkServiceConnection.Id
Write-Host "Created Private Link Service Connection with name $KeyVaultName bound to Key Vault $KeyVaultId"

# 6. Disable network policies to avoid ErrorCode: PrivateEndpointCannotBeCreatedInSubnetThatHasNetworkPoliciesEnabled
<#
Network policies like NSGs (Network security groups) previously weren't supported for private endpoints.
To deploy a private endpoint on a given subnet, an explicit disable setting was required on that subnet.
This setting is only applicable for the private endpoint.
For other resources in the subnet, access is controlled based on security rules in the network security group.
https://docs.microsoft.com/en-us/azure//private-link/disable-private-endpoint-network-policy
#>
Write-Host "################# STEP 6: Disable Network Policies ###################"  -ForegroundColor White -BackgroundColor DarkGreen
($VNet | Select -ExpandProperty subnets | Where-Object {$_.Name -eq $KeyVaultSubnetName}).PrivateEndpointNetworkPolicies = "Disabled"
$result = $VNet | Set-AzVirtualNetwork
Write-Host "Disabled network policies"

# 7. Create private endpoint
Write-Host "################# STEP 7: Create Private Endpoint ###################" -ForegroundColor White -BackgroundColor DarkGreen
$privateEndpoint = New-AzPrivateEndpoint -ResourceGroupName $KeyVaultResourceGroupName -Location $KeyVaultLocation -Name $PrivateEndpointName -Subnet $Subnet -PrivateLinkServiceConnection $privateLinkServiceConnection
Write-Host "Created Private Endpoint with name $PrivateEndpointName bound to subnet $KeyVaultSubnetName in VNet $KeyVaultVNetName"

# 8. Set IPs entries for Firewall
Write-Host "################# STEP 8: Set IPs entries for Firewall ###################"  -ForegroundColor White -BackgroundColor DarkGreen
$IPsForFirewallFromFile = Import-Csv -Path $IPsFirewallInputFile -Delimiter ';'
Write-Host "IPs Allowed:$IPsForFirewallFromFile"
[System.Collections.ArrayList]$IPsForFirewall = @() #will contains all IPs to set in Firewall section

foreach ($IPForFirewall in $IPsForFirewallFromFile)
{
    $null = $IPsForFirewall.Add($IPForFirewall.IP)
}


# 9. Enable access to keyvault only through private endpoints with selected vnets and IPs
Write-Host "################# STEP 9: Enable access to keyvault through private endpoints with selected vnets and IPs ###################"  -ForegroundColor White -BackgroundColor DarkGreen
if($BypassMSServices -eq "yes"){
    $updateNetworkRule = Update-AzKeyVaultNetworkRuleSet -InputObject $KeyVault -DefaultAction Deny -Bypass AzureServices -IpAddressRange $IPsForFirewall -VirtualNetworkResourceId $VNetsIdsForFirewall
    Write-Host "Enabled firewall access through private endpoint with selected vnets and IPs (bypass Microsoft Services enabled)"
}else{
    $updateNetworkRule = Update-AzKeyVaultNetworkRuleSet -InputObject $KeyVault -DefaultAction Deny -Bypass None -IpAddressRange $IPsForFirewall -VirtualNetworkResourceId $VNetsIdsForFirewall
    Write-Host "Enabled firewall access through private endpoint with selected vnets and IPs  (bypass Microsoft Services disabled)"    
}


<#
{
  "keyvault":{
    name : "keyvaulttest",
    resource-group : "test-IAM",
    allowed-ips : [
                "10.0.0.1/32",
                "10.0.0.2/32",
                "10.0.0.3/32"
                ],
    access-policies: {
            users:[]
            applications:[]
    }
   }
}
#>
