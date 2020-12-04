#!/bin/bash

sleep 75s

CDPINFO=`/usr/sbin/lldpctl`

EXTERNALIP=`curl ifconfig.co`

INTERNALIP=`ip addr | grep eth0 -A 3`

DHCPSVR=`nmap --script broadcast-dhcp-discover -e eth0`

echo "Current External IP address is $EXTERNALIP

LLDP Info is 

$CDPINFO

Internal IP Configuration is 

$INTERNALIP

Further DHCP Configuration information is

$DHCPSVR

