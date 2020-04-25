#!/bin/bash

# This script was created by tha hosting admin
# Find us on youtube by searching for tha hosting admin

if [[ -z "$1" ]]
   echo "You must specify the IP address or hostname of your Graphite server. Example:"
echo "installDiamond.sh 111.111.111.111"
fi

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

echo "Installing EPEL Repo"
yum install epel-release -y

echo "Installing python-pip"
yum install python-pip -y

echo "Installing Python Diamond"
pip install diamond

echo "Setting up the configuration"
cd ~
mkdir -pv /etc/diamond/collectors
mkdir -v /etc/diamond/configs
mkdir -v /var/log/diamond
chown -v pydiamond /var/log/diamond
cp -Rv ~/ggd-cpanel/diamond /etc/diamond
sed -i "s/graphitehostplaceholder/$1/" /etc/diamond/diamond.conf
cp -v ~/ggd-cpanel/diamond/diamond.service.example /etc/systemd/system/

echo "Adding pydiamond user"
adduser --system --no-create-home --shell=/sbin/nologin pydiamond

echo "Enabling systemd unit file"
systemctl enable diamond

echo "Starting diamond"
systemctl start diamond
systemctl status diamond
