

tar xvfz ./nrpe-4.1.1.tar.gz
cd nrpe-4.1.1/
./configure --enable-command-args --with-ssl-lib=/usr/lib/x86_64-linux-gnu/
make all
sudo make install-groups-users
sudo make install
sudo make install-config
sudo make install-init
systemctl enable nrpe
cp ./nrpe.cfg /usr/local/nagios/etc/nrpe.cfg
cp ./custom_check_mem /usr/local/nagios/libexec/
chmod 755 /usr/local/nagios/libexec/custom_check_mem
chown nagios:nagios /usr/local/nagios/libexec/custom_check_mem
sudo systemctl start nrpe.service
/usr/local/nagios/libexec/check_nrpe -H 127.0.0.1


