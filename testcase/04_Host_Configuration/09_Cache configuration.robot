*** Settings ***
Suite Setup       Run Keywords    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
...               AND    Open All SSH Connections    ${USERNAME}    ${PASSWORD}    @{PUBLICIP}
...               AND    Switch Connection    @{PUBLICIP}[1]
Suite Teardown    Run Keywords    Switch Connection    @{PUBLICIP}[1]
...               AND    Close All Connections    # Close SSH connections
Resource          ../00_commonconfig.txt
Resource          ../00_commonkeyword.txt
Resource          00_hostconfigurationkeywords.txt
Resource          ../06_Virtual_Storage/00_virtual_storage_keyword.txt

*** Test Cases ***
Enable/Disable FS cache
    [Documentation]    TestLink ID: Sc-125 Enable/Disable FS cache
    [Tags]    FAST
    log    Start to enable FS cache
    ${cache_disk}=    Set Variable    sdd
    ${new_pool} =    Set Variable    pool4
	${new_metapool} =    Set Variable    metapool4
    ${osd_ids} =    Set Variable    0
	${fs_name} =    Set Variable    cephfs4
	${vs_name} =    Set Variable    Default
	${folder_name} =    Set Variable    folder4
    Add Replicted Pool    pool_name=${new_pool}    rep_num=2    osd_ids=${osd_ids}
	Add Replicted Pool    pool_name=${new_metapool}    rep_num=2    osd_ids=${osd_ids}
	Create Cephfs    ${vs_name}    ${fs_name}    ${new_pool}    ${new_metapool}    enable_fscache=true    selected_cache_disk=${cache_disk}    cache_use_whole_disk=true    cache_size=40
	Wait Until Keyword Succeeds    3 min    5 sec    Get Cephfs    ${vs_name}    ${fs_name}
	Enable Cephfs    ${vs_name}    ${fs_name}
	Wait Until Keyword Succeeds    6 min    5 sec    Get Cephfs Status    ${vs_name}    ${fs_name}
	Add Shared Folder    name=${folder_name}    gateway_group=${vs_name}    pool=${new_pool}    nfs=true    cephfs=${fs_name}
	Wait Until Keyword Succeeds    6 min    5s    Check If SSH Output Is Empty    exportfs -v    ${false}
	log    Check enable FS cache result
    Wait Until Keyword Succeeds    4 min    5 sec    SSH Output Should Contain    lsblk | grep /var/cache/fscache    /var/cache/fscache
    [Teardown]    Run Keywords    Delete Shared Folder    ${vs_name}    ${folder_name}
	...    AND    Disable Cephfs    ${vs_name}    ${fs_name}
	...    AND    Wait Until Keyword Succeeds    6 min    5 sec    Get Cephfs Status    ${vs_name}    ${fs_name}    status=offline
	...    AND    Delete Cephfs    ${vs_name}    ${fs_name}
	...    AND    Wait Until Keyword Succeeds    6 min    5 sec    Get Cephfs Out    ${vs_name}    ${fs_name}
	...    AND    Delete Pool    ${new_pool}
	...    AND    Delete Pool    ${new_metapool}

Add SAN Volume Cache when volume is enabled
    [Documentation]    TestLink ID: Sc-127:Add SAN Volume Cache when volume is enabled
    [Tags]    FAST
    ${cache_disk}=    Set Variable    sdd
    log    Start to create iSCSI target
    Return Code Should be 0    /cgi-bin/ezs3/json/iscsi_add_target?gateway_group=Default&target_id=iqn.2016-09.rf%3Aautotest
    log    Create iSCSI volume
    Return Code Should Be 0    /cgi-bin/ezs3/json/iscsi_add?allow_all=true&allowed_initiators=&gateway_group=Default&iscsi_id=autltest_lv&qos_enabled=false&logical_bs=512&physical_bs=4096&pool=Default&size=1073741824&snapshot_enabled=false&target_id=iqn.2016-09.rf:autotest
    Wait Until Keyword Succeeds    60s    5s    Check If SSH Output Is Empty    rbd showmapped    ${false}
    log    Get rbd image name
    ${rbd_image_name}=    Do SSH CMD    @{PUBLICIP}[1]    ${USERNAME}    ${PASSWORD}    rbd ls
    Wait Until Keyword Succeeds    4 min    5 sec    Add SAN Cache    ${rbd_image_name}    ${cache_disk}
    [Teardown]    Run Keywords    Disable SAN Cache    ${cache_disk}
    ...    AND    Remove iSCSI Volume And Target
