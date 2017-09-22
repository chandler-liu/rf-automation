#!/bin/bash
cp -rf dhcp /etc/
cp -rf tftpboot /var/lib/

rm -rf /var/www/html
ln -s /var/lib/tftpboot /var/www/html
/etc/init.d/apache2 restart

echo If you want to restrict the DHCP network card, please modify /etc/default/isc-dhcp-server INTERFACE setting
/etc/init.d/isc-dhcp-server restart

