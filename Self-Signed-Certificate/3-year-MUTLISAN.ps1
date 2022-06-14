$passwordAsString="provide the password for PFX file"
$date_now = Get-Date
$extended_date = $date_now.AddYears(3)
$subject_name="subjectname.com" #The first DNS name is also saved as the Subject Name.
$dns1="dns1.com"
$dns2="dns2.com"
$dns3="dns3.com"
#other DNS entry if you want...

$cert = New-SelfSignedCertificate -certstorelocation "cert:\localmachine\my" -dnsname $subject_name, $dns1, $dns2, $dns3 -notafter $extended_date -KeyLength 4096

$pwd = ConvertTo-SecureString -String $passwordAsString -Force -AsPlainText
$path = "cert:\localMachine\my\" + $cert.thumbprint


Export-PfxCertificate -cert $path -FilePath .\self-signed-from-powershell.pfx -Password $pwd

Write-Host "PFX generated"
