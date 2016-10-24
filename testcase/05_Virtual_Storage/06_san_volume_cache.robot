*** Settings ***
Suite Setup       Run Keywords    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
...               AND    Open All SSH Connections    ${USERNAME}    ${PASSWORD}    @{PUBLICIP}
...               AND    Switch Connection    @{PUBLICIP}[0]
...               AND    Add iSCSI Target    gateway_group=${vs_name}    target_id=${iscsi_target_name_urlencoding}    pool_id=${default_pool}
...               AND    Add iSCSI Volume    gateway_group=${vs_name}    pool_id=${default_pool}    target_id=${iscsi_target_name_urlencoding}    iscsi_id=${iscsi_lun_name}    size=${iscsi_lun_size}
...               AND    Wait Until Keyword Succeeds    30s    5s    SSH Output Should Match    scstadmin --list_device | grep vdisk_blockio | awk '{print \$2}'    tgt*
Suite Teardown    Run Keywords    Disable iSCSI LUN    ${vs_name}    ${iscsi_target_name_urlencoding}    ${iscsi_lun_name}
...               AND    Wait Until Keyword Succeeds    30s    5s    Check If SSH Output Is Empty    rbd showmapped    ${true}
...               AND    Delete iSCSI LUN    ${vs_name}    ${iscsi_target_name_urlencoding}    ${iscsi_lun_name}
...               AND    Wait Until Keyword Succeeds    30s    5s    Check If SSH Output Is Empty    rbd ls    ${true}
...               AND    Delete iSCSI Target    ${vs_name}    ${iscsi_target_name_urlencoding}
...               AND    Wait Until Keyword Succeeds    30s    5s    SSH Output Should Not Contain    cat /etc/scst.conf    DEVICE
Resource          ../00_commonconfig.txt
Resource          ../00_commonkeyword.txt
Resource          00_virtual_storage_keyword.txt

*** Variables ***
${vs_name}        Default
${default_pool}    Default
${iscsi_target_name}    iqn.2016-01.bigtera.com:auto
${iscsi_target_name_urlencoding}    iqn.2016-01.bigtera.com%3Aauto
${iscsi_lun_name}    lun1
${iscsi_lun_size}    5368709120    # 5G

*** Test Cases ***
Enable/Disable FS cache
    [Documentation]    Testlink ID: Sc-125:Enable/Disable FS cache
    [Tags]    FAST
    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
    log    Start to enable FS cache
    ${cache_partions}    Set Variable    sdd
    Return Code Should be    /cgi-bin/ezs3/json/fs_cache_enable?host=@{STORAGEIP}[0]&cache_partition=%2Fdev%2F${cache_partions}&is_partition=false&use_whole_disk=true&cache_size=NaN    0
    log    Check if FS cache is enabled
    ${fs_cache_status}=    Get Return Json    /cgi-bin/ezs3/json/fs_cache_status?host=@{STORAGEIP}[0]    /response/is_enabled
    Should Be Equal As Strings    ${fs_cache_status}    true
    log    Start to disable FS Cache
    Return Code Should be    /cgi-bin/ezs3/json/fs_cache_disable?host=@{STORAGEIP}[0]    0
    log    Check if FS cache is disabled
    ${fs_disable_cache_status}=    Get Return Json    /cgi-bin/ezs3/json/fs_cache_status?host=@{STORAGEIP}[0]    /response/is_enabled
    Should Be Equal As Strings    ${fs_disable_cache_status}    false

Add SAN Volume Cache when volume is enabled
    [Documentation]    Testlink ID: Sc-127:Add SAN Volume Cache when volume is enabled
    [Tags]    FAST
    log    Get rbd volume name
    ${rbd_img}=    Do SSH CMD    @{PUBLICIP}[0]    ${USERNAME}    ${PASSWORD}    rbd showmapped | grep img | awk '{print $3}'
    Add SAN Cache    ${rbd_img}    ${default_pool}    sdd


*** Keywords ***
Add SAN cache
    [Arguments]    ${rbd_img}    ${default_pool}    ${cache_device}
    Return Code Should be 0    /cgi-bin/ezs3/json/rbd_volume_cache_create?host=@{STORAGEIP}[0]&rbd_img=${rbd_img}&pool_id=${default_pool}&cache_path=%2Fdev%2F${cache_device}
    log    Check add SAN cache success or not
    ${result}=    Get Return Json    /cgi-bin/ezs3/json/cached_volume_list?host=@{STORAGEIP}[0]    /response
    ${result}=    evaluate    ${result}
    log    Length of the list
    ${list_len}=    Get Length    ${result}
    log    Length of the list is : ${list_len}
    : FOR    ${i}    IN RANGE    ${list_len}
    \    ${res_lists_tmp}=    Get From List    ${result}    ${i}
    \    Run Keyword If    ${result}[${i}]['cache_dev']=='/dev/sdd'    Exit For Loop
    ${res_lists}=    Set Variable    ${res_lists_tmp}
    log    Get result of list: ${res_lists}
    ${cache_dev}=    Get From Dictionary    ${res_lists}    cache_dev
    Should Be Equal As Strings    ${cache_dev}    /dev/sdd
    log    Delete SAN Cache
    Return Code Should be 0    /cgi-bin/ezs3/json/rbd_volume_cache_delete?host=@{STORAGEIP}[0]&cache_names=%5B%22CACHE_${cache_device}%22%5D
