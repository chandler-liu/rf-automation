*** Settings ***
Suite Setup       Run Keywords    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
...               AND    Open All SSH Connections    ${USERNAME}    ${PASSWORD}    @{PUBLICIP}
...               AND    Switch Connection    @{PUBLICIP}[1]
Suite Teardown    Run Keywords    Switch Connection    @{PUBLICIP}[1]
...               AND    Close All Connections    # Close SSH connections
Resource          ../00_commonconfig.txt
Resource          ../keyword/keyword_verify.txt
Resource          ../keyword/keyword_system.txt
Resource          ../keyword/keyword_cgi.txt

*** Variables ***
${cache_disk}    sdd
${new_pool}    pool4
${new_metapool}    metapool4
@{node_ids}    0    1    2
${fs_name}    cephfs4
${vs_name}    Default
${folder_name}    folder4
${target_id}    iqn.2016-09.rf:autotest
${iscsi_id}    autltest_lv

*** Test Cases ***
Enable/Disable FS cache
    [Documentation]    TestLink ID: Sc-125 Enable/Disable FS cache
    [Tags]    FAST
	Create New Cephfs With Fscache
	Enable The Cephfs
	Add A New Shared Folder Base On The Cephfs
	Check enable FS cache result
	[Teardown]    Clean The Cephfs
	
Add SAN Volume Cache when volume is enabled
    [Documentation]    TestLink ID: Sc-127:Add SAN Volume Cache when volume is enabled
    [Tags]    FAST
	Start to create iSCSI target
	Create iSCSI volume
	Add SAN Cache For Host
	[Teardown]    Clean The Cache&SAN
	
*** Keywords ***
Create New Cephfs With Fscache
    Run Keyword    Create Pool    ${new_pool}    1
	Wait Until Keyword Succeeds    4 min    5 sec    Check Pool Exist UI    ${new_pool}
	Run Keyword    Create Pool    ${new_metapool}    1
	Wait Until Keyword Succeeds    4 min    5 sec    Check Pool Exist UI    ${new_metapool}
	Run Keyword    Add Node To Pool    ${new_pool}    @{node_ids}
	Wait Until Keyword Succeeds    4 min    5 sec    Check Pool UI Contain Node    ${new_pool}    @{node_ids}
	Run Keyword    Add Node To Pool    ${new_metapool}    @{node_ids}
	Wait Until Keyword Succeeds    4 min    5 sec    Check Pool UI Contain Node    ${new_metapool}    @{node_ids}
	Run Keyword    Create Cephfs    ${vs_name}    ${fs_name}    ${new_pool}    ${new_metapool}    enable_fscache=true    selected_cache_disk=${cache_disk}    cache_use_whole_disk=true    cache_size=40

Enable The Cephfs
	Run Keyword    Enable Cephfs    ${vs_name}    ${fs_name}

Add A New Shared Folder Base On The Cephfs
	Run Keyword    Add Shared Folder    name=${folder_name}    gateway_group=${vs_name}    pool=${new_pool}    nfs=true    cephfs=${fs_name}
	Wait Until Keyword Succeeds    6 min    5 sec    Check If SSH Output Is Empty    exportfs -v    ${false}

Check enable FS cache result
	Wait Until Keyword Succeeds    4 min    5 sec    SSH Output Should Contain    lsblk | grep /var/cache/fscache    /var/cache/fscache
	
Clean The Cephfs
    Run Keywords    Delete Shared Folder    ${vs_name}    ${folder_name}
	...    AND    Wait Until Keyword Succeeds    6 min    5s    Check If SSH Output Is Empty    exportfs -v    ${true}
	...    AND    Disable Cephfs    ${vs_name}    ${fs_name}
	...    AND    Delete Cephfs    ${vs_name}    ${fs_name}
	...    AND    Delete Pool    ${new_pool}
	...    AND    Wait Until Keyword Succeeds    4 min    5 sec    Check Pool Nonexist UI    ${new_pool}
	...    AND    Delete Pool    ${new_metapool}
    ...    AND    Wait Until Keyword Succeeds    4 min    5 sec    Check Pool Nonexist UI    ${new_metapool}
	
Start to create iSCSI target
    Run Keyword    Create Target    ${vs_name}    ${target_id}
	
Create iSCSI volume
    Run Keyword    Add Iscsi Volume    gateway_group=${vs_name}    iscsi_id=${iscsi_id}    size=1073741824    pool=Default    target_id=${target_id}
	Wait Until Keyword Succeeds    60s    5s    Check If SSH Output Is Empty    rbd showmapped    ${false}
	
Add SAN Cache For Host
    ${rbd_image_name}=    Get RBD Image Name    ${vs_name}    ${target_id}    ${iscsi_id}
    Run Keyword    Add SAN Cache    @{STORAGEIP}[1]    ${rbd_image_name}    ${cache_disk}
	
Clean The Cache&SAN
    Run Keyword    Disable SAN Cache    @{STORAGEIP}[1]    ${cache_disk}
    Run Keyword    Disable Iscsi Volume    ${vs_name}    ${target_id}    ${iscsi_id}
	Run Keyword    Remove Iscsi Volume    ${vs_name}    ${target_id}    ${iscsi_id}
	Run Keyword    Remove Target    ${vs_name}    ${target_id}
	