# Below script used to test multiple ports with multiple Servers
# First Execute the function and run the commands given in below script

Function Test-PortCustom () {
    [CmdletBinding()]

    # Parameters used in this function
    Param
    (
        [Parameter(Position=0, Mandatory = $True, HelpMessage="Provide destination source", ValueFromPipeline = $true)]
        $Hostname,

        [Parameter(Position=1, Mandatory = $True, HelpMessage="Provide port number", ValueFromPipeline = $true)]
        $Port,

        [Parameter(Position=1, Mandatory = $False, HelpMessage="Provide timeout of request", ValueFromPipeline = $true)]
        $Timeout=100

    ) 

    $ErrorActionPreference = "SilentlyContinue"

    $requestCallback = $state = $null
    $Client = New-Object System.Net.Sockets.TcpClient
    $beginConnect = $client.BeginConnect($hostname,$Port,$requestCallback,$state)
    Start-Sleep -milli $Timeout

    if ($client.Connected){
        $Status = "Success"
    } else {
        $Status = "Failure"
    }

    $Client.Close()

    [pscustomobject]@{hostname=$Hostname;port=$Port;status=$Status}
}

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
            #$Result = (Test-NetConnection -Port $p -ComputerName $D ).TCPTestSucceeded  
            $Result = Test-PortCustom -Hostname $D -Port $p

            If(!$Result){
                $Status = "Failure"
            }
            Else{
                $Status = $Result.Status
            }

            $Object | Add-Member Noteproperty "$("Port " + "$p")" -Value "$($Status)"
        }

        $Results += $Object

      }

    # Final results displayed in new pop-up window
    If($Results){
        $Results
    }
} 


# Execute below after executing above function


#Test-PortConnection -Destination <Server Name> -Ports 445  | Export-Csv -Path C:\users\$env:username\desktop\results.csv -NoTypeInformation
Test-PortConnection -Destination 10.127.110.148 -Ports 135, 137, 139, 464, 445, 389, 636, 3268, 3269, 53, 88, 9389
#Test-PortConnection -Destination DC01,DC02 -Ports 363,80,1433
#Test-PortConnection -Destination DC01,DC02 -Ports 363,80 | Export-Csv -Path C:\users\$env:username\desktop\results.csv -NoTypeInformation # Save it to CSV file on your desktop
#Test-PortConnection -Destination (GC "C:\Temp\Servers.txt") -Ports 363,80,1433
#Test-PortConnection -Destination (GC "C:\Temp\Servers.txt") -Ports 363,80,1433 | Out-GridView -Title "Results" # Display in new pop-up window
