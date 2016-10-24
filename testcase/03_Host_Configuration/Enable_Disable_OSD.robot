*** Settings ***
Resource          ../00_commonconfig.txt
Resource          ../00_commonkeyword.txt
Resource          00_hostconfigurationkeywords.txt

*** Variables ***
${osd_name}       enable_disable_osd

*** Test Cases ***
Enable/Disable OSD
    [Documentation]    Testlink ID: Sc-95:Enable/Disable OSD
    [Tags]    RAT
    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
    log    Create OSD, Single partition
    @{data_devs}=    Create List    sdc
    Add Storage Volume    @{STORAGEIP}[0]    ${osd_name}    0    data    \    %5B%5D
    ...    False    False    False    @{data_devs}
    log    Enable OSD
    log    First, get network info
    ${public_network}=    Do SSH CMD    @{PUBLICIP}[0]    ${USERNAME}    ${PASSWORD}    ifconfig | grep -i -B 1 @{PUBLICIP}[0] | grep -v 'inet' | awk -F " " '{print $1}' | sed s'/ //'g
    ${storage_network}=    Do SSH CMD    @{PUBLICIP}[0]    ${USERNAME}    ${PASSWORD}    ifconfig | grep -i -B 1 @{STORAGEIP}[0] | grep -v 'inet' | awk -F " " '{print $1}' | sed s'/ //'g
    log    Public network is: ${public_network}, \ Storage network is: ${storage_network}
    log    Start to enable OSD
    Return Code Should Be    /cgi-bin/ezs3/json/node_role_enable_osd?ip=@{STORAGEIP}[0]&sv_list=${osd_name}&cluster_iface=${storage_network}&public_iface=${public_network}    0
    log    Check if OSD is enabled
    Wait Until Keyword Succeeds    4 min    5 sec    Get OSD State    @{STORAGEIP}[0]    ONLINE    ${osd_name}
    sleep    10
    log    Disable OSD
    Return Code Should Be    /cgi-bin/ezs3/json/node_role_disable_osd?ip=@{STORAGEIP}[0]&sv_list=${osd_name}&force=true    0
    Wait Until Keyword Succeeds    4 min    5 sec    Get OSD State    @{STORAGEIP}[0]    OFFLINE    ${osd_name}
    sleep    10
    log    Start to enable OSD again
    Return Code Should Be    /cgi-bin/ezs3/json/node_role_enable_osd?ip=@{STORAGEIP}[0]&sv_list=${osd_name}&cluster_iface=${storage_network}&public_iface=${public_network}    0
    log    Check if OSD is enabled
    Wait Until Keyword Succeeds    4 min    5 sec    Get OSD State    @{STORAGEIP}[0]    ONLINE    ${osd_name}
    sleep    10
    log    Disable OSD again
    Return Code Should Be    /cgi-bin/ezs3/json/node_role_disable_osd?ip=@{STORAGEIP}[0]&sv_list=${osd_name}&force=true    0
    Wait Until Keyword Succeeds    4 min    5 sec    Get OSD State    @{STORAGEIP}[0]    OFFLINE    ${osd_name}
    sleep    10
    log    Delete OSD
    ${del_osd_body}=    Set Variable    host=@{STORAGEIP}[0]&names=%5B%22${osd_name}%22%5D
    ${delete_osd_url}=    Set Variable    /cgi-bin/ezs3/json/storage_volume_remove
    POST Request    ${del_osd_body}    ${delete_osd_url}
    sleep    5
    [Teardown]    Delete OSD    @{STORAGEIP}[0]    ${osd_name}
