*** Settings ***
Documentation     This suite includes cases related to general cases about system config backup
Suite Setup       Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
Resource          ../00_commonconfig.txt
Resource          ../00_commonkeyword.txt
Resource          00_hostconfigurationkeywords.txt

*** Test Cases ***
Back up configuration
    [Documentation]    TestLink ID: Sc-185:Back up configuration
    [Tags]    RAT
    log    Start to Config backup
    ${request_url}    set variable    /cgi-bin/ezs3/json/backup_node?ip=@{STORAGEIP}[1]
    ${res_info}=    Get Res Body Info    ${request_url}
    sleep    10
    log    Check backup result
    Should Contain    ${res_info}    ceph.conf
    log    Backup config success!
