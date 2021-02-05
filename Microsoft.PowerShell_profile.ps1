#alias for which command
New-Alias which get-command


#graphical settings

$foregroundColor = 'white'
$time = Get-Date
$psVersion= $host.Version.Major
$curUser= (Get-ChildItem Env:\USERNAME).Value
$curComp= (Get-ChildItem Env:\COMPUTERNAME).Value

function Convert-IpAddressToMaskLength([string] $dottedIpAddressString)
{
  $result = 0; 
  # ensure we have a valid IP address
  [IPAddress] $ip = $dottedIpAddressString;
  $octets = $ip.IPAddressToString.Split('.');
  foreach($octet in $octets)
  {
    while(0 -ne $octet) 
    {
      $octet = ($octet -shl 1) -band [byte]::MaxValue
      $result++; 
    }
  }
  return $result;
}

#initial printing on login in Powershell
Write-Host "=========================================="
Write-Host "Hello, " -foregroundColor $foregroundColor -NoNewline
Write-Host "$curUser" -foregroundColor Green
Write-Host "Today: " -foregroundColor $foregroundColor -NoNewline
Write-Host "$($time.ToLongDateString())" -foregroundColor Green
Write-Host "You're running PowerShell version: " -foregroundColor $foregroundColor -NoNewline
Write-Host "$psVersion" -foregroundColor Green
Write-Host "Your computer name is: " -foregroundColor $foregroundColor -NoNewline
Write-Host "$curComp" -foregroundColor Green
Write-Host "=========================================="


# $global:ip = [ipaddress]'1.1.1.1'
# $global:mask = [ipaddress]'1.1.1.1'
# $global:netid = [ipaddress]'2.2.2.2'
# $binary = [convert]::ToString($mask.Address, 2)
# $mask_length = ($binary -replace 0,$null).Length
# $cidr = '{0}/{1}' -f $netid, $mask_length
# $cidr
# $ip = [IPAddress] "192.168.32.76"
# $networkMask = [IPAddress] "255.255.255.0"
# $networkID = [IPAddress] ($ip.Address -band $networkMask.Address)
# $networkID.IPAddressToString  # outputs "192.168.32.0"
$IP = '192.168.4.5'
$mask = '255.255.0.0'
$IPBits = [int[]]$IP.Split('.')
$MaskBits = [int[]]$Mask.Split('.')
$NetworkIDBits = 0..3 | Foreach-Object { $IPBits[$_] -band $MaskBits[$_] }
$BroadcastBits = 0..3 | Foreach-Object { $NetworkIDBits[$_] + ($MaskBits[$_] -bxor 255) }
$NetworkID = $NetworkIDBits -join '.'
$Broadcast = $BroadcastBits -join '.'


#get all ip in version 4 and 6
$hole = Get-CimInstance win32_networkadapterconfiguration | Where-Object {$null -ne $_.IPAddress} | Select-Object - -ExpandProperty IPAddress -OutVariable allIpV4and6
#get all subnet ip obviously only for ipv4
$hole = Get-CimInstance win32_networkadapterconfiguration | Where-Object {$null -ne $_.IPAddress} | Select-Object -ExpandProperty IPSubnet -OutVariable allIpSubnetMask
#get all macaddress
$hole = Get-CimInstance win32_networkadapterconfiguration | Where-Object {$null -ne $_.IPAddress} | Select-Object -ExpandProperty MacAddress -OutVariable allMAC
#get all descriptions
$hole = Get-CimInstance win32_networkadapterconfiguration | Where-Object {$null -ne $_.IPAddress} | Select-Object -ExpandProperty Description -OutVariable allDescriptions

for ($i = $j = 0; $i -lt $allMAC.Count ; $i++) {
    $IPBits = [int[]]$allIpV4and6[$j].Split('.')
    $MaskBits = [int[]]$allIpSubnetMask[$j].Split('.')
    $NetworkIDBits = 0..3 | Foreach-Object { $IPBits[$_] -band $MaskBits[$_] }
    $BroadcastBits = 0..3 | Foreach-Object { $NetworkIDBits[$_] + ($MaskBits[$_] -bxor 255) }
    $NetworkID = $NetworkIDBits -join '.'
    $Broadcast = $BroadcastBits -join '.'
    Write-Host $allDescriptions[$i] " : " -foregroundColor Yellow
    Write-Host "`t IP: " -foregroundColor Green -NoNewline
    Write-Host $allIpV4and6[$j] -foregroundColor $foregroundColor 
    Write-Host "`t MAC: " -foregroundColor Green -NoNewline
    Write-Host $allMAC[$i] -foregroundColor $foregroundColor 
    Write-Host "`t MASK: " -foregroundColor Green -NoNewline
    Write-Host "/"$(Convert-IpAddressToMaskLength $allIpSubnetMask[$j])  -foregroundColor $foregroundColor 
    Write-Host "`t NETID:  " -foregroundColor Green -NoNewline
    # $ip = $NetworkID
    # $networkMask = [IPAddress]$allIpSubnetMask[$j]
    # $networkID = [IPAddress] ($ip.Address -band $networkMask.Address)
    # Write-Host $networkID.IPAddressToString -foregroundColor $foregroundColor 
    Write-Host $NetworkID -foregroundColor $foregroundColor 
    Write-Host "`t BROADID:  " -foregroundColor Green -NoNewline
    Write-Host $Broadcast -foregroundColor $foregroundColor  
    Write-Host "-----------------------------------"
    $j = $j + 2
}


# Get-CimInstance win32_networkadapterconfiguration | Where-Object {$null -ne $_.IPAddress} | Select-Object -Property @{ Name = 'IPAddress' 
#                                                                                                                     Expression = {($PSItem.IPAddress[0])}
#                                                                                                                     },
#                                                                                                                     @{ Name = 'IPSubnet' 
#                                                                                                                     Expression = {($PSItem.IPSubnet[0])}
#                                                                                                                     },
#                                                                                                                     @{ Name = 'MaskLength'
#                                                                                                                     Expression = {"/" + (Convert-IpAddressToMaskLength ($PSItem.IPSubnet[0]))}
#                                                                                                                      },
#                                                                                                                     @{ Name = 'NetID' 
#                                                                                                                     Expression = {(($allIpV4and6[$i+2] -band $mask.Address).IPAddressToString)}
#                                                                                                                     },
#                                                                                                                      MacAddress, Description

function Prompt {

    Write-Host -NoNewline "(" -foregroundColor Gray
    Write-Host -NoNewLine ${env:USERNAME} -foregroundColor Gray
    Write-Host -NoNewline ")" -foregroundColor Gray
    Write-Host -NoNewLine "$" -foregroundColor Green
    Write-Host -NoNewLine "[" -foregroundColor Yellow
    # Write-Host -NoNewLine ("{0}" -f (Get-Date)) -foregroundColor $foregroundColor
    Write-Host -NoNewLine $((Get-Location).Path)
    Write-Host -NoNewLine "]" -foregroundColor Yellow
    Write-Host -NoNewLine ">>" -foregroundColor Red

    $host.UI.RawUI.WindowTitle = "PS >> User: $curUser >> Current DIR: 
    $((Get-Location).Path)"

    Return " "

}

# concatenate multiple files specified in a text file with the format:
# file <path_file_1>
# file <path_file_2>

function Merge-Videos([String] $ListInputFile, [String] $PathOutput){

      if($ListInputFile.length -eq 0){
         return "Name of the file with a list of input videos is required!";
     }
     elseif($PathOutput.length -eq 0){
         return "Name of the file of output is required!";
     }
     else{
         ffmpeg -safe 0 -f concat -i "$ListInputFile" -c copy 
"$PathOutput.mp4"
     }

}
