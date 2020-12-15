#!/bin/bash

EMAIL_USE=N
SLACK_USE=N
RASPI=H
DISTRO_FAM=`cat /etc/os-release | grep ID_LIKE | cut -d '=' -f 2`
MUTT_RC=`sudo ls -al /root/.muttrc`
CRON=`crontab -l | grep '@reboot /bin/bash CDPPi.sh'`

read -p "Do you wish to send responses via email? (y/N) " EMAIL_USE

read -p "Do you wish to send responses via slack API? (y/N) " SLACK_USE

read -p "Is this installation for a Raspberry Pi? (y/n/Help) " RASPI

if [ \( "$RASPI" = h \) -o \( "$RASPI" = H \) ]; then

	echo "Raspberry Pi Installs Trigger Script on boot 
Non-Raspberry Pi Installations Trigger Script on interface activation"

	read -p "Is this installation for a Raspberry Pi? (Y/n) " RASPI

fi

echo "Updating Repositories and Installing Globally Needed Applications"

if [ -z "$DISTRO_FAM" ];then
	DISTRO_FAM=`cat /etc/os-release | grep ID | grep -v _ | cut -d '=' -f 2`
fi

if [ \( "$RASPI" = Y \) -o \( "$RASPI" = y \) ]; then

	if [ $DISTRO_FAM == "debian" ];then
	
		sudo apt update -y
		sudo apt install lldpd nmap -y 
	
	else 
	
		echo 'Need to Configure Support for your Distribution 1'
	
	fi

else

        if [[ $DISTRO_FAM = 'debian' ]];then

                sudo apt update -y
                sudo apt install lldpd nmap -y

	elif [[ $DISTRO_FAM =~ rhel ]];then

		sudo yum install lldpd nmap -y

	else

		echo $DISTRO_FAM
                echo 'Need to Configure Support for your Distribution 2'

        fi

fi

#Copies Saved LLDPD Service File to Service File Location

echo "Configuring LLDPD to Accept CDP Packets and not Broadcast LLDP/CDP"

sudo cp ./lldpd.service /lib/systemd/system/lldpd.service
sudo systemctl daemon-reload
sudo systemctl restart lldpd


#Install/Configure Mail Client

if [ \( "$EMAIL_USE" = Y \) -o \( "$EMAIL_USE" = y \) ]; then

        if [[ $DISTRO_FAM == "debian" ]];then

                sudo apt install mutt -y

	elif [[ $DISTRO_FAM =~ rhel ]];then

                sudo yum install mutt -y

        else

                echo 'Need to Configure Support for your Distribution'

        fi

	if [[ -z "$MUTT_RC" ]]; then
	
		sudo echo 'Configuring .muttrc, Further Information is needed'
	
		read -p 'E-Mail Address: ' MAIL_ACCT
	
		read -p 'Friendly Mail Name (Bob Smith Raspberry Pi): ' MAIL_ALIAS
	
		read -p 'Enter Password: ' -s MAIL_PW 
	
		echo " "
	
		read -p 'SMTP Server Address: ' SMTP_SRV
	
		read -p 'SMTP Port Number (Typically 587): ' SMTP_PORT
	
		echo 'set from = "'$MAIL_ACCT'"
		set realname = "'$MAIL_ALIAS'"
		
		set smtp_url = "smtp://'$MAIL_ACCT'@'$SMTP_SRV':'$SMTP_PORT'/"
		set smtp_pass = "'$MAIL_PW'"
		'  | sudo tee /root/.muttrc

                echo 'set from = "'$MAIL_ACCT'"
                set realname = "'$MAIL_ALIAS'"

                set smtp_url = "smtp://'$MAIL_ACCT'@'$SMTP_SRV':'$SMTP_PORT'/"
                set smtp_pass = "'$MAIL_PW'"
                ' | tee ~/.muttrc
	
	else
	
		echo '.muttrc Already Configured'
	
	fi

fi

#NEED SAFETY CHECK TO NOT MAKE MUTTRC IF ONE EXISTS

if [ \( "$SLACK_USE" = Y \) -o \( "$SLACK_USE" = y \) ]; then

        if [[ $DISTRO_FAM == "debian" ]];then

                sudo apt install python3 python3-pip gcc -y
                sudo pip3 install slackclient

		elif [[ $DISTRO_FAM =~ rhel ]];then

                sudo yum install python3 python3-pip python3-devel gcc -y
	        sudo pip3 install slackclient

        else

                echo 'Need to Configure Support for your Distribution'

        fi

	if [ ! -f /bin/netinfo-to-slack.py ]; then

		read -p "Provide Slack Token: " SLACK_TOKEN
	
		read -p "Provide Channel/User to respond to (For Example #general or @walt-smith): " SLACK_CHAN
	
		sudo echo '
		#!/usr/bin/env python3
	
		import slack
		import os
		import sys
	
		SLACK_TOKEN='$SLACK_TOKEN'
	
		mystring = sys.stdin.read()
		#mystring = ':dolphin:'
	
		client = slack.WebClient(token=SLACK_TOKEN)
	
		client.chat_postMessage(channel='$SLACK_CHAN', text= mystring)
		' | sudo tee /bin/netinfo-to-slack.py 
	
		sudo chmod +x /bin/netinfo-to-slack.py

	fi
fi

#Install Script

echo "Installing Discovery Script"

sudo cp -R ./CDPPi.sh /bin/CDPPi.sh

if [ \( "$EMAIL_USE" = Y \) -o \( "$EMAIL_USE" = y \) ]; then

	read -p "Email Account to Recieve E-Mail: " REPT_ACCT

	sudo echo 'cat /tmp/net-config | mutt -s Network Configuration '$REPT_ACCT'' | sudo tee -a /bin/CDPPi.sh

fi

if [ \( "$SLACK_USE" = Y \) -o \( "$SLACK_USE" = y \) ]; then

	sudo echo 'cat /tmp/net-config | /bin/netinfo-to-slack.py' | sudo tee -a /bin/CDPPi.sh 

fi

sudo echo 'rm /tmp/net-config' | sudo tee -a /bin/CDPPi.sh

sudo chmod +x /bin/CDPPi.sh

#Install Cron entry if none exists if Raspberry Pi

if [ \( "$RASPI" = Y \) -o \( "$RASPI" = y \) ]; then

	if [ ! -v $CRON = '@reboot /bin/bash CDPPi.sh' ]; then
	
		#write out current crontab
		sudo crontab -l > ./mycron
		#echo new cron into cron file
		sudo echo "@reboot /bin/bash CDPPi.sh" >> ./mycron
		#install new cron file
		sudo cat ./mycron | sudo crontab -
		rm ./mycron
	
	else
	
		echo "crontab entry exists"
	
	fi

fi

#Configure Network Manager Dispatcher

if [ \( "$RASPI" = N \) -o \( "$RASPI" = n \) ]; then

	if [ "$DISTRO_FAM" = debian ];then

                sudo apt install network-manager -y
		sudo sed -i 's/^\([^#].*\)/# \1/g' /etc/network/interfaces
		sudo sed -i 's/false/true/g' /etc/NetworkManager/NetworkManager.conf
		sudo systemctl restart NetworkManager

	elif [[ $DISTRO_FAM =~ rhel ]];then

                echo 'No need to Install Network Manager'

	else
	
		echo 'Network Manager May need to be installed'

        fi

	IF=`nmcli conn | grep ethernet | grep -v '\-\-' | awk '{print $1;}'`

	sudo echo '#!/usr/bin/env bash
	
	interface=$1
	event=$2
	
	if [[ $interface != "'$IF'" ]] || [[ $event != "up" ]]
	then
	  return 0
	fi
	
	sleep 75 && /bin/CDPPi.sh' | sudo tee /etc/NetworkManager/dispatcher.d/88-net-info
	sudo chmod +x /etc/NetworkManager/dispatcher.d/88-net-info
	sudo systemctl restart NetworkManager

fi
