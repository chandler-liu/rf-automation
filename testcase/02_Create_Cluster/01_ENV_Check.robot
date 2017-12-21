*** Settings ***
Resource          ../00_commonconfig.txt
Resource          ../keyword/keyword_verify.txt
Resource          ../keyword/keyword_system.txt
Resource          ../keyword/keyword_cgi.txt


*** Variables ***


*** Test Cases ***
ENV_Check
    [Tags]    Check
    : FOR    ${ip}    IN    @{PUBLICIP}
    \    log    Modify apache.conf file on ${ip}
    \    Do SSH CMD    ${ip}    ${USERNAME}    ${PASSWORD}    sed \ -i 's/KeepAlive On/KeepAlive Off/' \ /etc/apache2/apache2.conf; /etc/init.d/apache2 restart
    \    Do SSH CMD    127.0.0.1    root    1    sshpass -p p@ssw0rd scp /work/automation-test/rf-automation-7.0/testcase/${ip}nc.sh root@${ip}:/root
	\    Do SSH CMD    ${ip}    ${USERNAME}    ${PASSWORD}    chmod +x ${ip}nc.sh
	\    Do SSH CMD    ${ip}    ${USERNAME}    ${PASSWORD}    echo /root/${ip}nc.sh >> /etc/rc.local
	\    Do SSH CMD    ${ip}    ${USERNAME}    ${PASSWORD}    bash /root/${ip}nc.sh
	log    Check Disk
    ${check_result}    Set Variable    False
    ${disk_check}=    Do SSH CMD    @{PUBLICIP}[0]    ${USERNAME}    ${PASSWORD}    fdisk -l | grep -i "/dev/sd[b-z]" | grep -v GPT | awk -F ":" '{print $2}' | awk -F " " '{print $1}' | awk 'BEGIN {min = 1999999} {if ($1<min) min=$1 fi} END {print "", min}'
    log    Get the Min disk info, size is ${disk_check}
    ${check_result}    Run Keyword IF    ${disk_check} > 8    Set Variable    True
    ...    ELSE    Set Variable    False
    Should Be Equal As Strings    True    ${check_result}
    ${data_disk_nums}=    Do SSH CMD    @{PUBLICIP}[0]    ${USERNAME}    ${PASSWORD}    lsblk |awk -F " " '{print $1}' | grep -v "─" | grep sd[a-z] | grep -v sda | wc -l
    ${disk_check}    Run Keyword IF    ${data_disk_nums}>=4    Set Variable    True
    ...    ELSE    Set Variable    False
    Should Be Equal As Strings    True    ${disk_check}
    

*** Keywords ***


