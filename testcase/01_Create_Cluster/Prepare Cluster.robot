*** Settings ***
Resource          ../00_commonconfig.txt
Resource          ../00_commonkeyword.txt
Resource          00_createclusterkeywords.txt

*** Test Cases ***
01_ENV_Check
    [Tags]    Check
    : FOR    ${ip}    IN    @{PUBLICIP}
    \    log    Modify apache.conf file on ${ip}
    \    Do SSH CMD    ${ip}    ${USERNAME}    ${PASSWORD}    sed \ -i 's/KeepAlive On/KeepAlive Off/' \ /etc/apache2/apache2.conf; /etc/init.d/apache2 restart
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

02_Create Cluster
    [Tags]    Check
    log    login UI with root account
    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${USERNAME}    ${PASSWORD}
    log    Get each node of public interface and storage interface
    log    Get node1's public and storage network interface
    ${node1_public_network}=    Do SSH CMD    @{PUBLICIP}[0]    ${USERNAME}    ${PASSWORD}    ifconfig | grep -i -B 1 @{PUBLICIP}[0] | grep -v 'inet' | awk -F " " '{print $1}' | sed s'/ //'g
    ${node1_storage_network}=    Do SSH CMD    @{PUBLICIP}[0]    ${USERNAME}    ${PASSWORD}    ifconfig | grep -i -B 1 @{STORAGEIP}[0] | grep -v 'inet' | awk -F " " '{print $1}' | sed s'/ //'g
    log    node1's public : ${node1_public_network}, storage network interface : ${node1_storage_network}
    log    Get node2's public and storage network interface
    ${node2_public_network}=    Do SSH CMD    @{PUBLICIP}[1]    ${USERNAME}    ${PASSWORD}    ifconfig | grep -i -B 1 @{PUBLICIP}[1] | grep -v 'inet' | awk -F " " '{print $1}' | sed s'/ //'g
    ${node2_storage_network}=    Do SSH CMD    @{PUBLICIP}[1]    ${USERNAME}    ${PASSWORD}    ifconfig | grep -i -B 1 @{STORAGEIP}[1] | grep -v 'inet' | awk -F " " '{print $1}' | sed s'/ //'g
    log    node2's public : ${node2_public_network}, storage network interface : ${node2_storage_network}
    log    Get node3's public and storage network interface
    ${node3_public_network}=    Do SSH CMD    @{PUBLICIP}[2]    ${USERNAME}    ${PASSWORD}    ifconfig | grep -i -B 1 @{PUBLICIP}[2] | grep -v 'inet' | awk -F " " '{print $1}' | sed s'/ //'g
    ${node3_storage_network}=    Do SSH CMD    @{PUBLICIP}[2]    ${USERNAME}    ${PASSWORD}    ifconfig | grep -i -B 1 @{STORAGEIP}[2] | grep -v 'inet' | awk -F " " '{print $1}' | sed s'/ //'g
    log    node3's public : ${node3_public_network}, storage network interface : ${node3_storage_network}
    log    Start to create a three nodes cluster
    log    Discover free nodes
    log    url: /cgi-bin/ezs3/json/freenode_list?interface=${node1_storage_network}
    Return Code Should be    /cgi-bin/ezs3/json/freenode_list?interface=${node1_storage_network}    0
    log    Start to create cluster, 3 nodes cluster and replicate=2
    Create Cluster
    log    Log in UI(Need to change account, should logout root account, then login with SDS Admin)
    Return Code Should be    /cgi-bin/ezs3/json/logout    0
    log    Log UI with SDS Admin
    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
    log    To get the product info, then input license
    ${product_info}=    Get Product Type
    log    The product is: ${product_info}
    : FOR    ${i}    IN RANGE    3
    \    Run Keyword If    '${product_info}'== 'Controller'    Input License    @{STORAGEIP}[${i}]    @{CONTROLLER_LICENSE}[${i}]
    \    ...    ELSE IF    '${product_info}'== 'Scaler'    Input License    @{STORAGEIP}[${i}]    @{SCALER_LICENSE}[${i}]
    \    ...    ELSE IF    '${product_info}'== 'Converger'    Input License    @{STORAGEIP}[${i}]    @{CONVERGER_LICENSE}[${i}]
    log    Create OSD on node: @{PUBLICIP}[0]
    @{data_devs}=    Create List    sdb
    Add Storage Volume    @{STORAGEIP}[0]    osd01    0    data    \    %5B%5D
    ...    False    False    False    @{data_devs}
    log    Enable OSD on node : @{PUBLICIP}[0]
    log    First, get network info
    log    Start to enable OSD on node: @{PUBLICIP}[0]
    Return Code Should Be    /cgi-bin/ezs3/json/node_role_enable_osd?ip=@{STORAGEIP}[0]&sv_list=osd01&cluster_iface=${node1_storage_network}&public_iface=${node1_public_network}    0
    log    Check if OSD is enabled on node : @{PUBLICIP}[0]
    Wait Until Keyword Succeeds    4 min    5 sec    Get OSD State    @{STORAGEIP}[0]    ONLINE    osd01
    sleep    10
    log    Create OSD on node: @{PUBLICIP}[1]
    @{data_devs}=    Create List    sdb
    Add Storage Volume    @{STORAGEIP}[1]    osd02    0    data    \    %5B%5D
    ...    False    False    False    @{data_devs}
    log    Enable OSD on node : @{PUBLICIP}[1]
    log    First, get network info
    log    Start to enable OSD on node \ : @{PUBLICIP}[1]
    Return Code Should Be    /cgi-bin/ezs3/json/node_role_enable_osd?ip=@{STORAGEIP}[1]&sv_list=osd02&cluster_iface=${node2_storage_network}&public_iface=${node2_public_network}    0
    log    Check if OSD is enabled on node: : @{PUBLICIP}[1]
    Wait Until Keyword Succeeds    4 min    5 sec    Get OSD State    @{STORAGEIP}[1]    ONLINE    osd02
    sleep    10
    log    Create OSD on node : @{PUBLICIP}[2]
    @{data_devs}=    Create List    sdb
    Add Storage Volume    @{STORAGEIP}[2]    osd03    0    data    \    %5B%5D
    ...    False    False    False    @{data_devs}
    log    Enable OSD on node : @{PUBLICIP}[2]
    log    First, get network info
    log    Start to enable OSD on node : @{PUBLICIP}[2]
    Return Code Should Be    /cgi-bin/ezs3/json/node_role_enable_osd?ip=@{STORAGEIP}[2]&sv_list=osd03&cluster_iface=${node3_storage_network}&public_iface=${node3_public_network}    0
    log    Check if OSD is enabled on node : @{PUBLICIP}[2]
    Wait Until Keyword Succeeds    4 min    5 sec    Get OSD State    @{STORAGEIP}[2]    ONLINE    osd03
    sleep    10
    log    End to enabled OSD on each node
    log    Check if cluster health status is HEALTH_OK
    Wait Until Keyword Succeeds    4 min    5 sec    Get Cluster Health Status
    log    Enable Gateway on each node
    log    Start to enable GW on node @{PUBLICIP}[0]
    Return Code Should Be    /cgi-bin/ezs3/json/gateway_role_enable?ip=@{STORAGEIP}[0]&public_iface=${node1_public_network}
    log    Check Gateway enabled status on node @{PUBLICIP}[0]
    Wait Until Keyword Succeeds    4 min    5 sec    Get GW or RRS Status    @{STORAGEIP}[0]    2    gw
    ...    True
    log    Start to enable GW on node @{PUBLICIP}[1]
    Return Code Should Be    /cgi-bin/ezs3/json/gateway_role_enable?ip=@{STORAGEIP}[1]&public_iface=${node2_public_network}
    log    Check Gateway enabled status on node @{PUBLICIP}[1]
    Wait Until Keyword Succeeds    4 min    5 sec    Get GW or RRS Status    @{STORAGEIP}[1]    2    gw
    ...    True
    log    Start to enable GW on node @{PUBLICIP}[2]
    Return Code Should Be    /cgi-bin/ezs3/json/gateway_role_enable?ip=@{STORAGEIP}[2]&public_iface=${node3_public_network}
    log    Check Gateway enabled status on node @{PUBLICIP}[2]
    Wait Until Keyword Succeeds    6 min    5 sec    Get GW or RRS Status    @{STORAGEIP}[2]    2    gw
    ...    True
    log    End to enable Gateway on each node successfully
    Wait Until Keyword Succeeds    4 min    5 sec    Get ctdb Status
