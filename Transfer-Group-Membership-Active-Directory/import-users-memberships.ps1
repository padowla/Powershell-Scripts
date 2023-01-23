#Import active directory module for running AD cmdlets

Import-Module activedirectory
$count = 0

$GroupsFromDomain = Import-csv "groups-from-domain.csv" -Delimiter ";"

$GroupsFromDomain | Format-Table

foreach ($Group in $GroupsFromDomain) {
    Write-Output "--------------------------------------------------------------------------------------------"
    Write-Output "Membership transfer for the following group: $($Group.Groups)"
    #import previous exported csv from domain of origin
    $GroupCSV = Import-csv "$($Group.Groups).csv" -Delimiter ";"
    #$GroupCSV | Format-Table
    foreach($User in $GroupCSV){
        $ret = Add-ADGroupMember -Identity $Group.Groups -Members $($User.SamAccountName) -PassThru
        #$ret is equal to group if fail to find/add member 
        Write-Output "Member $($User.SamAccountName) added to $($Group.Groups)"
        $count++
      
    }
}

Write-Output "Succesfully transfered $count accounts"
