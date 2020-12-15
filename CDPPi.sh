#!/bin/bash

IF=`nmcli conn | grep ethernet | grep -v '\-\-' | awk '{print $1;}'`

CDPINFO=`sudo /usr/sbin/lldpctl`

EXTERNALIP=`curl ifconfig.co`

INTERNALIP=`ip addr | grep $IF -A 3`

DHCPSVR=`nmap --script broadcast-dhcp-discover -e $IF`

echo "Current External IP address is $EXTERNALIP

LLDP Info is 

$CDPINFO

Internal IP Configuration is 

$INTERNALIP

Further DHCP Configuration information is

$DHCPSVR

" | sudo tee /tmp/net-config

