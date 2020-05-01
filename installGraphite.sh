#!/bin/bash

echo "Disabling selinux"
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
setenforce Permissive

echo "Running updates via yum"
yum update -y

echo "Installing yum utils"
yum install yum-utils -y

echo "Installing gcc"
yum install gcc -y

echo "Installing EPEL repo"
yum install epel-release -y

echo "Install python-devel"
yum install python-devel -y

echo "Installing Python Django and pytz"
yum install python-django -y

echo "Installing Cairocffi"
yum install python-cairocffi -y

echo "Installing cairo-devel"
yum install cairo-devel -y

echo "Installing libffi-devel"
yum install libffi-devel -y

echo "Installing scandir"
yum install python2-scandir -y

echo "Installing fontconfig"
yum install fontconfig -y

echo "Installing apache"
yum install httpd -y

echo "Enabling the httpd unit file"
systemctl enable httpd

echo "Installing mod_wsgi for apache"
yum install mod_wsgi -y

echo "Installing Pip"
yum install python2-pip -y

echo "Installing Whisper, Carbon, and Graphite via pip"
PYTHONPATH="/opt/graphite/lib/:/opt/graphite/webapp/"
pip install --no-binary=:all: https://github.com/graphite-project/whisper/tarball/master
pip install https://github.com/graphite-project/carbon/tarball/master
pip install --no-binary=:all: https://github.com/graphite-project/graphite-web/tarball/master

echo "Setting up the database schema for Graphite Web"
PYTHONPATH=/opt/graphite/webapp /usr/lib/python2.7/site-packages/django/bin/django-admin.py migrate --settings=graphite.settings

echo "Create the Graphite Web static content"
PYTHONPATH=/opt/graphite/webapp /usr/lib/python2.7/site-packages/django/bin/django-admin.py collectstatic --noinput --settings=graphite.settings

echo "Create the graphite.wsgi from the example"
cp -v /opt/graphite/conf/graphite.wsgi.example /opt/graphite/conf/graphite.wsgi

echo "Setup the local_settings.py"
cp -v /opt/graphite/webapp/graphite/local_settings.py.example /opt/graphite/webapp/graphite/local_settings.py

echo "Creating secret key in local_settings.py"
sed -i "s/UNSAFE_DEFAULT/$(</dev/urandom tr -dc '12345@#$%qwertQWERTasdfgASDFGzxcvbZXCVB' | head -c200)/" /opt/graphite/webapp/graphite/local_settings.py

echo "Copying apache configuration into place."
mv -v /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf-ggd-cpanel-install-bak
cp -v /root/ggd-cpanel/graphite/httpd.conf /etc/httpd/conf/httpd.conf

echo "Creating user for the carbon daemon"
adduser --system --no-create-home --shell=/sbin/nologin

echo "Updating ownership of whisper storage for the carbon daemon"
chown -R carbon:carbon /opt/graphite/storage

echo "Updating ownership of webapp for apache"
chown -R apache:apache /opt/graphite/webapp

echo "Copy main carbon configuration into place"
cp -v /opt/graphite/conf/carbon.conf.example /opt/graphite/conf/carbon.conf

echo "Copy carbon storage schema configuration into place"
cp -v /opt/graphite/conf/storage-schemas.conf.example /opt/graphite/conf/storage-schemas.conf

echo "Copying carbon unit file into place"
cp -v /root/ggd-cpanel/graphite/carbon.service /etc/systemd/system/
systemctl daemon-reload

echo "Enabling the carbon daemon"
systemctl enable carbon

echo "Starting the carbon daemon"
systemctl start carbon

echo "Starting apache"
systemctl start httpd
echo
echo
echo
echo "Depending on the following output, you may need to restart the server to load required libraries and software:"
needs-restarting -s
needs-restarting -r
