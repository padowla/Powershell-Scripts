#Import active directory module for running AD cmdlets

Import-Module activedirectory
$count = 0

$GroupsFromDomain = Import-csv "C:\Users\adm.samuelep\Downloads\Migrate-Group-Membership-AD\groups-from-domain.csv" -Delimiter ";"

$GroupsFromDomain | Format-Table

foreach ($Group in $GroupsFromDomain) {
    Write-Output "Total number of members of group $($Group.Groups): $((Get-ADGroup $Group.Groups -Properties *).Member.Count) "
    #Write-Output "Members of group: $($Group.Groups)"
    Get-ADGroupMember -Identity $Group.Groups | select SamAccountName | Export-CSV -Path "C:\Users\adm.samuelep\Downloads\Migrate-Group-Membership-AD\$($Group.Groups).csv" -Notypeinformation
}