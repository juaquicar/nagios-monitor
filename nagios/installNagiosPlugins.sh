#!/bin/sh

echo "[+] PREQUISITOS COMUNES"
echo "\tsudo apt-get update"
echo "\tsudo apt-get install -y autoconf gcc libc6 libmcrypt-dev make libssl-dev wget bc gawk dc build-essential snmp libnet-snmp-perl gettext"
read -p "[+] Pulsa enter para continuar..."
tar zxf nagios-plugins.tar.gz
cd /tmp/nagios-plugins-release-2.4.10/
sudo ./tools/setup
sudo ./configure
sudo make
sudo make install
echo "[+] Plugins instalados en /usr/local/nagios/libexec/"
