#!/bin/bash

#buildserver=192.168.163.254
buildserver=125.227.238.56
md5server=192.168.168.8
downisoflag=1
retry=0
isopath=/iso
product=virtualstor_scaler_master

# add get ISO build name and RF start&end time
START_TIME=`date "+%Y %m %d %H:%M:%S"`
echo START_TIME=${START_TIME} > /work/automation-test/rf-automation/build.properties

while [ $downisoflag = 1 -a $retry -lt 3 ]; do
{
    cd $isopath
    rm -rf iso
    rm -rf precise/$product
    # Register first
    #wget -q -O - --no-check-certificate https://$buildserver/HeyITsMyIP.html
    #sleep 300
    dailyfolder=`wget -q -O - --no-check-certificate https://$buildserver/precise/$product/builds/ |grep "2016"|tail -n 1|cut -b 28-46` # 125.227.238.56's
    #dailyfolder=`wget -q -O - --no-check-certificate http://$buildserver/iso/$product/builds/ |grep "2016"|tail -n 1|cut -b 74-92`
    if [ -z $dailyfolder ]; then
        echo "Fail to find build path!!!"
        retry=$((retry+1)) && continue
    fi

    wget --no-check-certificate -r -np -nH --accept=*iso --tries=0 -c  https://$buildserver/precise/$product/builds/$dailyfolder/ # 125.227.238.56's
    #wget --no-check-certificate -r -np -nH --accept=*iso --tries=0 -c  http://$buildserver/iso/$product/builds/$dailyfolder/  # 192.168.163.254's
    if [ $? != 0 ]; then
        echo "Download ISO fail!!!"
        retry=$((retry+1)) && continue
    fi
    cp precise/$product/builds/$dailyfolder/*.iso daily.iso # 125.227.238.56's
    #cp iso/$product/builds/$dailyfolder/*.iso daily.iso # 192.168.163.254's

    ## Check md5sum ##
    echo Start to check md5
    isomd5sum=`md5sum daily.iso | awk '{print $1}'`
    expectedmd5sum=`sudo ssh bruce@$md5server "md5sum /home/jenkins/jobs/$product/lastSuccessful/archive/*.iso" | awk '{print $1}'`
    echo Download: $isomd5sum, Server: $expectedmd5sum
    if [ "$isomd5sum" != "$expectedmd5sum" ]; then
        echo "File md5sum check is failed!!!"
        retry=$((retry+1)) && continue
    fi
    echo "ISO is downloaded successfully!"
    break
}
done

if [ $retry -eq 3 ]; then
    echo "Have retried 3 times, exit!"
    exit 1
fi

sudo killall vblade
sudo /usr/sbin/vblade 1 0 ens160 $isopath/daily.iso &
#pybot --logLevel DEBUG -e install testcase
#pybot --logLevel DEBUG testcase

COMMON_CONFIG_PATH="/work/automation-test/rf-automation/testcase/00_commonconfig.txt"
CLUSER_NODE_IP=`cat ${COMMON_CONFIG_PATH}  | grep @{PUBLICIP} | awk -F " " '{print $NF}'`
ROOT_PASSWORD=`cat ${COMMON_CONFIG_PATH}  | grep \$\{PASSWORD\} | awk -F " " '{print $NF}'`
# Remove ECDSA key from jenkins's known_hosts
ssh-keygen -f "/root/.ssh/known_hosts" -R ${CLUSER_NODE_IP}
ISO_NAME=`sshpass -p ${ROOT_PASSWORD} ssh -o StrictHostKeyChecking=no root@${CLUSER_NODE_IP} cat /var/log/installer/media-info`
echo ISO_NAME=${ISO_NAME} >> /work/automation-test/rf-automation/build.properties

pybot --logLevel DEBUG -d /work/automation-test/rf-automation/report /work/automation-test/rf-automation/testcase

END_TIME=`date "+%Y %m %d %H:%M:%S"`
echo END_TIME=${END_TIME} >> /work/automation-test/rf-automation/build.properties
