# Below script used to test multiple ports with multiple Servers
# First Execute the function and run the commands given in below script

Function Test-PortConnection {
    [CmdletBinding()]

    # Parameters used in this function
    Param
    (
        [Parameter(Position=0, Mandatory = $True, HelpMessage="Provide destination source", ValueFromPipeline = $true)]
        $Destination,

        [Parameter(Position=1, Mandatory = $False, HelpMessage="Provide port numbers", ValueFromPipeline = $true)]
        $Ports = "80"
    ) 
 
    $ErrorActionPreference = "SilentlyContinue"
    $Results = @()

    ForEach($D in $Destination){
        # Create a custom object
        $Object = New-Object PSCustomObject
        $Object | Add-Member -MemberType NoteProperty -Name "Destination" -Value $D

        Write-Verbose "Checking $D"
        ForEach ($P in $Ports){
            $Result = (Test-NetConnection -Port $p -ComputerName $D ).TCPTestSucceeded  
 
            If(!$Result){
                $Status = "Failure"
            }
            Else{
                $Status = "Success"
            }

            $Object | Add-Member Noteproperty "$("Port " + "$p")" -Value "$($status)"
        }

        $Results += $Object

# or easier way true/false value
        ForEach ($P in $Ports){
            $Result = $null
            $Result = Test-NetConnection -Port $p -ComputerName $D -InformationLevel Quiet
            $Object | Add-Member Noteproperty "$("Port " + "$p")" -Value "$($Result)"
        }
        $Results += $Object
    }

# Final results displayed in new pop-up window
If($Results){
    $Results
}
} 


# Execute below after executing above function


Test-PortConnection -Destination <Server Name> -Ports 445  | Export-Csv -Path C:\users\$env:username\desktop\results.csv -NoTypeInformation
#Test-PortConnection -Destination DC01 -Ports 363,80,1433
#Test-PortConnection -Destination DC01,DC02 -Ports 363,80,1433
#Test-PortConnection -Destination DC01,DC02 -Ports 363,80 | Export-Csv -Path C:\users\$env:username\desktop\results.csv -NoTypeInformation # Save it to CSV file on your desktop
#Test-PortConnection -Destination (GC "C:\Temp\Servers.txt") -Ports 363,80,1433
#Test-PortConnection -Destination (GC "C:\Temp\Servers.txt") -Ports 363,80,1433 | Out-GridView -Title "Results" # Display in new pop-up window
