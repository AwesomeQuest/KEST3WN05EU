
Install-WindowsFeature dhcp -IncludeManagementTools

Add-DhcpServerv4Scope -Name "Let's'a go" -StartRange 10.10.0.1 -EndRange 10.10.0.14 -SubnetMask 255.255.255.240
Add-DhcpServerv4ExclusionRange -Name "Let's'a not go" -StartRange 10.10.0.11 -EndRange 10.10.0.14 -SubnetMask 255.255.255.240

Add-DhcpServerv6Scope -Name "Let's'a goV6" -Prefix 2001:face:8b:2a00::/60

Restart-Service Dhcpserver




$InternalIPNetwork = "10.10.0.0/24"

Install-WindowsFeature -name "NET-Framework-Features" –IncludeManagementTools
New-NetNat -Name "ClientNAT" -InternalIPInterfaceAddressPrefix $InternalIPNetwork


Install-WindowsFeature -name "WINS" –IncludeManagementTools



$domain              = 'DC=torfi,DC=local'
$domain2             = 'OU=company,'+$domain
$preOU               = 'OU='
$domain3             = ','+$domain2
$domainIT            = $preOU+'Tölvudeild'+$domain3
$domainManagement    = $preOU+'Rekstrardeild'+$domain3
$domainHarpa         = $preOU+'Framkvæmdadeild'+$domain3
$domainEngineering   = $preOU+'Framleiðsludeild'+$domain3

New-ADOrganizationalUnit -Name "company" -Path $domain
New-ADOrganizationalUnit -Name "Tölvudeild" -Path $domain2
New-ADOrganizationalUnit -Name "Rekstrardeild" -Path $domain2
New-ADOrganizationalUnit -Name "Framkvæmdadeild" -Path $domain2
New-ADOrganizationalUnit -Name "Framleiðsludeild" -Path $domain2

New-ADGroup -Name "Tölvudeild" -SamAccountName Tölvudeild -GroupCategory Security -GroupScope Universal -DisplayName "Tölvudeild" -Path $domainIT
New-ADGroup -Name "Rekstrardeild" -SamAccountName Rekstrardeild -GroupCategory Security -GroupScope Universal -DisplayName "Rekstrardeild" -Path $domainManagement
New-ADGroup -Name "Framkvæmdadeild" -SamAccountName Framkvæmdadeild -GroupCategory Security -GroupScope Universal -DisplayName "Framkvæmdadeild" -Path $domainHarpa
New-ADGroup -Name "Framleiðsludeild" -SamAccountName Framleiðsludeild -GroupCategory Security -GroupScope Universal -DisplayName "Framleiðsludeild" -Path $domainEngineering


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
    $fullname      = $User.Nafn
    $userprinciple = $User.Notendanafn + "@" + $domain
	$Username 	   = $User.Notendanafn
	$Firstname     = $User.Fornafn
	$Lastname 	   = $User.Eftirnafn
    $department    = $User.Deild
	$desc		   = $User.Stada
    $OU            = $preDC + $department + $DC
    $Password      = $typepasswordhere
    $CN            = 'CN='+$department+','+$OU

	if (Get-ADUser -F {SamAccountName -eq $Username})
	{
		 Write-Warning "A user account with username $Username already exist in Active Directory."
	}
    elseif ($desc)
    {
        New-ADUser -SamAccountName $Username -UserPrincipalName $userprinciple -Name $fullname -GivenName $Firstname -Surname $Lastname -Enabled $True -DisplayName $fullname -Path $OU -Department $department -AccountPassword (convertto-securestring $Password -AsPlainText -Force) -ChangePasswordAtLogon $True
		$supervisor = $Username
	}
	else
	{
        New-ADUser -SamAccountName $Username -UserPrincipalName $userprinciple -Name $fullname -GivenName $Firstname -Surname $Lastname -Enabled $True -DisplayName $fullname -Path $OU -Department $department -AccountPassword (convertto-securestring $Password -AsPlainText -Force) -ChangePasswordAtLogon $True -Manager $supervisor
	}
    Add-ADGroupMember -Identity $CN -Members $Username
}




New-Item -Path "c:\" -Name EmplyeeShare -ItemType "directory"
New-Item -Path "c:\EmplyeeShare" -Name Tölvudeild -ItemType "directory"
New-Item -Path "c:\EmplyeeShare" -Name Rekstrardeild -ItemType "directory"
New-Item -Path "c:\EmplyeeShare" -Name Framkvæmdadeild -ItemType "directory"
New-Item -Path "c:\EmplyeeShare" -Name Framleiðsludeild -ItemType "directory"

New-Item -Path "c:\EmplyeeShare" -Name SharedShare  -ItemType "directory"
New-SmbShare -Path "c:\EmplyeeShare" -Name SharedShare -FullAccess everyone


New-SmbShare -Name SharedIT -Path "c:\EmplyeeShare\Tölvudeild"  -FullAccess torfi.local\administrator
New-SmbShare -Name SharedManagement -Path "c:\EmplyeeShare\Rekstrardeild"  -FullAccess torfi.local\administrator
New-SmbShare -Name SharedEngineering -Path "c:\EmplyeeShare\Framkvæmdadeild" -FullAccess torfi.local\administrator
New-SmbShare -Name SharedHarpa -Path "c:\EmplyeeShare\Framleiðsludeild"  -FullAccess torfi.local\administrator



$printDriverName =  "Microsoft Print To PDF"


Install-WindowsFeature Print-Services -IncludeManagementTools

Add-PrinterDriver -Name  $printDriverName

Add-PrinterPort -Name TölvudeildPrintPort -PrinterHostAddress 10.10.0.15
Add-Printer -Name TölvudeildPrinter -DriverName $printDriverName -PortName TölvudeildPrintPort

Add-PrinterPort -Name RekstrardeildPrintPort -PrinterHostAddress 10.10.0.16
Add-Printer -Name RekstrardeildPrinter -DriverName $printDriverName -PortName RekstrardeildPrintPort

Add-PrinterPort -Name FramkvæmdadeildPrintPort -PrinterHostAddress 10.10.0.17
Add-Printer -Name FramkvæmdadeildPrinter -DriverName $printDriverName -PortName FramkvæmdadeildPrintPort

Add-PrinterPort -Name FramleiðsludeildPrintPort -PrinterHostAddress 10.10.0.18
Add-Printer -Name FramleiðsludeildPrinter -DriverName $printDriverName -PortName FramleiðsludeildPrintPort

Add-PrinterPort -Name SharedPrintPort -PrinterHostAddress 10.10.0.19
Add-Printer -Name SharedPrinter -DriverName $printDriverName -PortName SharedPrintPort




$gpopath = "C:\GPOs"

$employeeOU = "ou=company,dc=torfi,dc=local"
$ITOU = "ou=Tölvudeild," + $employeeOU
$ManagementOU = "ou=Rekstrardeild," + $employeeOU
$EngineeringOU = "ou=Framkvæmdadeild," + $employeeOU
$HarpaOU = "ou=Framleiðsludeild," + $employeeOU

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

















$gpopath = "C:\GPOs"

class GPO {
    [string]$name
    [string]$id
    $path = $gpopath + "\" + $name

}


$employeeOU = "OU=company," + (Get-ADDomain).DistinguishedName

$GROUPS = @()
foreach($i in $env:EXPANDTHEDONG.Split(";")){$GROUPS += ,$i}

$groupsOUs = @()
foreach($i in $GROUPS){$groupsOUs += "OU=" + $i + "," + $employeeOU}

function linkSome ([GPO]$GPO, $groups){

    New-GPO -Name $GPO.name
    Import-GPO -Path $GPO.path -BackupId $GPO.id -TargetName $GPO.name

    foreach($group in $groups){
        New-GPLink -Name $GPO.name -Target $groupsOUs[$group]
        
        echo $GPO.name + "has been applied to " + $groupsOUs[$group] 
    }
}
function linkAll ([GPO]$GPO){

    New-GPO -Name $GPO.name
    Import-GPO -Path $GPO.path -BackupId $GPO.id -TargetName $GPO.name
    New-GPLink -Name $GPO.name -Target $employeeOU

    echo $GPO.name + "has been applied to all" 
    
}



foreach($GPO in (Get-ChildItem $gpopath).Name){
    if($GPO.Contains('&'))
    {
        $GPO1 = [GPO]::new()
        $GPO1.id = (Get-ChildItem "$gpopath\$GPO").Name
        $GPO1.name = $GPO

        $gprStr = $GPO.Split('&')[0]
        $grps = $gprStr.Split(' ')

        linkSome $GPO1 $grps

    }
    else
    {
        $GPO1 = [GPO]::new()
        $GPO1.id = (Get-ChildItem "$gpopath\$GPO").Name
        $GPO1.name = $GPO

        linkAll($GPO1)
    }
}

