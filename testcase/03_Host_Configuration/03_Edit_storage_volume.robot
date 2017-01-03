*** Settings ***
Resource          ../00_commonconfig.txt
Resource          ../00_commonkeyword.txt
Resource          00_hostconfigurationkeywords.txt

*** Variables ***
${osd_name}       osd_add_cache_partion

*** Test Cases ***
Add cache partition
    [Documentation]    Testlink ID: Sc-87:Add cache partition
    [Tags]    RAT
    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
    log    Create OSD, Single partition
    @{data_devs}=    Create List    sdc
    Add Storage Volume    @{STORAGEIP}[0]    ${osd_name}    0    data    \    %5B%5D
    ...    False    False    False    @{data_devs}
    log    Start to add cache partition
    ${cache_devs}=    Set Variable    sdd
    ${request_body}=    Set Variable    host=@{STORAGEIP}[0]&name=${osd_name}&cache_devs=%5B%22%2Fdev%2F${cache_devs}%22%5D&spare_devs=%5B%5D&write_cache=false
    ${modify_cache_partition_url}=    Set Variable    /cgi-bin/ezs3/json/storage_volume_edit
    POST Request    ${request_body}    ${modify_cache_partition_url}
    log    Check if add cache partition success
    Wait Until Keyword Succeeds    4 min    5 sec    Do SSH CMD    @{PUBLICIP}[0]    ${USERNAME}    ${PASSWORD}
    ...    lsblk | grep -i ${osd_name} | wc -l    True    2
    [Teardown]    Delete OSD    @{STORAGEIP}[0]    ${osd_name}
