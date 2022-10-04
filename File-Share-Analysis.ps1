<#    


          DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
                   Version 2, December 2004
 
Copyright (C) 2004 Sam Hocevar <sam@hocevar.net>

Everyone is permitted to copy and distribute verbatim or modified
copies of this license document, and changing it is allowed as long
as the name is changed.
 
           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
  TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION

 0. You just DO WHAT THE FUCK YOU WANT TO.
 
 
 #>
 
 function Get-LastWriteTime {

    <#
.SYNOPSIS
    Returns the datetime of the last recorded change. In case of empty datetime, 
    the analyzed folder does not contain any files or sub-folders.
.DESCRIPTION
    Get-LastWriteTime is a function that returns the datetime of the last recorded change. 
    In case of empty datetime, the analyzed folder does not contain any files or sub-folders.

.PARAMETER Path
    The path to the folder or file whose last modification datetime is to be obtained.

.EXAMPLE
     Get-LastWriteTime -Path 'C:\'

.EXAMPLE
     'Server1', 'Server2' | Get-LastWriteTime

.INPUTS
    String

.OUTPUTS
    String

.NOTES
    Author:  Samuele Padula
    Website: https://hi.samuelepadula.org/
#>

    param (
        [Parameter(Mandatory = $True)]
        [string]
        $Path
    )
    
    try {
        $item = Get-ChildItem "$Path" -ErrorAction Stop
    }
    catch {
        return "Access denied"    
    }
    
    $lastWriteTime = ( $item | Select-Object LastWriteTime | Sort-Object  -pro LastWriteTime -Descending | Select-Object -First 1).LastWriteTime
    if ($lastWriteTime) {
        return $lastWriteTime
    }
    else {
        return "Empty folder"
    }
}

function Test-IsNetworkShared {

    <#
.SYNOPSIS
    Returns true if the path provided is shared. Otherwise return false.
.DESCRIPTION
    Test-IsNetworkShared is a function that returns True if path provided as parameter is
    a network share folder, otherwise return False.
.PARAMETER Path
    The path to the folder or file to check if is shared.

.EXAMPLE
     Test-IsNetworkShared -Path 'C:\'

.EXAMPLE
     'Share1', 'Share2' | Test-IsNetworkShared

.INPUTS
    String

.OUTPUTS
    Bool

.NOTES
    Author:  Samuele Padula
    Website: https://hi.samuelepadula.org/
#>

    param (
        [Parameter(Mandatory = $True)]
        [string]
        $Path
    )

    $PathReplaced = $Path.Replace('\', '\\')
    [bool](Get-WmiObject -Class Win32_Share -ComputerName $env:COMPUTERNAME -Filter "Path='$PathReplaced'" -ErrorAction SilentlyContinue)

}

function Get-Size {

    <#
.SYNOPSIS
    Returns the size with provided data format (GB,MB,KB) and 2 decimals.

.DESCRIPTION
    Get-Size is a function that returns the size with provided data format for the 
    file or directory provided with Path parameter.

.PARAMETER Path
    The path to the folder or file.

.PARAMETER DataFormat
    The data format availables: GB, MB, KB   

.EXAMPLE
        Get-Size -Path 'C:\' -DataFormat MB

.INPUTS
    String

.OUTPUTS
    String

.NOTES
    Author:  Samuele Padula
    Website: https://hi.samuelepadula.org/
#>

    param (
        [Parameter(Mandatory = $True)]
        [string]
        $Path,

        [Parameter(Mandatory = $True)]
        [ValidateSet("GB", "MB", "KB")]
        [string]
        $DataFormat
    )
    
    $measure = (Get-ChildItem $Path -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue ).Sum

    if ($item -Or $measure) {
        #if measure is not null
        Switch ($DataFormat) {
            "GB" { ("{0:N2} $DataFormat" -f ($measure / 1GB)).Replace(',', '.') } #replace , with . to avoid problem during exporting CSV
            "MB" { ("{0:N2} $DataFormat" -f ($measure / 1MB)).Replace(',', '.') } #replace , with . to avoid problem during exporting CSV
            "KB" { ("{0:N2} $DataFormat" -f ($measure / 1KB)).Replace(',', '.') } #replace , with . to avoid problem during exporting CSV
        } 
    }
    else {
        return "Not Defined"
    }   
}

function Initialize-Env {
    <#
.SYNOPSIS
    Initialize the environment of application by creating all support files.

.DESCRIPTION
    Initialize-Env is a function that creates an empty CSV file that will contains
    all network shares and populate it with an header row.
    Name,Path,Depth

    Name: is the name of network share to analyze
    Path: is the path of network share in the file system
    Depth: is the depth of the share folders to be analyzed

    After that, obtain all the network shares, populates the file with Name, Path and a default
    value for the Depth of each share to analyze (default value = 1) and asks the user to
    review and approve or not the content of CSV by saving the file.
    
    Also prepare the final report CSV file, by adding to the header row.
    
.PARAMETER SharesCsv
    The path to the file that will contain the shares to analyze.

.PARAMETER ReportCsv
    The path to the file that will contain the final report.

.EXAMPLE
    Initialize-Env -Path 'C:\share2analyze.csv'

.INPUTS
    Not available

.OUTPUTS
    Object[] : return the array of objects containing all the shares to analyze

.NOTES
    Author:  Samuele Padula
    Website: https://hi.samuelepadula.org/
#>
    param (
        [Parameter(Mandatory = $True)]
        [string]
        $SharesCsv,

        [Parameter(Mandatory = $True)]
        [string]
        $ReportCSV
    )

    #create new empty files
    $null = New-Item $SharesCsv -type file -Force 
    $null = Add-Content $SharesCsv 'Name,Path,Depth'

    #create a dummy object to write ONLY the header inside report file
    $dummyAclDirectory = New-Object PsObject -property @{
        'Folder Path'            = ""
        'Shared'                 = ""
        'ComputerName'           = ""
        'Permissions'            = ""
        'Note'                   = ""
        'Size'                   = ""
        'Last Modification Time' = ""
    }

    $dummyAclDirectory | ConvertTo-Csv -NoTypeInformation | Select-Object -First 1 | Set-Content $ReportCSV #-First parameter allow to dump only the first row

    #obtain all shares
    $shares = Get-WMIObject -Query "SELECT * FROM Win32_Share"

    #extract for each object in shares the name and path and write in CSV
    foreach ($share in $shares) {
        $Name = $share.Name
        $Path = $share.Path
        $Depth = 1
        Add-Content $SharesCsv "`n$Name,$Path,$Depth"
    }

    $response = Read-Host "Review list of shares to analyze in file '$SharesCsv' and then press 'y'. Otherwise press 'n' to Exit."

    if ($response -ne "y") {
        exit
    }
    else {
        return Import-CSV -Path $SharesCsv
    }
}

function Get-Dirs {
    <#
.SYNOPSIS
    Return the list of path directories.

.DESCRIPTION
    Get-Dirs is a function that returns the list of path for all directories based on root path
    and depth specified.

.PARAMETER Path
    The path to the folder root.

.PARAMETER ToDepth
    Depth of recursion. Default value = 255.  

.PARAMETER CurrentDepth
    Starting depth. Default value = 0.

.EXAMPLE
    Get-Dirs -Path 'C:\' -ToDepth 3

.INPUTS
    Not available

.OUTPUTS
    Object[]

.NOTES
    Author:  Samuele Padula
    Website: https://hi.samuelepadula.org/
#>
    
    param (
        [Parameter(Mandatory = $False)]
        [string]
        $Path = (Get-Location).ToString(),

        [Parameter(Mandatory = $False)]
        [Byte]
        $ToDepth = 255,

        [Parameter(Mandatory = $False)]
        [Byte]
        $CurrentDepth = 0
    )

    $CurrentDepth++
    If ($CurrentDepth -le $ToDepth) {
        foreach ($item in Get-ChildItem $path) {
            if (Test-Path $item.FullName -PathType Container) {
                $item.FullName
                GetDirs $item.FullName -ToDepth $ToDepth -CurrentDepth $CurrentDepth
            }
        }
    }
}

function Start-Script {
    param (
        [Parameter(Mandatory = $True)]
        [string]
        $ReportCSVFileName,

        [Parameter(Mandatory = $True)]
        [string]
        $SharesCSVFileName
    )

    $PercentComplete = 0
    $CurrentItem = 0
    $TotalItems = 0
    $tempShareFileName = '.tmp.csv'
    $shares = Initialize-Env -SharesCsv $SharesCSVFileName -ReportCsv $ReportCSVFileName

    #calculate total items
    foreach ($share in $shares) {
        $folders = Get-Dirs -Path $share.Path -ToDepth $share.Depth -ErrorAction SilentlyContinue
        $TotalItems += $folders.Count
    }

    foreach ($share in $shares) {
        $folders = Get-Dirs -Path $share.Path -ToDepth $share.Depth -ErrorAction SilentlyContinue
        $outarray = @()
        foreach ($folder in $folders) {
            if ($folder) {
                Write-Progress -Activity "Exporting report of ACLs for all shares in '$SharesCSVFileName' to '$ReportCSVFileName...'" -Status "$PercentComplete% Complete" -PercentComplete $PercentComplete
                #Write-Host "DEBUG -------> $folder"
                $comp = $env:COMPUTERNAME
                $acls = (Get-Acl -Path $folder | Where-Object { !($_.IsInherited) }).Access
                [System.Collections.ArrayList]$permissions = @()
                $permstring = ""
                foreach ($access in $acls) {
                    $null = $permissions.Add($access.AccessControlType.ToString() + " " + $access.IdentityReference.ToString() + ":" + $access.FileSystemRights.ToString() + " [" + "Inherited:" + $access.IsInherited.ToString() + "]")
                    $permstring += $access.AccessControlType.ToString() + " " + $access.IdentityReference.ToString() + ":" + $access.FileSystemRights.ToString() + " [" + "Inherited:" + $access.IsInherited.ToString() + "]||"
                }
                $aclDirectory = New-Object PsObject -property @{
                    'Folder Path'            = $folder
                    'Shared'                 = Test-IsNetworkShared -Path $folder
                    'ComputerName'           = $comp
                    'Permissions'            = $permstring
                    'Note'                   = ""
                    'Size'                   = Get-Size -Path $folder -DataFormat KB
                    'Last Modification Time' = Get-LastWriteTime -Path $folder
                }
        
                $outarray += $aclDirectory
        
                #Since the -Append parameter is not available for the Export-Csv command in Powershell 2.0,
                #use a temporary CSV file and then write its contents in append to the final file
        
                $outarray | ConvertTo-Csv -NoTypeInformation | Select-Object -Skip 1 | Set-Content $tempShareFileName #use Skip parameter to avoid to write header (Size, Last Modification Time,etc..) during every flush to final report
                
                #.NET Methods lives in it's own world when it comes to current directory...
                $tempReportFile = Get-Item $tempShareFileName
                [System.IO.File]::ReadAllText($tempReportFile.FullName) | Out-File $ReportCSVFileName -Append -Encoding Unicode
                $outarray = @()

                #update progress bar
                $CurrentItem++
                $PercentComplete = [int](($CurrentItem / $TotalItems) * 100)
                Start-Sleep -Milliseconds 2500
            }

        }
    }
}

$ReportCSVFileName = 'report.csv'
$SharesCSVFileName = 'shares-to-analyze.csv'
Start-Script -ReportCSVFileName $ReportCSVFileName -SharesCSVFileName $SharesCSVFileName
