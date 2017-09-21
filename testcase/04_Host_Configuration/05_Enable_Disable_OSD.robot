*** Settings ***
Documentation     This suite includes cases related to general cases about enable and disable OSD
Suite Setup       Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
Resource          ../00_commonconfig.txt
Resource          ../00_commonkeyword.txt
Resource          00_hostconfigurationkeywords.txt

*** Variables ***
${osd_name}       enable_disable_osd

*** Test Cases ***
Enable/Disable OSD
    [Documentation]    Testlink ID: Sc-95:Enable/Disable OSD
    [Tags]    RAT
    log    Create OSD, Single partition
    @{data_devs}=    Create List    sdc
    Add Storage Volume    @{STORAGEIP}[0]    ${osd_name}    0    data    \    %5B%5D
    ...    False    False    False    @{data_devs}
    log    Enable OSD
    log    First, get network info
    ${public_network}=    Do SSH CMD    @{PUBLICIP}[0]    ${USERNAME}    ${PASSWORD}    ifconfig | grep -i -B 1 @{PUBLICIP}[0] | grep -v 'inet' | awk -F " " '{print $1}' | sed s'/ //'g
    ${storage_network}=    Do SSH CMD    @{PUBLICIP}[0]    ${USERNAME}    ${PASSWORD}    ifconfig | grep -i -B 1 @{STORAGEIP}[0] | grep -v 'inet' | awk -F " " '{print $1}' | sed s'/ //'g
    log    Public network is: ${public_network}, Storage network is: ${storage_network}
    log    ---------- 1 enable osd -----------
    Enable OSD    @{STORAGEIP}[0]    ${osd_name}    ${storage_network}    ${public_network}
    log    Get cluster status
    Wait Until Keyword Succeeds    4 min    5 sec    Get Cluster Health Status
    sleep    5
    log    ---------- 1 disable osd ------------
    Wait Until Keyword Succeeds    4 min    5 sec    Disable OSD    @{STORAGEIP}[0]    ${osd_name}
    log    Get cluster status
    Wait Until Keyword Succeeds    4 min    5 sec    Get Cluster Health Status
    sleep    5
    log    Enable and disable OSD again
    log    ---------- 2 enbale osd ------------
    Enable OSD    @{STORAGEIP}[0]    ${osd_name}    ${storage_network}    ${public_network}
    log    Get cluster status
    Wait Until Keyword Succeeds    4 min    5 sec    Get Cluster Health Status
    sleep    5
    log    ---------- 2 disbale osd -----------
    Wait Until Keyword Succeeds    4 min    5 sec    Disable OSD    @{STORAGEIP}[0]    ${osd_name}
    log    Get cluster status
    Wait Until Keyword Succeeds    4 min    5 sec    Get Cluster Health Status
    sleep    5
    [Teardown]    Disable and Delete OSD    @{STORAGEIP}[0]    ${osd_name}