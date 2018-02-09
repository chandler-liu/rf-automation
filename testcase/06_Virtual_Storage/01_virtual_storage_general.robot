*** Settings ***
Documentation     This suite includes cases related to general cases about virtual storage
Suite Setup       Run Keywords    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
...               AND    Open All SSH Connections    ${USERNAME}    ${PASSWORD}    @{PUBLICIP}
...               AND    Add Virtual Storage    ${vs_name}    ${default_pool}    @{STORAGEIP}[0]
...               AND    Switch Connection    @{PUBLICIP}[0]
...               AND    Wait Until Keyword Succeeds    3 min    5 sec    Ctdb Should Be OK    1
Suite Teardown    Run Keywords    Remove Virtual Storage    ${vs_name}
...               AND    Switch Connection    @{PUBLICIP}[0]
...               AND    Wait Until Keyword Succeeds    3 min    5 sec    Ctdb Should Be OK    3
...               AND    Close All Connections    # Close SSH connections
Library           OperatingSystem
Library           SSHLibrary
Library           HttpLibrary.HTTP
Resource          ../00_commonconfig.txt
Resource          ../00_commonkeyword.txt
Resource          00_virtual_storage_keyword.txt

*** Variables ***
${vs_name}        custom-vs1
${default_pool}    Default

*** Test Cases ***
Create a new virtual storage and a new shared folder on it.
    [Documentation]    Testlink ID:
    ...    Sc-411:Create a new virtual storage and a new shared folder on it.
    [Tags]    FAST
    ${folder_name} =    Set Variable    folder611
    Add Shared Folder    name=${folder_name}    gateway_group=${vs_name}
    [Teardown]    Delete Shared Folder    ${vs_name}    ${folder_name}

Create a new virtual storage and a new iSCSI volume on it.
    [Documentation]    Testlink ID:
    ...    Sc-412:Create a new virtual storage and a new iSCSI volume on it.
    [Tags]    FAST
    ${iscsi_target_name} =    Set Variable    iqn.2016-01.bigtera.com%3Avsauto
    ${iscsi_lun_name} =    Set Variable    lun1
    ${iscsi_lun_size} =    Set Variable    5368709120    # 5G
    Add iSCSI Target    gateway_group=${vs_name}    target_id=${iscsi_target_name}
    Add iSCSI Volume    gateway_group=${vs_name}    pool_id=${default_pool}    target_id=${iscsi_target_name}    iscsi_id=${iscsi_lun_name}    size=${iscsi_lun_size}
    Wait Until Keyword Succeeds    30s    5s    Check If SSH Output Is Empty    rbd showmapped    ${false}
    [Teardown]    Run Keywords    Disable iSCSI LUN    ${vs_name}    ${iscsi_target_name}    ${iscsi_lun_name}
    ...    AND    Delete iSCSI LUN    ${vs_name}    ${iscsi_target_name}    ${iscsi_lun_name}
    ...    AND    Delete iSCSI Target    ${vs_name}    ${iscsi_target_name}

Add gateway for virtual storage
    [Documentation]    Testlink ID:
    ...    Sc-414:Add gateway for virtual storage
    [Tags]    FAST    
    ${folder_name} =    Set Variable    folder613
    Add Shared Folder    name=${folder_name}    gateway_group=${vs_name}
    Switch Connection    @{PUBLICIP}[1]
    Wait Until Keyword Succeeds    30s    5s    Check If SSH Output Is Empty    exportfs -v    ${true}
    Assign Gateway to Virtual Storage    ${vs_name}    @{STORAGEIP}[1]
    Switch Connection    @{PUBLICIP}[0]    # switch to 0, to prevent FA
    Wait Until Keyword Succeeds    3m    5s    Ctdb Should Be OK    2
    Switch Connection    @{PUBLICIP}[1]
    Wait Until Keyword Succeeds    30s    5s    Check If SSH Output Is Empty    exportfs -v    ${false}
    [Teardown]    Delete Shared Folder    ${vs_name}    ${folder_name}

Remove gateway for virtual storage
    [Documentation]    Testlink ID:
    ...    Sc-415:Remove gateway for virtual storage
    ...    Have dependency on the last case
    [Tags]    FAST    
    ${folder_name} =    Set Variable    folder614
    Add Shared Folder    name=${folder_name}    gateway_group=${vs_name}
    Switch Connection    @{PUBLICIP}[1]
    Wait Until Keyword Succeeds    30s    5s    Check If SSH Output Is Empty    exportfs -v    ${false}
    Assign Gateway to Virtual Storage    Default    @{STORAGEIP}[1]
    Switch Connection    @{PUBLICIP}[2]
    Wait Until Keyword Succeeds    3m    5s    Ctdb Should Be OK    2
    Switch Connection    @{PUBLICIP}[1]
    Wait Until Keyword Succeeds    30s    5s    Check If SSH Output Is Empty    exportfs -v    ${true}
    [Teardown]    Delete Shared Folder    ${vs_name}    ${folder_name}

Add pool for virtual storage
    [Documentation]    Testlink ID:
    ...    Sc-416:Add pool for virtual storage
    [Tags]    FAST
    ${new_pool} =    Set Variable    pool1
	${new_metapool} =    Set Variable    metapool1
    ${osd_ids} =    Set Variable    0+1+2
    ${folder_name} =    Set Variable    folder615
	${fs_name} =    Set Variable    cephfs1
    Add Replicted Pool    pool_name=${new_pool}    rep_num=2    osd_ids=${osd_ids}
	Add Replicted Pool    pool_name=${new_metapool}    rep_num=2    osd_ids=${osd_ids}
    Assign Pool to Virtual Storage    vs_name=${vs_name}    pool_name=${new_metapool}%2C${new_pool}%2CDefault
	Create Cephfs    ${vs_name}    ${fs_name}    ${new_pool}    ${new_metapool}
	Wait Until Keyword Succeeds    3 min    5 sec    Get Cephfs    ${vs_name}    ${vs_name}_${fs_name}
	Enable Cephfs    ${vs_name}    ${fs_name}
	Wait Until Keyword Succeeds    6 min    5 sec    Get Cephfs Status    ${vs_name}    ${vs_name}_${fs_name}
    Add Shared Folder    name=${folder_name}    gateway_group=${vs_name}    pool=${new_pool}    nfs=true    cephfs=${fs_name}
    Switch Connection    @{PUBLICIP}[0]
    Wait Until Keyword Succeeds    30s    5s    Check If SSH Output Is Empty    exportfs -v    ${false}
    Write    cd /vol/${folder_name}
    Write    dd if=/dev/zero of=1.tst bs=1K count=1 conv=fsync
    ${output}=    Read    delay=10s
    Should Contain    ${output}    copied
    Wait Until Keyword Succeeds    30s    5s    SSH Output Should Be Equal    ceph df|grep -w ${new_pool}|awk {'print \$3'}    1024
    [Teardown]    Run Keywords    Delete Shared Folder    ${vs_name}    ${folder_name} 
	...    AND    Disable Cephfs    ${vs_name}    ${fs_name}
	...    AND    Wait Until Keyword Succeeds    6 min    5 sec    Get Cephfs Status    ${vs_name}    ${vs_name}_${fs_name}    status=offline
	...    AND    Delete Cephfs    ${vs_name}    ${fs_name}
	...    AND    Wait Until Keyword Succeeds    6 min    5 sec    Get Cephfs Out    ${vs_name}    ${vs_name}_${fs_name}
	...    AND    Delete Pool    ${new_pool}
	...    AND    Delete Pool    ${new_metapool}

Remove pool for virtual storage
    [Documentation]    Testlink ID:
    ...    Sc-417:Remove pool for virtual storage
    [Tags]    FAST
    ${new_pool} =    Set Variable    pool1
    ${osd_ids} =    Set Variable    0+1+2
    Add Replicted Pool    pool_name=${new_pool}    rep_num=2    osd_ids=${osd_ids}
    Assign Pool to Virtual Storage    vs_name=${vs_name}    pool_name=${new_pool}%2CDefault
    ${ret} =    Get Json Path Value    /cgi-bin/ezs3/json/sds_get_pool?gateway_group=${vs_name}    /response/gateway_group
    Should Contain    ${ret}    ${new_pool}
    Wait Until Keyword Succeeds    15s    5s    Delete Pool    ${new_pool}
    ${ret} =    Get Json Path Value    /cgi-bin/ezs3/json/sds_get_pool?gateway_group=${vs_name}&get_support_rbd_info=false   /response/gateway_group
    Should Not Contain    ${ret}    ${new_pool}

Remove virtual storage
    [Documentation]    Testlink ID:
    ...    Sc-418:Remove virtual storage
    [Tags]    FAST
    Log    This case is executed in suit teardown phase
    #Template
    #    [Documentation]    Testlink ID:
    #    ...
    #    [Tags]    FAST
    #
    #    [Teardown]

*** Keywords ***
