*** Settings ***
Documentation     This suite includes cases related to general cases about options to join Default or Metedata pool
Suite Setup       Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
Resource          ../00_commonconfig.txt
Resource          ../00_commonkeyword.txt
Resource          00_hostconfigurationkeywords.txt

*** Test Cases ***
The pool information in a drop-down box
    [Documentation]    Testlink ID: Sc-98:The pool information in a drop-down box
    [Tags]    FAST
    log    Create a common pool
    ${pool_name}=    Evaluate    ''.join([random.choice(string.ascii_lowercase) for i in xrange(6)])    string, random
    ${pool_type}=    Set Variable    1
    Return Code Should be    /cgi-bin/ezs3/json/pool_create?pool_name=${pool_name}&pool_type=${pool_type}&settings=%7B%22r%22%3A%222%22%7D    0
    log    Check to create pool success or failed
    ${get_pool_name}=    Do SSH CMD    @{PUBLICIP}[0]    ${USERNAME}    ${PASSWORD}    ceph osd lspools | awk -F " " '{print $NF}' | sed 's/,//g'
    Should Be Equal As Strings    ${pool_name}    ${get_pool_name}
    sleep    5
    log    Delete Pool
    Return Code Should Be    /cgi-bin/ezs3/json/pool_delete?pool_name=${pool_name}    0

OSD join newly created pool
    [Documentation]    Testlink ID: Sc-103:OSD join newly created pool
    [Tags]    FAST
    log    Create a common pool
    ${pool_name}=    Evaluate    ''.join([random.choice(string.ascii_lowercase) for i in xrange(6)])    string, random
    ${pool_type}=    Set Variable    1
    Return Code Should be    /cgi-bin/ezs3/json/pool_create?pool_name=${pool_name}&pool_type=${pool_type}&settings=%7B%22r%22%3A%222%22%7D    0
    log    Check to create pool success or failed
    ${get_pool_name}=    Do SSH CMD    @{PUBLICIP}[0]    ${USERNAME}    ${PASSWORD}    ceph osd lspools | awk -F " " '{print $NF}' | sed 's/,//g'
    Should Be Equal As Strings    ${pool_name}    ${get_pool_name}
    log    Join OSD in newly created pool
    Return Code Should Be    /cgi-bin/ezs3/json/pool_add_node?pool_id=${pool_name}&node_ids=0+1+2    0
    Wait Until Keyword Succeeds    3 min    5 sec    Do SSH CMD    @{PUBLICIP}[0]    ${USERNAME}    ${PASSWORD}
    ...    ceph osd tree | grep -A 6 "pool ${pool_name}" \ | grep "osd." | wc -l    True    3
    sleep    5
    log    Delete Pool
    Return Code Should Be    /cgi-bin/ezs3/json/pool_delete?pool_name=${pool_name}    0

OSD join metadata pool
    [Documentation]    Testlink ID: Sc-101:OSD join metadata pool
    [Tags]    FAST
    log    Create OSD, Single partition
    ${osd_name}    Evaluate    'a'+''.join([random.choice(string.ascii_lowercase) for i in xrange(6)])    string, random
    @{data_devs}=    Create List    sdc
    Add Storage Volume    @{STORAGEIP}[0]    ${osd_name}    0    data    \    %5B%5D
    ...    False    False    False    @{data_devs}
    log    Enable OSD
    log    First, get network info
    ${public_network}=    Do SSH CMD    @{PUBLICIP}[0]    ${USERNAME}    ${PASSWORD}    ifconfig | grep -i -B 1 @{PUBLICIP}[0] | grep -v 'inet' | awk -F " " '{print $1}' | sed s'/ //'g
    ${storage_network}=    Do SSH CMD    @{PUBLICIP}[0]    ${USERNAME}    ${PASSWORD}    ifconfig | grep -i -B 1 @{STORAGEIP}[0] | grep -v 'inet' | awk -F " " '{print $1}' | sed s'/ //'g
    log    Public network is: ${public_network}, Storage network is: ${storage_network}
    log    Start to enable OSD, join in Metadata pool
    Return Code Should Be    /cgi-bin/ezs3/json/node_role_enable_osd?ip=@{STORAGEIP}[0]&sv_list=${osd_name}&cluster_iface=${storage_network}&public_iface=${public_network}&pool_to_join=none&add_metadata_pool=true    0
    log    Check if OSD is enabled
    Wait Until Keyword Succeeds    4 min    5 sec    Get OSD State    @{STORAGEIP}[0]    ONLINE    ${osd_name}
    sleep    10
    [Teardown]    Disable and Delete OSD    @{STORAGEIP}[0]    ${osd_name}
