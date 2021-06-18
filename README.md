# CDPPi
Network Discovery Tool to be Deployed to a Raspberry Pi, this isn't exactly a fancy one, tweaking and tools will be performed later, merely is leveraging mutt, lldpd, and nmap to gather basic information and sending it via email. Additional Slack notifications are available if one configures a bot with a slack token to send out notifications.

Just a simple set of scripts to install and configure CDPPi.

This Auto-Installer script is intended for use with Raspbian

For alternative distros you're free to make alterations to make it work as needed for them

# Installation

```bash
git clone https://github.com/wyatt-kinkade/CDPPi.git
cd CDPPi/
chmod +x ./install.sh
./install.sh
```

