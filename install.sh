#!/bin/bash

DISTRO=`cat /etc/os-release | grep ID | grep -v _ | cut -d '=' -f 2`
CRON=`crontab -l | grep '@reboot /bin/bash CDPPi.sh'`

#Fail if not Raspian
if [ $DISTRO != "raspbian" ]; then

printf "unsupported distribution, manual instructions are in readme.txt \n"

exit

fi

#Basic Checks
while [ -z $EMAIL_INPUT ]; do
read -p "Do you wish to send responses via email? (y/n) " EMAIL_INPUT
done
EMAIL_USE=${EMAIL_INPUT^^}

while [ -z $SLACK_INPUT ]; do
read -p "Do you wish to send responses via slack API? (y/n) " SLACK_INPUT
done
SLACK_USE=${SLACK_INPUT^^}

echo "$EMAIL_USE"
echo "$SLACK_USE"

#if [ $EMAIL_USE == "N" -a $SLACK_USE == "N" ]; then
if [ $EMAIL_USE == "N" ] && [ $SLACK_USE == "N" ]; then

printf "No notifications are to be sent, Ending Script \n" ; exit

fi

#Install packages that are needed regardless
echo "Updating Repositories and Installing Globally Needed Applications"

sudo apt update -y
sudo apt install lldpd nmap curl -y


#Copies Saved LLDPD Service File to Service File Location

echo "Configuring LLDPD to Accept CDP Packets and not Broadcast LLDP/CDP"

sudo cp ./lldpd.service /lib/systemd/system/lldpd.service
sudo systemctl daemon-reload
sudo systemctl restart lldpd


#Install/Configure Mail Client

if [ $EMAIL_USE = "Y" ]; then

                sudo apt install mutt -y

        if sudo bash -c '[ ! -f /root/.muttrc ]'; then

                echo 'Configuring .muttrc, Further Information is needed'

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

                echo '.muttrc Already Configured for root user, further configuration may be required, Delete file to recreate it with this script if needed, or edit the file manually'

        fi

fi

#NEED SAFETY CHECK TO NOT MAKE MUTTRC IF ONE EXISTS

if [ $SLACK_USE = "Y" ]; then

sudo apt install python3 python3-pip gcc -y
sudo pip3 install slackclient

    if [ ! -f /bin/netinfo-to-slack.py ]; then

    read -p "Provide Slack Token: " SLACK_TOKEN

    read -p "Provide Channel/User to respond to (For Example #general or @walt-smith): " SLACK_CHAN

    echo "#!/usr/bin/env python3

import slack
import os
import sys

SLACK_TOKEN='$SLACK_TOKEN'
SLACK_CHAN='$SLACK_CHAN'
mystring = sys.stdin.read()

client = slack.WebClient(token=SLACK_TOKEN)

client.chat_postMessage(channel=SLACK_CHAN, text= mystring)
" | sudo tee /bin/netinfo-to-slack.py

    sudo chmod +x /bin/netinfo-to-slack.py

    else

    printf "If you need to change slack token or channel, please delete /bin/netinfo-to-slack.py and run this script again or manually edit the file with your preferred text editor"

    fi
fi

#Install Script

echo "Installing Discovery Script"

sudo cp -R ./CDPPi.sh /bin/CDPPi.sh

if [ $EMAIL_USE = "Y" ]; then

        read -p "Email Account to Recieve E-Mail: " REPT_ACCT

        sudo echo "cat /tmp/net-config | mutt -s 'Network Configuration' $REPT_ACCT" | sudo tee -a /bin/CDPPi.sh

fi

if [ $SLACK_USE = "Y" ]; then

        sudo echo 'cat /tmp/net-config | /bin/netinfo-to-slack.py' | sudo tee -a /bin/CDPPi.sh

fi

sudo echo 'sudo rm /tmp/net-config' | sudo tee -a /bin/CDPPi.sh

sudo chmod +x /bin/CDPPi.sh

#Install Cron entry if none exists if Raspberry Pi

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
