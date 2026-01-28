Clear-Host
write-host "Starting script at $(Get-Date)"

# Generate unique random suffix
[string]$suffix =  -join ((48..57) + (97..122) | Get-Random -Count 7 | % {[char]$_})
$resourceGroupName = "msl-$suffix"

Write-Output "Using resource group name: $resourceGroupName"

# Handle cases where the user has multiple subscriptions
$subs = Get-AzSubscription | Select-Object
if($subs.GetType().IsArray -and $subs.length -gt 1){
    Write-Host "You have multiple Azure subscriptions - please select the one you want to use:"
    for($i = 0; $i -lt $subs.length; $i++)
    {
            Write-Host "[$($i)]: $($subs[$i].Name) (ID = $($subs[$i].Id))"
    }
    $selectedIndex = -1
    $selectedValidIndex = 0
    while ($selectedValidIndex -ne 1)
    {
            $enteredValue = Read-Host("Enter 0 to $($subs.Length - 1)")
            if (-not ([string]::IsNullOrEmpty($enteredValue)))
            {
                if ([int]$enteredValue -in (0..$($subs.Length - 1)))
                {
                    $selectedIndex = [int]$enteredValue
                    $selectedValidIndex = 1
                }
                else
                {
                    Write-Output "Please enter a valid subscription number."
                }
            }
            else
            {
                Write-Output "Please enter a valid subscription number."
            }
    }
    $selectedSub = $subs[$selectedIndex].Id
    Select-AzSubscription -SubscriptionId $selectedSub
    az account set --subscription $selectedSub
}

# Configure Azure CLI to allow preview extensions
az config set extension.dynamic_install_allow_preview=true --only-show-errors

# Register resource providers
Write-Host "Registering resource providers...";
$provider_list = "Microsoft.Storage", "Microsoft.Databricks"
foreach ($provider in $provider_list){
    $result = Register-AzResourceProvider -ProviderNamespace $provider
    $status = $result.RegistrationState
    Write-Host "$provider : $status"
}

# Get a list of locations for Azure Databricks. These regions support Serverless compute for notebooks, jobs, pipelines, and SQL warehouses
$supported_regions = "australiaeast","australiasoutheast","brazilsouth","canadacentral","canadaeast","centralindia","centralus","eastasia","eastus","eastus2","francecentral","japaneast","koreacentral","mexicocentral","northcentralus","northeurope","norwayeast","southafricanorth","southcentralus","southeastasia","swedencentral","switzerlandnorth","uaenorth","uksouth","westcentralus","westeurope","westus","westus2","westus3"

$locations = Get-AzLocation | Where-Object {
    $_.Providers -contains "Microsoft.Databricks" -and
    $_.Location -in $supported_regions
}
$max_index = $locations.Count - 1
$rand = (0..$max_index) | Get-Random

# Start with preferred region if specified, otherwise choose one at random
if ($args.count -gt 0 -And $args[0] -in $locations.Location)
{
    $Region = $args[0]
}
else {
    $Region = $locations.Get($rand).Location
}

# Create Azure Databricks workspace
write-host "Using region: $Region"
Write-Host "Creating $resourceGroupName resource group ..."
az group create --name $resourceGroupName --location $Region --output none
$dbworkspace = "databricks-$suffix"
Write-Host "Creating $dbworkspace Azure Databricks workspace in $resourceGroupName resource group..."
az databricks workspace create --name $dbworkspace --resource-group $resourceGroupName --location $Region --sku premium --output none

write-host "Script completed at $(Get-Date)"