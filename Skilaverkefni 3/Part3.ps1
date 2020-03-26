
Install-WindowsFeature dhcp -IncludeManagementTools

Add-DhcpServerv4Scope -Name "Let's'a go" -StartRange 172.16.16.1 -EndRange 172.16.18.88 -SubnetMask 255.255.252.0

Restart-Service Dhcpserver



$InternalIPNetwork = "172.16.16.0/22"

Install-WindowsFeature -name "NET-Framework-Features" –IncludeManagementTools
New-NetNat -Name "ClientNAT" -InternalIPInterfaceAddressPrefix $InternalIPNetwork


Install-WindowsFeature -name "WINS" –IncludeManagementTools


Import-Module activedirectory
$CSVpath                   = "C:\csv.csv"
#$typepasswordhere          = "" #you can type a set password if you do not want to be prompted
$typepasswordhere          = Read-Host -Prompt "Type Base Password here"
$company                   = 'company'
$HomeDrive                 = 'H:'
$HomeDriveRoot             = "ServerUsers"
$everyoneGroupName         = "everyEmployee"

$NameCSV                   = "Nafn"
$IDCSV					   = "ID"
$PositionCSV			   = "Starfsheiti"
$LocationCSV			   = "Sveitarfelag"
$FirstnameCSV              = "Fornafn"
$LastnameCSV               = "Eftirnafn"
$HomePhone				   = "Heimasimi"
$WorkPhone				   = "Vinnusimi"
$MobilePhone			   = "Farsimi"
$UsernameCSV               = "Notendanafn"
$DepartmentCSV             = "Deild"

$ADUsers                   = Import-csv $CSVpath -Encoding UTF8
$domain                    = ((Get-ADDomain).DNSRoot)
$DC                        = ((Get-ADDomain).DistinguishedName)
$domain2                   = 'OU='+$company+','+$DC
$preDC                     = 'OU='
$domain3                   = ','+$domain2
$UserRoot                  = '\\DC1\' + $HomeDriveRoot + '\'
$FolderRoot                = 'C:\' + $HomeDriveRoot + '\'

$groupArray                = @()
foreach ($UserGroup in $ADUsers){
    $tempGroup = $UserGroup.$DepartmentCSV
    if(!($groupArray -contains $tempGroup)){
        $groupArray += $tempGroup
    }
}
$tempString = ""
for($i=0;$i -lt $groupArray.Length; $i++){
    if($i -eq ($groupArray.Length - 1)){
        $tempString += $groupArray[$i]
    }
    else
    {
        $tempString += $groupArray[$i] + ';'
    }
}
New-ItemProperty -Path HKCU:\Environment -Name GROUPS -PropertyType ExpandString -Value $tempString


#OU creation
if (Get-ADOrganizationalUnit -Filter {Name -eq $company})
{
    Write-Warning "An OU with the name $company already exist in Active Directory."
}
else
{
    New-ADOrganizationalUnit -Name $company -Path $DC
}

if (Get-ADGroup -Filter {SamAccountName -eq $everyoneGroupName})
{
    Write-Warning "A group with the name $everyoneGroupName already exist in Active Directory."
}
else
{
    New-ADGroup -Name $everyoneGroupName -SamAccountName $everyoneGroupName -GroupCategory Security -GroupScope Universal -DisplayName $everyoneGroupName -Path $domain2
}

foreach ($group in $groupArray)
{
    $domainGroup = $preDC+$group+$domain3
    $CN1          = 'CN='+$everyoneGroupName+$domain3

    if (Get-ADOrganizationalUnit -Filter {Name -eq $group})
	{
		 Write-Warning "An OU with the name $group already exist in Active Directory."
	}
    else
    {
        New-ADOrganizationalUnit -Name $group -Path $domain2
    }

    #Group creation
    if (Get-ADGroup -Filter {SamAccountName -eq $group})
	{
		 Write-Warning "A group with the name $group already exist in Active Directory."
	}
    else
    {
        New-ADGroup -Name $group -SamAccountName $group -GroupCategory Security -GroupScope Universal -DisplayName $group -Path $domainGroup
        Add-ADGroupMember -Identity $CN1 -Members $group
    }
}

$supervisor = ""
#User creation
foreach ($User in $ADUsers)
{
    $fullname      = $User.$NameCSV
	$userID		   = $User.$IDCSV
	$position	   = $User.$PositionCSV
	$location	   = $User.$LocationCSV
    $Username 	   = $User.$UsernameCSV
    $userprinciple = $Username + "@" + $domain
	$Firstname     = $User.$FirstnameCSV
	$Lastname 	   = $User.$LastnameCSV
	$HPhone		   = $User.$HomePhone
	$WPhone		   = $User.$WorkPhone
	$MPhone		   = $User.$MobilePhone
    $email         = $userprinciple
    $department    = $User.$DepartmentCSV
    $OU            = $preDC+$department+$domain3
    $Password      = $typepasswordhere
    $CN2           = 'CN='+$department+','+$OU

	if (Get-ADUser -Filter {SamAccountName -eq $Username})
	{
		 Write-Warning "A user account with username $Username already exist in Active Directory."
	}
	else
	{
        New-ADUser -SamAccountName $Username -UserPrincipalName $userprinciple -Name $fullname -GivenName $Firstname -Surname $Lastname -Enabled $True -DisplayName $fullname -Path $OU -EmailAddress $email -Department $department -AccountPassword (convertto-securestring $Password -AsPlainText -Force) -ChangePasswordAtLogon $True -HomePhone $HPhone -OfficePhone $WPhone -MobilePhone $MPhone -EmployeeID $userID -Description $position -Division $location
	}
    Add-ADGroupMember -Identity $CN2 -Members $Username

    #adds homefolder to users
    $UserDirectory=$UserRoot+$Username
    $HomeDirectory=$FolderRoot+$Username

    if (Test-Path $HomeDirectory -PathType Container)
    {
        Write-Warning "A directory with the name $HomeDirectory already exist in Active Directory."
    }
    else
    {
        New-Item -path $HomeDirectory -type directory -force
    }
    Set-ADUser -Identity $Username -HomeDrive $HomeDrive -HomeDirectory $UserDirectory

}




New-Item -Path "c:\" -Name EmplyeeShare -ItemType "directory"

foreach($group in $groupArray)
{
	New-Item -Path "c:\EmplyeeShare" -Name $group -ItemType "directory"
	New-SmbShare -Name ("Shared" + $group) -Path "c:\EmplyeeShare\$group"  -FullAccess torfi.local\administrator

}

New-Item -Path "c:\EmplyeeShare" -Name SharedShare  -ItemType "directory"
New-SmbShare -Path "c:\EmplyeeShare" -Name SharedShare -FullAccess everyone

#share install files

New-SmbShare -Name intsallfire -Path "c:\installs"  -FullAccess torfi.local\administrator





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





Restart-Computer