*** Settings ***
Resource          ../00_commonconfig.txt
Resource          ../00_commonkeyword.txt
Resource          00_hostconfigurationkeywords.txt

*** Test Cases ***
Check local disk
    [Documentation]    Testlink ID: Sc-131:Check local disk
    [Tags]    FAST
    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
    log    Go to Hosts > Storage page, check status of local disk
    Return Code Should be 0    /cgi-bin/ezs3/json/host_local_disk_list?host=@{STORAGEIP}[0]
    ${response_tmp}=    Get Return Json    /cgi-bin/ezs3/json/host_local_disk_list?host=@{STORAGEIP}[0]    /response
    ${response}    evaluate    ${response_tmp}
    ${res_lists}=    Get From List    ${response}    0
    ${dev_info}=    get from dictionary    ${res_lists}    name
    log    Check get local disk result
    Should contain    ${dev_info}    sda
    log    Get local disk seccess!

Check "Physical Disks Status" when all disks work well
    [Documentation]    Testlink ID: Sc-132:Check "Physical Disks Status" when all disks work well
    [Tags]    FAST
    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
    log    Go to Hosts > Storage page, check status of local disk
    Return Code Should be 0    /cgi-bin/ezs3/json/host_disk_status_image?host=@{STORAGEIP}[0]
    ${response_tmp}=    Get Return Json    /cgi-bin/ezs3/json/host_disk_status_image?host=@{STORAGEIP}[0]    /response
    log    ${response_tmp}
    ${response}    evaluate    ${response_tmp}
    ${res_lists}=    Get From List    ${response}    0
    log    Get result of list: ${res_lists}
    log    Check the machine is a physical machine or virtual machine
    ${machine_type}=    Do SSH CMD    @{PUBLICIP}[0]    ${USERNAME}    ${PASSWORD}    lspci -b|grep "VMware" | wc -l
    Run Keyword if    ${machine_type}!=0    log    Machine is a VM, not to check
    ...    ELSE    log    Phycical machine
    Run Keyword if    ${machine_type}==0    Should Contain    raw
