Install-WindowsFeature dhcp -IncludeManagementTools

Add-DhcpServerv4Scope -Name "Let's'a go" -StartRange 172.20.0.1 -EndRange 172.20.0.253 -SubnetMask 255.255.255.0

Add-DhcpServerv6Scope -Name "Let's'a goV6" -Prefix fd00::

Add-DhcpServerv4ExclusionRange -ScopeId 172.20.0.0 -StartRange 172.20.0.243 -EndRange 172.20.0.253