$publicAdapter = "Ethernet 2"
$privateAdapter = "Ethernet"

$privateAdapterIndex = 6
$publicAdapterIndex = 5

Rename-Computer -NewName "DC1"

Rename-NetAdapter -Name $publicAdapter -NewName "Public"
Rename-NetAdapter -Name $privateAdapter -NewName "Private"


New-NetIPAddress -InterfaceIndex $privateAdapterIndex -IPAddress 10.10.0.110 -PrefixLength 28
New-NetIPAddress -InterfaceIndex $privateAdapterIndex -IPAddress 2001:face:008b:2a02:ffff:ffff:ffff:ffff


Set-DnsClientServerAddress -InterfaceIndex $privateAdapterIndex -ServerAddresses 10.10.0.110

New-ItemProperty -Path HKCU:\Environment -Name GROUPS -PropertyType ExpandString -Value "Tölvudeild;Rekstrardeild;Framkvæmdadeild;Framleiðsludeild"


Install-WindowsFeature -Name "AD-Domain-Services" -IncludeManagementTools

Restart-Computer
