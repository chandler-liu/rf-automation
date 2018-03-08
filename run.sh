#!/bin/bash

# Initiate default parameter
downloadisoflag=1
installisoflag=1
buildserver=172.17.59.124
md5server=192.168.168.6
isopath=/iso
scriptrootpath=/work/automation-test/rf-automation-7.0
product=virtualstor_scaler_master

# Specified parameter

usage()
{
    echo -e "usage:\n$0 [-h] [-d downisoflag] [-i installflag] [-p {product_name}]"
    echo "  -d      0: not download iso before execute testcases"
    echo "          1: download iso before execute testcases [default]"
    echo "  -i      0: skip iso installation testcases"
    echo "          1: install iso before execute other testcases [default]"
    echo "  -p      {product_name}"
    echo "  -h      display this help"
}

while [ "$1" != "" ]; do
    case $1 in
        -d | --downisoflag )    shift
                                downloadisoflag=$1
                                ;;
        -i | --installflag )    shift
                                installisoflag=$1
                                ;;
        -p | --product )        shift
                                product=$1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done


# Rocord automation start time for jenkins report
START_TIME=`date "+%Y %m %d %H:%M:%S"`
echo START_TIME=${START_TIME} > $scriptrootpath/build.properties

retry=0
cd $isopath
while [ $downloadisoflag -eq 1 -a $retry -lt 3 ]; do
{
    rm -rf *.iso
    rm -rf iso
    rm -rf trusty/$product
    dailyfolder=`ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${buildserver} "ls /vol/share/Builds/buildwindow/trusty/$product/builds/"|tail -n 1`
    if [ -z $dailyfolder ]; then
        echo "Fail to find build path!!!"
        retry=$((retry+1)) && continue
    fi
    
    scp root@${buildserver}:/vol/share/Builds/buildwindow/trusty/$product/builds/$dailyfolder/*.iso .

    ## Check md5sum ##
    echo "Start to check md5 of `ls *.iso`"
    isomd5sum=`md5sum *.iso | awk '{print $1}'`
    expectedmd5sum=`ssh chandler@$md5server "md5sum /var/lib/jenkins/jobs//builds/$dailyfolder/archive/*.iso" | awk '{print $1}'`
    if [ -z "$expectedmd5sum" ]
    then
        echo ":< Cannot retrieve md5sum of ISO from $md5server!"
        exit 1
    fi
    echo Download: $isomd5sum, Server: $expectedmd5sum
    if [ "$isomd5sum" != "$expectedmd5sum" ]; then
        echo ":< File md5sum check is failed!"
        retry=$((retry+1)) && continue
    fi
    echo ":D ISO is downloaded successfully!"
    break
}
done

if [ $retry -eq 3 ]; then
    echo ":< Have retried 3 times, exit!"
    exit 1
fi

sudo killall vblade
echo "Start to mount `ls *.iso`"
sudo /usr/sbin/vblade 2 0 ens192 $isopath/*.iso &
if [ $installisoflag -eq 1 ];then
    pybot --logLevel TRACE -d $scriptrootpath/report $scriptrootpath/testcase
else
    pybot --logLevel TRACE -e install -d $scriptrootpath/report $scriptrootpath/testcase
fi

# Rocord automation build for jenkins report
COMMON_CONFIG_PATH="$scriptrootpath/testcase/00_commonconfig.txt"
CLUSER_NODE_IP=`cat ${COMMON_CONFIG_PATH}  | grep @{PUBLICIP} | awk -F " " '{print $NF}'`
ROOT_PASSWORD=`cat ${COMMON_CONFIG_PATH}  | grep \$\{PASSWORD\} | awk -F " " '{print $NF}'`
ssh-keygen -f "/var/lib/jenkins/.ssh/known_hosts" -R ${CLUSER_NODE_IP}
ISO_NAME=`sshpass -p ${ROOT_PASSWORD} ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${CLUSER_NODE_IP} cat /var/log/installer/media-info`
echo ISO_NAME=${ISO_NAME} >> $scriptrootpath/build.properties

# Rocord automation end time for jenkins report
END_TIME=`date "+%Y %m %d %H:%M:%S"`
echo END_TIME=${END_TIME} >> $scriptrootpath/build.properties
