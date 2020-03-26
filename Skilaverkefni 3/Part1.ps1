$publicAdapter = "Ethernet 2"
$privateAdapter = "Ethernet"

$privateAdapterIndex = (Get-NetAdapter -Name $privateAdapter).ifIndex
$publicAdapterIndex = (Get-NetAdapter -Name $publicAdapter).ifIndex

Rename-Computer -NewName "DC1"

Rename-NetAdapter -Name $publicAdapter -NewName "Public"
Rename-NetAdapter -Name $privateAdapter -NewName "Private"


New-NetIPAddress -InterfaceIndex $privateAdapterIndex -IPAddress 172.16.19.254 -PrefixLength 22


Set-DnsClientServerAddress -InterfaceIndex $privateAdapterIndex -ServerAddresses 172.16.19.254

New-ItemProperty -Path HKCU:\Environment -Name GROUPS -PropertyType ExpandString -Value "Tölvudeild;Rekstrardeild;Framkvæmdadeild;Framleiðsludeild"


Install-WindowsFeature -Name "AD-Domain-Services" -IncludeManagementTools

Restart-Computer
