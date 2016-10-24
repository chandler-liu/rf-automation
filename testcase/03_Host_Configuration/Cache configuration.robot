*** Settings ***
Suite Setup       Run Keywords    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
...               AND    Open All SSH Connections    ${USERNAME}    ${PASSWORD}    @{PUBLICIP}
...               AND    Switch Connection    @{PUBLICIP}[1]
Suite Teardown    Run Keywords    Switch Connection    @{PUBLICIP}[1]
...               AND    Close All Connections    # Close SSH connections
Resource          ../00_commonconfig.txt
Resource          ../00_commonkeyword.txt
Resource          00_hostconfigurationkeywords.txt

*** Test Cases ***
Enable/Disable FS cache
    [Documentation]    TestLink ID: Sc-125 Enable/Disable FS cache
    [Tags]    FAST
    log    Start to enable FS cache
    ${cache_disk}=    Set Variable    sdd
    Return Code Should be 0    /cgi-bin/ezs3/json/fs_cache_enable?host=@{STORAGEIP}[1]&cache_partition=%2Fdev%2F${cache_disk}&is_partition=false&use_whole_disk=true&cache_size=NaN
    log    Check enable FS cache result
    Wait Until Keyword Succeeds    4 min    5 sec    SSH Output Should Contain    lsblk | grep /var/cache/fscache    /var/cache/fscache
    log    Disable FS cache
    Return Code Should be 0    /cgi-bin/ezs3/json/fs_cache_disable?host=@{STORAGEIP}[1]
    log    Check add flashcache result
    Wait Until Keyword Succeeds    4 min    5 sec    SSH Output Should Not Contain    lsblk | grep /var/cache/fscache    /var/cache/fscache

Add SAN Volume Cache when volume is enabled
    [Documentation]    TestLink ID: Sc-127:Add SAN Volume Cache when volume is enabled
    [Tags]    FAST
    log    Start to create iSCSI target
    Return Code Should be 0    /cgi-bin/ezs3/json/iscsi_add_target?gateway_group=Default&target_id=iqn.2016-09.rf%3Aautotest&pool_id=Default
    log    Create iSCSI volume
    Return Code Should Be 0    /cgi-bin/ezs3/json/iscsi_add?allowed_initiators=&gateway_group=Default&iscsi_id=autltest_lv&qos_enabled=false&size=1073741824&snapshot_enabled=false&target_id=iqn.2016-09.rf:autotest
    sleep    10
    log    Get rbd image name
    ${cache_disk}=    Set Variable    sdd
    ${rbd_image_name}=    Do SSH CMD    @{PUBLICIP}[1]    ${USERNAME}    ${PASSWORD}    rbd ls
    log    Add SAN cache
    Return Code Should be 0    /cgi-bin/ezs3/json/rbd_volume_cache_create?host=@{STORAGEIP}[1]&rbd_img=${rbd_image_name}&pool_id=Default&cache_path=%2Fdev%2F${cache_disk}
    log    Check add SAN Cache result
    Wait Until Keyword Succeeds    3 min    5 sec    SSH Output Should Contain    eio_cli info    Source Device
    log    Disale SAN cache
    Return Code Should be 0    /cgi-bin/ezs3/json/rbd_volume_cache_delete?host=@{STORAGEIP}[1]&cache_names=%5B%22CACHE_${cache_disk}%22%5D
    log    Check remove SAN cache result
    Wait Until Keyword Succeeds    3 min    5 sec    SSH Output Should Contain    eio_cli info    No caches Found
    log    Remove iSCSI volume and target
    Return Code Should be 0    /cgi-bin/ezs3/json/iscsi_multi_disable?gateway_group=Default&iscsi_id_list=autltest_lv&target_id=iqn.2016-09.rf%3Aautotest
    Return Code Should be 0    /cgi-bin/ezs3/json/iscsi_multi_remove?gateway_group=Default&iscsi_id_list=autltest_lv&target_id=iqn.2016-09.rf%3Aautotest
    Return Code Should be 0    /cgi-bin/ezs3/json/iscsi_remove_target?gateway_group=Default&target_id=iqn.2016-09.rf%3Aautotest
