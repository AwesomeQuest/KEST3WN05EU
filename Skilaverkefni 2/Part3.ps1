
Install-WindowsFeature dhcp -IncludeManagementTools

Add-DhcpServerv4Scope -Name "Let's'a go" -StartRange 10.10.0.1 -EndRange 10.10.0.14 -SubnetMask 255.255.255.240
Add-DhcpServerv4ExclusionRange -Name "Let's'a not go" -StartRange 10.10.0.11 -EndRange 10.10.0.14 -SubnetMask 255.255.255.240

Add-DhcpServerv6Scope -Name "Let's'a goV6" -Prefix 2001:face:8b:2a00::/60

Restart-Service Dhcpserver




$InternalIPNetwork = "10.10.0.0/24"

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
$FirstnameCSV              = "Fornafn"
$LastnameCSV               = "Eftirnafn"
$UsernameCSV               = "Notendanafn"
$DepartmentCSV             = "Deild"
$isSupervisorCSV           = "Stada"

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
    $Username 	   = $User.$UsernameCSV
    $userprinciple = $Username + "@" + $domain
	$Firstname     = $User.$FirstnameCSV
	$Lastname 	   = $User.$LastnameCSV
    $email         = $userprinciple
    $department    = $User.$DepartmentCSV
    $isSupervisor  = $User.$isSupervisorCSV
    $OU            = $preDC+$department+$domain3
    $Password      = $typepasswordhere
    $CN2           = 'CN='+$department+','+$OU

	if (Get-ADUser -Filter {SamAccountName -eq $Username})
	{
		 Write-Warning "A user account with username $Username already exist in Active Directory."
	}
    elseif ($isSupervisor)
    {
        New-ADUser -SamAccountName $Username -UserPrincipalName $userprinciple -Name $fullname -GivenName $Firstname -Surname $Lastname -Enabled $True -DisplayName $fullname -Path $OU -EmailAddress $email -Department $department -AccountPassword (convertto-securestring $Password -AsPlainText -Force) -ChangePasswordAtLogon $True 
        $supervisor = $Username
    }
	else
	{
        New-ADUser -SamAccountName $Username -UserPrincipalName $userprinciple -Name $fullname -GivenName $Firstname -Surname $Lastname -Enabled $True -DisplayName $fullname -Path $OU -EmailAddress $email -Department $department -AccountPassword (convertto-securestring $Password -AsPlainText -Force) -ChangePasswordAtLogon $True -Manager $supervisor
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




