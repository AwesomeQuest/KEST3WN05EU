
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
