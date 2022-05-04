#hashtable containing user:password to add
$accounts = @{
		"user" = "password";
		"user" = "password";
}

$accounts_groups = @{
		"user" = "group name";
		"user" = "Administrators";
		"user" = "Backup Operators";
		"user" = "Remote Desktop Users";
}

#domain to which add servers
$domain = "test.priv"
#username of admin that make join
$adminjoin = "$domain\username"
#password of admin that make join
$passwordjoin = convertto-securestring -AsPlainText -Force -String 'password'
#credential generated
$credjoin = new-object -typename System.Management.Automation.PSCredential($adminjoin,$passwordjoin)

#iterate over hashtable and create accounts
$accounts.keys | ForEach-Object{
	$user = $_
	net user $user $accounts[$user] /add /y /comment:"Comment"
	$create_user = $?
	#username^    password^
	#modify some parameters with powershell due to unavailibity in cmd
	Set-LocalUser -Name $_ -AccountNeverExpires –PasswordNeverExpires $true -FullName $_
	$modify_user = $?
    if($create_user -and $modify_user){
		$message = '[+] User: {0} created successfully!' -f $user
		Write-Output $message
	}else{
		if(!$create_user){
			$message = '[-] Failed during create user {0}' -f $user
			Write-Output $message		
		}elseif(!$modify_user){
			$message = '[-] Failed during modify user {0}' -f $user
			Write-Output $message
		}
	}
}
 
 
#iterate over hashtable and add accounts to groups
$accounts_groups.keys | ForEach-Object{
	$user = $_
	Add-LocalGroupMember -Group $accounts_groups[$user] -Member $user
	$add_user_to_group = $?
	if($add_user_to_group){
		$message = '[+] {0} added to group {1} successfully!' -f $user,$accounts_groups[$user]
		Write-Output $message
	}else{
		$message = '[-] Failed during adding user {0} to group {1}' -f $user,$accounts_groups[$user]
		Write-Output $message
	}

}


#add local computer to domain
Add-Computer -Credential $credjoin -DomainName $domain -Verbose
if($?){
	$message = '[+] Current machine added to {0} domain successfully!' -f $domain
	Write-Output $message
}else{
	$message = '[-] Failed adding machine to domain {0}' -f $domain
	Write-Output $message
}
