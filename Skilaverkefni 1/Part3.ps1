Install-WindowsFeature dhcp -IncludeManagementTools

Add-DhcpServerv4Scope -Name "Let's'a go" -StartRange 192.168.130.129 -EndRange 192.168.130.159 -SubnetMask 255.255.255.192

Add-DhcpServerv6Scope -Name "Let's'a goV6" -Prefix 2001:cc1d:5a:c000:: 