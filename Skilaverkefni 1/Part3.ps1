$domain              = 'DC=torfi,DC=local'
$domain2             = 'OU=company,'+$domain
$preOU               = 'OU='
$domain3             = ','+$domain2
$domainIT            = $preOU+'IT'+$domain3
$domainManagement    = $preOU+'Management'+$domain3
$domainHarpa         = $preOU+'Harpa'+$domain3
$domainEngineering   = $preOU+'Engineering'+$domain3
$domainFinance       = $preOU+'Finance'+$domain3
$domainManufacturing = $preOU+'Manufacturing'+$domain3

New-ADOrganizationalUnit -Name "company" -Path $domain
New-ADOrganizationalUnit -Name "IT" -Path $domain2
New-ADOrganizationalUnit -Name "Management" -Path $domain2
New-ADOrganizationalUnit -Name "Harpa" -Path $domain2
New-ADOrganizationalUnit -Name "Engineering" -Path $domain2
New-ADOrganizationalUnit -Name "Finance" -Path $domain2
New-ADOrganizationalUnit -Name "Manufacturing" -Path $domain2

New-ADGroup -Name "IT" -SamAccountName IT -GroupCategory Security -GroupScope Universal -DisplayName "IT" -Path $domainIT
New-ADGroup -Name "Management" -SamAccountName Management -GroupCategory Security -GroupScope Universal -DisplayName "Management" -Path $domainManagement
New-ADGroup -Name "Harpa" -SamAccountName Harpa -GroupCategory Security -GroupScope Universal -DisplayName "Harpa" -Path $domainHarpa
New-ADGroup -Name "Engineering" -SamAccountName Engineering -GroupCategory Security -GroupScope Universal -DisplayName "Engineering" -Path $domainEngineering
New-ADGroup -Name "Finance" -SamAccountName Finance -GroupCategory Security -GroupScope Universal -DisplayName "Finance" -Path $domainFinance
New-ADGroup -Name "Manufacturing" -SamAccountName Manufacturing -GroupCategory Security -GroupScope Universal -DisplayName "Manufacturing" -Path $domainManufacturing


Import-Module activedirectory
$CSVpath = "C:\csv.csv"
$ADUsers = Import-csv $CSVpath
$typepasswordhere = "a100Hlusta" #you can type a set password if you do not want to be prompted
#$typepasswordhere = Read-Host -Prompt "Type Base Password here"

foreach ($User in $ADUsers)
{
	$domain        = "torfi.local"
    $DC            = ',OU=company,DC=torfi,DC=local'
    $preDC         = 'OU='
    $fullname      = $User.fullname
    $userprinciple = $User.userprinciple + "@" + $domain
	$Username 	   = $User.userprinciple
	$Firstname     = $User."first name"
	$Lastname 	   = $User."last name"
    $email         = $User.email
    $department    = $User.dept
    $OU            = $preDC + $department + $DC
    $Password      = $typepasswordhere
    $supervisor    = "HarHja"
    $CN            = 'CN='+$department+','+$OU

	if (Get-ADUser -F {SamAccountName -eq $Username})
	{
		 Write-Warning "A user account with username $Username already exist in Active Directory."
	}
    elseif ($Username -eq $supervisor)
    {
        New-ADUser -SamAccountName $Username -UserPrincipalName $userprinciple -Name $fullname -GivenName $Firstname -Surname $Lastname -Enabled $True -DisplayName $fullname -Path $OU -EmailAddress $email -Department $department -AccountPassword (convertto-securestring $Password -AsPlainText -Force) -ChangePasswordAtLogon $True
    }
	else
	{
        New-ADUser -SamAccountName $Username -UserPrincipalName $userprinciple -Name $fullname -GivenName $Firstname -Surname $Lastname -Enabled $True -DisplayName $fullname -Path $OU -EmailAddress $email -Department $department -AccountPassword (convertto-securestring $Password -AsPlainText -Force) -ChangePasswordAtLogon $True -Manager $supervisor
	}
    Add-ADGroupMember -Identity $CN -Members $Username
}



Install-WindowsFeature dhcp -IncludeManagementTools

Add-DhcpServerv4Scope -Name "Let's'a go" -StartRange 192.168.130.129 -EndRange 192.168.130.159 -SubnetMask 255.255.255.192

Add-DhcpServerv6Scope -Name "Let's'a goV6" -Prefix 2001:cc1d:5a:c000:: 

Restart-Service Dhcpserver




$InternalIPNetwork = "192.168.130.128/26"

Install-WindowsFeature -name "NET-Framework-Features" –IncludeManagementTools
New-NetNat -Name "ClientNAT" -InternalIPInterfaceAddressPrefix $InternalIPNetwork



New-Item -Path "c:\" -Name EmplyeeShare -ItemType "directory"
New-Item -Path "c:\EmplyeeShare" -Name IT -ItemType "directory"
New-Item -Path "c:\EmplyeeShare" -Name Management -ItemType "directory"
New-Item -Path "c:\EmplyeeShare" -Name Engineering -ItemType "directory"
New-Item -Path "c:\EmplyeeShare" -Name Harpa -ItemType "directory"
New-Item -Path "c:\EmplyeeShare" -Name Finance -ItemType "directory"
New-Item -Path "c:\EmplyeeShare" -Name Manufacturing  -ItemType "directory"

New-Item -Path "c:\EmplyeeShare" -Name SharedShare  -ItemType "directory"
New-SmbShare -Path "c:\EmplyeeShare" -Name SharedShare -FullAccess everyone


New-SmbShare -Name SharedIT -Path "c:\EmplyeeShare\IT"  -FullAccess torfi.local\administrator
New-SmbShare -Name SharedManagement -Path "c:\EmplyeeShare\Management"  -FullAccess torfi.local\administrator
New-SmbShare -Name SharedEngineering -Path "c:\EmplyeeShare\Engineering" -FullAccess torfi.local\administrator
New-SmbShare -Name SharedHarpa -Path "c:\EmplyeeShare\Harpa"  -FullAccess torfi.local\administrator
New-SmbShare -Name SharedFinance -Path "c:\EmplyeeShare\Finance"  -FullAccess torfi.local\administrator
New-SmbShare -Name SharedManufacturing -Path "c:\EmplyeeShare\Manufacturing"  -FullAccess torfi.local\administrator




$printDriverName =  "Microsoft Print To PDF"


Install-WindowsFeature Print-Services -IncludeManagementTools

Add-PrinterDriver -Name  $printDriverName

Add-PrinterPort -Name ITPrintPort -PrinterHostAddress 192.168.130.160
Add-Printer -Name ITPrinter -DriverName $printDriverName -PortName ITPrintPort

Add-PrinterPort -Name ManagementPrintPort -PrinterHostAddress 192.168.130.161
Add-Printer -Name ManagementPrinter -DriverName $printDriverName -PortName ManagementPrintPort

Add-PrinterPort -Name EngineeringPrintPort -PrinterHostAddress 192.168.130.162
Add-Printer -Name EngineeringPrinter -DriverName $printDriverName -PortName EngineeringPrintPort

Add-PrinterPort -Name HarpaPrintPort -PrinterHostAddress 192.168.130.163
Add-Printer -Name HarpaPrinter -DriverName $printDriverName -PortName HarpaPrintPort

Add-PrinterPort -Name FinancePrintPort -PrinterHostAddress 192.168.130.164
Add-Printer -Name FinancePrinter -DriverName $printDriverName -PortName FinancePrintPort

Add-PrinterPort -Name ManufacturingPrintPort -PrinterHostAddress 192.168.130.165
Add-Printer -Name ManufacturingPrinter -DriverName $printDriverName -PortName ManufacturingPrintPort

Add-PrinterPort -Name SharedPrintPort -PrinterHostAddress 192.168.130.166
Add-Printer -Name SharedPrinter -DriverName $printDriverName -PortName SharedPrintPort





$gpopath = "C:\GPOs"

$employeeOU = "ou=company,dc=torfi,dc=local"
$ITOU = "ou=IT," + $employeeOU
$ManagementOU = "ou=Management," + $employeeOU
$EngineeringOU = "ou=Engineering," + $employeeOU
$HarpaOU = "ou=Harpa," + $employeeOU
$FinanceOU = "ou=Finance," + $employeeOU
$ManufacturingOU = "ou=Manufacturing," + $employeeOU

$Fold = $gpopath + "\set screen save"
$BackID = "{A11ED179-A62E-427E-BEED-18219EBC5F3B}"
$GPOName = "set screen save"

New-GPO -Name $GPOName

Import-GPO -path $Fold -BackupId $BackID -TargetName $GPOName

New-GPLink -Name $GPOName -Target $ITOU -LinkEnabled Yes
New-GPLink -Name $GPOName -Target $ManagementOU -LinkEnabled Yes
New-GPLink -Name $GPOName -Target $HarpaOU -LinkEnabled Yes
New-GPLink -Name $GPOName -Target $FinanceOU -LinkEnabled Yes
New-GPLink -Name $GPOName -Target $ManufacturingOU -LinkEnabled Yes



$MapGPONameArray = "map Engineering share", "map Finance share", "map Harpa share", "map IT share", "map Management share", "map Manufacturing share"
$MapGPOIDArray = "{A8FA853C-085B-4238-8C19-371AD4199999}", "{793C3611-75D0-4EBF-B594-851591325FFF}", "{9A2BDCEC-346F-431E-BFF7-3FAB33826113}", "{2BFEB8E7-BB59-4D11-8349-45C222EA69A4}", "{BAAC016F-9B45-41EA-9696-1683D1FAA726}", "{B0B8CC43-526F-4829-ACA8-CC246797C36A}"


$OUNameArray = $EngineeringOU, $FinanceOU, $HarpaOU, $ITOU, $ManagementOU, $ManufacturingOU

$MapGPONameArray = "map Engineering share", "map Finance share", "map Harpa share", "map IT share", "map Management share", "map Manufacturing share"
$MapGPOIDArray = "{A8FA853C-085B-4238-8C19-371AD4199999}", "{793C3611-75D0-4EBF-B594-851591325FFF}", "{9A2BDCEC-346F-431E-BFF7-3FAB33826113}", "{2BFEB8E7-BB59-4D11-8349-45C222EA69A4}", "{BAAC016F-9B45-41EA-9696-1683D1FAA726}", "{B0B8CC43-526F-4829-ACA8-CC246797C36A}"


For ($i=0; $i -lt $MapGPONameArray.Length; $i++){

    $Fold = $gpopath + "\" + $MapGPONameArray[$i]
	
	New-GPO -Name $MapGPONameArray[$i]
    
    Import-GPO -Path $Fold -BackupId $MapGPOIDArray[$i] -TargetName $MapGPONameArray[$i]

    New-GPLink -Name $MapGPONameArray[$i] -Target $OUNameArray[$i]

}

$Fold = $gpopath + "\map Share share"
New-GPO -Name "map Share share"
Import-GPO -Path $Fold -BackupId "{E008D14F-2CA9-4203-A356-0BA14240E53E}" -TargetName "map Share share"
New-GPLink -Name "map Share share" -Target $employeeOU


$Fold = $gpopath + "\restrict taskmgr and control"
New-GPO -Name "map Share share"
Import-GPO -Path $Fold -BackupId "{1A9DB1F6-C0C2-42B5-BE9A-6CA06D6A9EBB}" -TargetName "map Share share"

New-GPLink -Name "map Share share" -Target $EngineeringOU
New-GPLink -Name "map Share share" -Target $FinanceOU
New-GPLink -Name "map Share share" -Target $HarpaOU
New-GPLink -Name "map Share share" -Target $ITOU
New-GPLink -Name "map Share share" -Target $ManufacturingOU



New-SmbShare -Name autoInstall -Path "c:\auto install"  -FullAccess torfi.local\administrator

$Fold = $gpopath + "\install firefox"
New-GPO -Name "install firefox"
Import-GPO -Path $Fold -BackupId "{F7326C9E-ABEB-4DCD-9106-FFE094A778EE}" -TargetName "install firefox"

New-GPLink -Name "install firefox" -Target $employeeOU


$Fold = $gpopath + "\no firefox"
New-GPO -Name "no firefox"
Import-GPO -Path $Fold -BackupId "{752DFEFE-EA8E-49EA-A0A9-A7D098D0F42D}" -TargetName "no firefox"

New-GPLink -Name "no firefox" -Target $ManufacturingOU



$printGPONameArray = "share Engineering printer", "share Finance printer", "share Harpa printer", "share IT printer", "share Management printer", "share Manufacturing printer"
$printGPOBackID = "{7DA21A69-25A3-4DDD-B9DB-D96065AFA07C}", "{AB64D675-877D-4FA4-848C-BEEBA269876C}", "{C0CB0D26-81E2-4BDC-86EC-6FAF31448213}", "{5BCEF547-3A5A-4FA7-8055-81F675DB259B}", "{E4FB64EA-B311-42B0-B289-5E33C16E5A3D}", "{D8BCE15C-DA47-4A5A-B6B2-EBC5F5E0A01B}"


For ($i=0; $i -lt $printGPONameArray.Length; $i++){

    $Fold = $gpopath + "\" + $printGPONameArray[$i]
	
	New-GPO -Name $printGPONameArray[$i]
    
    Import-GPO -Path $Fold -BackupId $printGPOBackID[$i] -TargetName $printGPONameArray[$i]

    New-GPLink -Name $printGPONameArray[$i] -Target $OUNameArray[$i]

}


$Fold = $gpopath + "\share Share printer"
New-GPO -Name "share Share printer"
Import-GPO -Path $Fold -BackupId "{4721A0FB-2ED8-4D34-B839-895271DBD34A}" -TargetName "share Share printer"
New-GPLink -Name "share Share printer" -Target $employeeOU