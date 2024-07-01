# Ensure the Azure PowerShell module is installed
Install-Module -Name Az -AllowClobber -Scope CurrentUser

# Import the Az module
Import-Module Az

# Prompt for the source resource group name
$sourceResourceGroupName = Read-Host -Prompt "Enter the source resource group name"

# Validate if the source resource group exists
$sourceResourceGroup = Get-AzResourceGroup -Name $sourceResourceGroupName -ErrorAction SilentlyContinue

if ($null -eq $sourceResourceGroup) {
    Write-Host "Source resource group '$sourceResourceGroupName' does not exist." -ForegroundColor Red
    exit
}

# Prompt for the new resource group name
$newResourceGroupName = Read-Host -Prompt "Enter the new resource group name"

# Create the new resource group with the same location as the source resource group
New-AzResourceGroup -Name $newResourceGroupName -Location $sourceResourceGroup.Location -Tag $sourceResourceGroup.Tags

# Output the details of the new resource group
$newResourceGroup = Get-AzResourceGroup -Name $newResourceGroupName
Write-Host "New resource group '$newResourceGroupName' created with the following details:"
$newResourceGroup | Format-List

# Get the role assignments for the source resource group
$roleAssignments = Get-AzRoleAssignment -ResourceGroupName $sourceResourceGroupName | Where-Object { $_.Scope -eq "/subscriptions/$($sourceResourceGroup.SubscriptionId)/resourceGroups/$sourceResourceGroupName" }

# Copy the role assignments to the new resource group
foreach ($roleAssignment in $roleAssignments) {
    New-AzRoleAssignment -ObjectId $roleAssignment.PrincipalId -RoleDefinitionName $roleAssignment.RoleDefinitionName -ResourceGroupName $newResourceGroupName
}

Write-Host "Role assignments copied to the new resource group '$newResourceGroupName'."
