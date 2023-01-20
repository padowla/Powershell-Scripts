<#
   This script extracts all the users contained within
   the groups listed in the $csvWindowsGroupsNPSPolicies file
   and of these it selects those with the Reversible Encryption Active Directory flag active.
   For all CSV files don't touch the header and leave it as in file examples!.
#>

$countTotalUsersOfGroups = 0
$csvUsersGroupPolicies = "users-of-groups.csv"
$csvUsersGroupPoliciesWithRevEnc = "users-of-groups--with-rev-enc.csv"
$csvWindowsGroupsNPSPolicies = "groups.csv"
New-Item $csvUsersGroupPolicies -ItemType File -Force
Import-Csv $csvWindowsGroupsNPSPolicies | ForEach{ #leave curly bracket here!!
   # extract total number of members
   $countTotalUsersOfGroups = $countTotalUsersOfGroups + (Get-ADGroup $_.Name -Properties *).Member.Count
   Write-Output "$($_.Name): $((Get-ADGroup $_.Name -Properties *).Member.Count) members"
   Get-ADGroupMember -identity $_.Name | Select name | Export-csv -Path $csvUsersGroupPolicies -Notypeinformation -Append
}

$usersListGroupPolicies = Import-Csv $csvUsersGroupPolicies 
$finalUsersList = [System.Collections.ArrayList]::new()
foreach ($user in $usersListGroupPolicies){
    $targetUser = Get-ADUser -Filter 'userAccountControl -band 128' -Properties Name,userAccountControl, Enabled | Where { $_.Name -eq $user.Name }
    $null = $finalUsersList.Add($targetUser)
}
Write-Output "Total count of groups members: $countTotalUsersOfGroups"
Write-Output "Total count of users with reversible encryption enabled : $($finalUsersList.Count)"
$finalUsersList | Export-Csv -Path $csvUsersGroupPoliciesWithRevEnc -Force -NoTypeInformation
