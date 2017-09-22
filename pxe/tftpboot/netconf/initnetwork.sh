#!/bin/sh
cp /root/interfaces /etc/network/interfaces
/sbin/ifup -a
#sed -i.bak 's/^#\ \ \ StrictHostKeyChecking ask/\ \ \ \ StrictHostKeyChecking no/' /etc/ssh/ssh_config
python -c "from ezs3.utils import start_web_ui,start_freenode_service;start_web_ui();start_freenode_service()"
python -c "from ezs3.config import Ezs3CephConfig; Ezs3CephConfig()"
sed -i '/\/root\/initnetwork.sh/d' /etc/rc.local
