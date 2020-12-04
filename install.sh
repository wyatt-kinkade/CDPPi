#!/bin/bash

echo "Updating Repositories and Installing Needed Applications"

DISTRO_FAM=`cat /etc/os-release | grep ID_LIKE | cut -d '=' -f 2`

if [ "$DISTRO_FAM" = debian ];then

	sudo apt update -y
	sudo apt install lldpd mutt nmap -y 

#elif [ "$DISTRO_FAM" = 'redhat fedora' ];then
#
#	sudo yum install lldpd mutt nmap

else 

	echo 'Need to Configure Support for your Distribution'

fi

#Copies Saved LLDPD Service File to Service File Location

echo "Configuring LLDPD to Accept CDP Packets and not Broadcast LLDP/CDP"

sudo cp ./lldpd.service /lib/systemd/system/lldpd.service
sudo systemctl daemon-reload
sudo systemctl restart lldpd

#NEED SAFETY CHECK TO NOT MAKE MUTTRC IF ONE EXISTS

if [ ! -f ~/.muttrc ]; then

	echo 'Configuring .muttrc, Further Information is needed'

	read -p 'E-Mail Address: ' MAIL_ACCT

	read -p 'Friendly Mail Name (Bob Smith Raspberry Pi): ' MAIL_ALIAS

	read -p 'Enter Password: ' -s MAIL_PW 

	echo " "

	read -p 'SMTP Server Address: ' SMTP_SRV

	read -p 'SMTP Port Number (Typically 587): ' SMTP_PORT

	read -p 'IMAP Server Address: ' IMAP_SRV

	read -p 'IMAP Port Number (Typically 993): ' IMAP_PORT

	echo '
	set from = "'$MAIL_ACCT'"
	set realname = "'$MAIL_ALIAS'"
	
	set smtp_url = "smtp://'$MAIL_ACCT'@'$SMTP_SRV':'$SMTP_PORT'/"
	set smtp_pass = "'$MAIL_PW'"
	set imap_user = "'$MAIL_ACCT'"
	set imap_pass = "'$MAIL_PW'"
	
	set folder = "imaps://'$IMAP_SRV':'$IMAP_PORT'"
	set spoolfile = "+INBOX"
	
	#Where to put the stuff
	set header_cache = "~/.mutt/cache/headers"
	set message_cachedir = "~/.mutt/cache/bodies"
	set certificate_file = "~/.mutt/certificates"
	
	# Etc
	set mail_check = 30
	set move = no
	set imap_keepalive = 900
	set sort = threads
	set editor = "vim"
	
	# GnuPG bootstrap
	# source ~/.mutt/gpg.rc
	'  >> ~/.muttrc

else

	echo '.muttrc Already Configured'

fi

#Install Script

if [ ! -d ~/bin/ ]; then

	mkdir ~/bin/

fi

if [ ! -f ~/bin/net-info.sh ]; then

	echo "Installing Discovery Script"

	cp ./net-info.sh ~/bin/net-info.sh

	echo '" | mutt -s "Network Configuration" '$MAIL_ACCT'' >> ~/bin/net-info.sh

	`chmod +x ~/bin/net-info.sh`
else

	echo "ERROR: File Exists, Possible Previous Version or Alternative Script/Program, please check ~/bin/net-info.sh"

fi

#Install Cron entry if none exists

CRON=`crontab -l | grep '@reboot /bin/bash net-info.sh'`

if [ ! -v $CRON ]; then

	#write out current crontab
	crontab -l > ./mycron
	#echo new cron into cron file
	echo "@reboot /bin/bash net-info.sh" >> ./mycron
	#install new cron file
	cat ./mycron | crontab -
	rm ./mycron

else

	echo "crontab entry exists"

fi
