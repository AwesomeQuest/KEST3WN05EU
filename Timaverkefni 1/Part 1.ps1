$publicAdapter = "Ethernet 2"
$privateAdapter = "Ethernet"

$privateAdapterIndex = 6
$publicAdapterIndex = 5

Rename-Computer -NewName "dc1"

Rename-NetAdapter -Name $publicAdapter -NewName "Public"
Rename-NetAdapter -Name $privateAdapter -NewName "Private"


New-NetIPAddress -InterfaceIndex $privateAdapterIndex -IPAddress 172.20.0.254 -PrefixLength 24 
New-NetIPAddress -InterfaceIndex $privateAdapterIndex -IPAddress fd00::1


Set-DnsClientServerAddress -InterfaceIndex 5 -ServerAddresses 172.20.0.254


Install-WindowsFeature -Name "AD-Domain-Services" -IncludeManagementTools

