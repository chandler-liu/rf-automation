*** Settings ***
Documentation     This suite includes cases related to general cases about repair storage volume
Suite Setup       Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
Resource          ../00_commonconfig.txt
Resource          ../00_commonkeyword.txt
Resource          00_hostconfigurationkeywords.txt

*** Test Cases ***
scan/fix storage volumes
    [Documentation]    TestLink ID: Sc-111 scan/fix storage volumes
    [Tags]    TOFT
    log    Select OSD and click "Repair storage volume", select "Scan and fix the storage volumes", check cluster status
    ${osd_name}=    Do SSH CMD    @{PUBLICIP}[1]    ${USERNAME}    ${PASSWORD}    cat /etc/ezs3/storage.conf|python -mjson.tool | grep -i name | head -1 | awk -F ": " '{print $2}' | sed "s/,//" | sed 's/"//g'
    ${repair_osd_body}=    Set Variable    host=@{STORAGEIP}[1]&names=%5B%22${osd_name}%22%5D
    ${repair_osd_url}=    Set Variable    /cgi-bin/ezs3/json/storage_volume_scan
    Post Return Code Should be 0    ${repair_osd_body}    ${repair_osd_url}

reformat storage volumes
    [Documentation]    TestLink ID: Sc-112 reformat storage volumes
    [Tags]    TOFT
    log    Select OSD and click "Repair storage volume", select "Scan and fix the storage volumes", check cluster status
    ${osd_name}=    Do SSH CMD    @{PUBLICIP}[1]    ${USERNAME}    ${PASSWORD}    cat /etc/ezs3/storage.conf|python -mjson.tool | grep -i name | head -1 | awk -F ": " '{print $2}' | sed "s/,//" | sed 's/"//g' | sed 's/ //g'
    ${repair_osd_body}=    Set Variable    host=@{STORAGEIP}[1]&names=%5B%22${osd_name}%22%5D
    ${repair_osd_url}=    Set Variable    /cgi-bin/ezs3/json/storage_volume_reformat
    Post Return Code Should be 0    ${repair_osd_body}    ${repair_osd_url}
    sleep    10
    log    Check OSD state
    Wait Until Keyword Succeeds    4 min    5 sec    Get OSD State    @{STORAGEIP}[1]    ONLINE    ${osd_name}
