$WarningPreference = 'SilentlyContinue'

$VirtualMachines = @{
	SNSRD00415	=	"snred00016-rgp"
	snsrt00524	=	"snrec00010-rgp"
	snsrt00525	=	"snrec00010-rgp"
	SNSRT00539	=	"snrec00010-rgp"
	SNSRD00407	=	"snred00010-rgp"
	SNSRP02442	=	"snreb00047-rgp"
	SNSRQ00655	=	"snrec00015-rgp"
	SNSRQ00656	=	"snrec00015-rgp"
	SNSRQ00657	=	"snrec00015-rgp"
	SNSRT00496	=	"snrec00010-rgp"
	SNSRT00522	=	"snrec00010-rgp"

}

foreach($virtualMachine in $VirtualMachines.keys)
{
	$resource = Get-AzResource `
	  -ResourceGroupName $VirtualMachines[$virtualMachine] `
	  -ResourceName $virtualMachine `
	  -ResourceType Microsoft.Compute/virtualMachines
	$null = Export-AzResourceGroup `
	  -ResourceGroupName $VirtualMachines[$virtualMachine] `
	  -Resource $resource.ResourceId `
	  -Path './arm-template.json' `
	  -Force
	  
	$ArmTemplate = Get-Content './arm-template.json' | Out-String | ConvertFrom-Json

	if(!$ArmTemplate.resources.properties.osProfile.windowsConfiguration.enableAutomaticUpdates){
		Write-Output "[!] $virtualMachine con autoupdate NON ATTIVA!"
	}else{
		Write-Output "[+] $virtualMachine con autoupdate ATTIVA!"
	}

}
