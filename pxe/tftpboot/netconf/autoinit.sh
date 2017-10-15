#!/bin/sh
sed -i 's/KeepAlive On/KeepAlive Off/' /etc/apache2/apache2.conf;
sed -i.bak 's/^#\ \ \ StrictHostKeyChecking ask/\ \ \ \ StrictHostKeyChecking no/' /etc/ssh/ssh_config
python -c "from ezs3.utils import start_web_ui,start_freenode_service;start_web_ui();start_freenode_service()"
python -c "from ezs3.config import Ezs3CephConfig; Ezs3CephConfig()"
sed -i '/\/root\/autoinit.sh/d' /etc/rc.local
