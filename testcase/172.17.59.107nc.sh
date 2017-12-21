#!/bin/bash
senddev=ens160
receip=172.17.59.234
receport=8887
mac=
gateway=$(ip -4 -o route get $receip|/usr/bin/cut -f 3 -d ' ')
if echo $gateway|/bin/grep -q '^[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+$'
then
    mac=$(ip -4 neigh show $gateway|/usr/bin/cut -f 5 -d ' ')
else
    /bin/ping -c 2 $receip > /dev/null
    mac=$(ip -4 neigh show $receip|/usr/bin/cut -f 5 -d ' ')
fi
[ x$mac = x ] && exit
echo 7 > /proc/sys/kernel/printk
/sbin/modprobe -r netconsole
/sbin/modprobe netconsole netconsole=@/$senddev,$receport@$receip/$mac