#!/bin/bash
cp -rf dhcp /etc/
cp -rf tftpboot /var/lib/

mv /var/www/html /var/www/html_bak_`date +%s`
ln -s /var/lib/tftpboot /var/www/html
/etc/init.d/apache2 restart

echo If you want to restrict the DHCP network card, please modify /etc/default/isc-dhcp-server INTERFACE setting
/etc/init.d/isc-dhcp-server restart

