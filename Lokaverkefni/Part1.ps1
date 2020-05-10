$publicAdapter = "Ethernet 2"
$privateAdapter = "Ethernet"

$privateAdapterIndex = (Get-NetAdapter -Name $privateAdapter).ifIndex
$publicAdapterIndex = (Get-NetAdapter -Name $publicAdapter).ifIndex

Rename-Computer -NewName "DC1"

Rename-NetAdapter -Name $publicAdapter -NewName "Public"
Rename-NetAdapter -Name $privateAdapter -NewName "Private"


New-NetIPAddress -InterfaceIndex $privateAdapterIndex -IPAddress 192.168.1.65 -PrefixLength 26


Set-DnsClientServerAddress -InterfaceIndex $privateAdapterIndex -ServerAddresses 192.168.1.65


Install-WindowsFeature -Name "AD-Domain-Services" -IncludeManagementTools

Restart-Computer
