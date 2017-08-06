#!/bin/bash

# Initiate default parameter
serverflag=0 # 0 represents 172.16.146.220, 1 represents 125.227.238.56, 2 represents 192.168.163.254
downloadisoflag=1
installisoflag=1
md5server=192.168.168.8
isopath=/iso
scriptrootpath=/work/automation-test/rf-automation
product=virtualstor_scaler_master

# Specified parameter

usage()
{
    echo -e "usage:\n$0 [-h] [-d downisoflag] [-i installflag] [-s buildserverflag] [-p {product_name}]"
    echo "  -d      0: not download iso before execute testcases"
    echo "          1: download iso before execute testcases [default]"
    echo "  -i      0: skip iso installation testcases"
    echo "          1: install iso before execute other testcases [default]"
    echo "  -s      0: use 172.16.146.220 as build server [default]"
    echo "          1: use 125.227.238.56 as build server"
    echo "          2: use 192.168.163.254 as build server"
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
        -s | --buildserver )    shift
                                serverflag=$1
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
    rm -rf precise/$product
    case $serverflag in
        0 ) dailyfolder=`ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@172.16.146.220 "ls /vol/share/Builds/buildwindow/precise/$product/builds/"|tail -n 1`
            ;;
        1 ) # Register first
            # wget -q -O - --no-check-certificate https://$buildserver/HeyITsMyIP.html
            # sleep 300
            dailyfolder=`wget -q -O - --no-check-certificate https://125.227.238.56/precise/$product/builds/ |grep "201"|tail -n 1|cut -b 28-46` # 125.227.238.56's
            ;;
        2 ) dailyfolder=`wget -q -O - --no-check-certificate http://192.168.163.254/iso/precise/$product/builds/ |grep "201"|tail -n 1|cut -b 74-92` # 192.168.163.254's
            ;;
        * ) echo ":< Server flag is not found!"
            exit 1
    esac

    if [ -z $dailyfolder ]; then
        echo "Fail to find build path!!!"
        retry=$((retry+1)) && continue
    fi
    
    case $serverflag in
        1 ) wget --no-check-certificate -r -np -nH --accept=*iso --tries=0 -c  https://125.227.238.56/precise/$product/builds/$dailyfolder/
            ;;
        2 ) wget --no-check-certificate -r -np -nH --accept=*iso --tries=0 -c  http://192.168.163.254/iso/precise/$product/builds/$dailyfolder/
            ;;
    esac

    if [ $? != 0 ]; then
        echo "Download ISO fail!!!"
        retry=$((retry+1)) && continue
    fi

    case $serverflag in
        0 ) scp root@172.16.146.220:/vol/share/Builds/buildwindow/precise/$product/builds/$dailyfolder/*.iso .
            ;;
        1 ) cp precise/$product/builds/$dailyfolder/*.iso .
            ;;
        2 ) cp iso/precise/$product/builds/$dailyfolder/*.iso .
    esac

    ## Check md5sum ##
    echo "Start to check md5 of `ls *.iso`"
    isomd5sum=`md5sum *.iso | awk '{print $1}'`
    expectedmd5sum=`sudo ssh bruce@$md5server "md5sum /home/jenkins/jobs/$product/builds/$dailyfolder/archive/*.iso" | awk '{print $1}'`
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
sudo /usr/sbin/vblade 1 0 ens160 $isopath/*.iso &
if [ $installisoflag -eq 1 ];then
    pybot --logLevel DEBUG -d $scriptrootpath/report $scriptrootpath/testcase
else
    pybot --logLevel DEBUG -e install -d $scriptrootpath/report $scriptrootpath/testcase
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
