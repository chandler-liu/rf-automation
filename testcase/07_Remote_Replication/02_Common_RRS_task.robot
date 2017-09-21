*** Settings ***
Documentation     This suite includes cases related to general cases about Common RRS Task
Suite Setup       Run Keywords    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
...               AND    Open All SSH Connections    ${USERNAME}    ${PASSWORD}    @{PUBLICIP}
Suite Teardown    Run Keywords    Close All Connections
Library           SSHLibrary
Library           HttpLibrary.HTTP
Resource          ../00_commonconfig.txt
Resource          ../00_commonkeyword.txt
Resource          ../05_Virtual_Storage/00_virtual_storage_keyword.txt
Resource          00_remote_replicate_keywords.txt

*** Test Cases ***
One time replication task for iSCSI/FC volumes
    [Documentation]    TestLinkID Sc-666: One time replication task for iSCSI/FC volumes
    [Tags]    FAST
    [Setup]    Run Keywords    Switch Connection    @{PUBLICIP}[0]
    ...    AND    Add iSCSI Target    gateway_group=${vs_name}    target_id=${iscsi_target_name_urlencoding}
    ...    AND    Add iSCSI Volume    gateway_group=${vs_name}    pool_id=${default_pool}    target_id=${iscsi_target_name_urlencoding}    iscsi_id=${iscsi_lun_name}
    ...    size=${iscsi_lun_size}
    ...    AND    Wait Until Keyword Succeeds    30s    5s    SSH Output Should Match    scstadmin --list_device | grep vdisk_blockio | awk '{print \$2}'
    ...    tgt*
    ...    AND    Add Virtual Storage    ${dest_vs_name}    ${dest_pool}    @{STORAGEIP}[-1]
    ...    AND    Switch Connection    @{PUBLICIP}[-1]
    ...    AND    Add iSCSI Target    gateway_group=${dest_vs_name}    target_id=${dest_iscsi_target_name_urlencoding}
    ...    AND    Add iSCSI Volume    gateway_group=${dest_vs_name}    pool_id=${dest_pool}    target_id=${dest_iscsi_target_name_urlencoding}    iscsi_id=${dest_iscsi_lun_name}
    ...    size=${iscsi_lun_size}
    ...    AND    Wait Until Keyword Succeeds    30s    5s    SSH Output Should Match    scstadmin --list_device | grep vdisk_blockio | awk '{print \$2}'
    ...    tgt*
    ...    AND    Wait Until Keyword Succeeds    1m    5s    Disable iSCSI LUN    ${dest_vs_name}
    ...    ${dest_iscsi_target_name_urlencoding}    ${dest_iscsi_lun_name}
    ...    AND    Switch Connection    @{PUBLICIP}[0]
    log    Second, create a new virtual storege,then create iscsi volume, and disable this volume
    log    Third, create a RRS task, which data obsync is from iscsi to iscsi
    log    Create automation test file in /vol/${folder_name}/
    ${source_file}=    Set Variable    /dev/rbd0
    ${dst_file}=    Set Variable    ${source_file}
    ${task_id}=    Create Replication Task    iscsi-iscsi-automation    rbdtorbd    ${dest_vs_name}    ${EMPTY}    ${EMPTY}
    ...    @{PUBLICIP}[-1]
    Get Replication Task Status    ${task_id}
    Wait Until Keyword Succeeds    30s    5s    MD5 Check    ${source_file}    ${dst_file}
    [Teardown]    Run Keywords    Wait Until Keyword Succeeds    1m    5s    Disable iSCSI LUN    ${dest_vs_name}
    ...    ${dest_iscsi_target_name_urlencoding}    ${dest_iscsi_lun_name}
    ...    AND    Wait Until Keyword Succeeds    1m    5s    Delete iSCSI LUN    ${dest_vs_name}
    ...    ${dest_iscsi_target_name_urlencoding}    ${dest_iscsi_lun_name}
    ...    AND    Wait Until Keyword Succeeds    1m    5s    Delete iSCSI Target    ${dest_vs_name}
    ...    ${dest_iscsi_target_name_urlencoding}
    ...    AND    Wait Until Keyword Succeeds    2m    5s    Remove Virtual Storage    ${dest_vs_name}
    ...    AND    Wait Until Keyword Succeeds    1m    5s    Disable iSCSI LUN    ${vs_name}
    ...    ${iscsi_target_name_urlencoding}    ${iscsi_lun_name}
    ...    AND    Wait Until Keyword Succeeds    1m    5s    Delete iSCSI LUN    ${vs_name}
    ...    ${iscsi_target_name_urlencoding}    ${iscsi_lun_name}
    ...    AND    Wait Until Keyword Succeeds    1m    5s    Delete iSCSI Target    ${vs_name}
    ...    ${iscsi_target_name_urlencoding}
    ...    AND    Delete Replication Task    ${task_id}

One time replication task for shared folders
    [Documentation]    TestLink ID: Sc-667:One time replication task for shared folders
    [Tags]    RAT
    [Setup]    Run Keywords    Add Shared Folder    name=${folder_name}    gateway_group=${vs_name}    pool=${default_pool}    nfs=true
    ...    AND    Switch Connection    @{PUBLICIP}[0]
    ...    AND    Wait Until Keyword Succeeds    1m    5s    Check If SSH Output Is Empty    exportfs -v|grep ${folder_name}
    ...    ${false}
    ...    AND    Add Virtual Storage    ${dest_vs_name}    ${dest_pool}    @{STORAGEIP}[-1]
    ...    AND    Add Shared Folder    name=${dest_folder_name}    gateway_group=${dest_vs_name}    pool=${default_pool}    nfs=true
    ...    AND    Switch Connection    @{PUBLICIP}[-1]
    ...    AND    Wait Until Keyword Succeeds    2m    5s    Check If SSH Output Is Empty    exportfs -v|grep ${dest_folder_name}
    ...    ${false}
    ...    AND    Switch Connection    @{PUBLICIP}[0]
    log    Create automation test file in /vol/${folder_name}/
    ${source_file}=    Set Variable    /vol/${folder_name}/rrs_automation_test.txt
    ${dst_file}=    Set Variable    /vol/${dest_folder_name}/rrs_automation_test.txt
    Execute Command Successfully    echo RRS_automation_test>${source_file}
    ${task_id}=    Create Replication Task    nas-nas-automation    fstofs    ${dest_vs_name}    ${EMPTY}    ${EMPTY}
    ...    @{PUBLICIP}[-1]
    Get Replication Task Status    ${task_id}
    Wait Until Keyword Succeeds    30s    5s    MD5 Check    ${source_file}    ${dst_file}
    [Teardown]    Run Keywords    Wait Until Keyword Succeeds    2m    5s    Delete Shared Folder    ${vs_name}    ${folder_name}
    ...    AND    Wait Until Keyword Succeeds    2m    5s    Delete Shared Folder    ${dest_vs_name}    ${dest_folder_name}
    ...    AND    Wait Until Keyword Succeeds    2m    5s    Remove Virtual Storage    ${dest_vs_name}
    ...    AND    Delete Replication Task    ${task_id}
    ...    AND    Switch Connection    @{PUBLICIP}[0]
    ...    AND    Wait Until Keyword Succeeds    1m    5s    Check If SSH Output Is Empty    exportfs -v|grep ${folder_name}    ${true}

One time replication task for S3 buckets
    [Documentation]    TestLink ID: Sc-668:One time replication task for S3 buckets
    [Tags]    RAT
    [Setup]    Run Keywords    Add Shared Folder    name=${folder_name}    gateway_group=${vs_name}    pool=${default_pool}    nfs=true
    ...    AND    Switch Connection    @{PUBLICIP}[0]
    ...    AND    Wait Until Keyword Succeeds    1m    5s    Check If SSH Output Is Empty    exportfs -v|grep ${folder_name}    ${false}
    log    Create S3 account, create bucket and input some data to bucket
    @{key_list}=    Create Bucket and Input Data
    ${bucket_name_url}=    Set Variable    @{key_list}[0]
    ${bucket_name}=    Evaluate    '${bucket_name_url}'.replace("s3://","")
    ${akey}=    Set Variable    @{key_list}[1]
    ${skey}=    Set Variable    @{key_list}[2]
    ${user_name}=    Set Variable    @{key_list}[3]
    ${task_id}=    Create Replication Task    nas-s3-automation    fstos3    ${vs_name}    ${akey}    ${skey}
    ...    @{PUBLICIP}[-1]    dst=${bucket_name}
    Get Replication Task Status    ${task_id}
    [Teardown]    Run Keywords    Wait Until Keyword Succeeds    2m    5s    Delete Shared Folder    ${vs_name}    ${folder_name}
    ...    AND    Delete User and Clean s3cfg    ${user_name}    ${bucket_name_url}    /var/log/ceph/ceph.log
    ...    AND    Delete Replication Task    ${task_id}

Create a recurrent replication task for iSCSI/FC volumes
    [Documentation]    TestLinkID Sc-669:Create a recurrent replication task for iSCSI/FC volumes
    [Tags]    FAST
    [Setup]    Run Keywords    Switch Connection    @{PUBLICIP}[0]
    ...    AND    Add iSCSI Target    gateway_group=${vs_name}    target_id=${iscsi_target_name_urlencoding}
    ...    AND    Add iSCSI Volume    gateway_group=${vs_name}    pool_id=${default_pool}    target_id=${iscsi_target_name_urlencoding}    iscsi_id=${iscsi_lun_name}
    ...    size=${iscsi_lun_size}
    ...    AND    Wait Until Keyword Succeeds    30s    5s    SSH Output Should Match    scstadmin --list_device | grep vdisk_blockio | awk '{print \$2}'
    ...    tgt*
    ...    AND    Add Virtual Storage    ${dest_vs_name}    ${dest_pool}    @{STORAGEIP}[-1]
    ...    AND    Switch Connection    @{PUBLICIP}[-1]
    ...    AND    Add iSCSI Target    gateway_group=${dest_vs_name}    target_id=${dest_iscsi_target_name_urlencoding}
    ...    AND    Add iSCSI Volume    gateway_group=${dest_vs_name}    pool_id=${dest_pool}    target_id=${dest_iscsi_target_name_urlencoding}    iscsi_id=${dest_iscsi_lun_name}
    ...    size=${iscsi_lun_size}
    ...    AND    Wait Until Keyword Succeeds    30s    5s    SSH Output Should Match    scstadmin --list_device | grep vdisk_blockio | awk '{print \$2}'
    ...    tgt*
    ...    AND    Wait Until Keyword Succeeds    1m    5s    Disable iSCSI LUN    ${dest_vs_name}
    ...    ${dest_iscsi_target_name_urlencoding}    ${dest_iscsi_lun_name}
    log    First, create iscsi in Default virutal storage
    log    Second, create a new virtual storege,then create iscsi volume, and disable this volume
    log    Third, create a schedule RRS task, which data obsync is from iscsi to iscsi
    ${schedule}=    Set Variable    *%2F1+*+*+*+*
    ${task_id}=    Create Replication Task    iscsi-iscsi-schedule-automation    rbdtorbd    ${dest_vs_name}    ${EMPTY}    ${EMPTY}
    ...    @{PUBLICIP}[-1]    schedule=${schedule}
    Get Replication Task Status    ${task_id}
    Check Schedule Task    ${task_id}
    [Teardown]    Run Keywords    Wait Until Keyword Succeeds    1m    5s    Disable iSCSI LUN    ${dest_vs_name}
    ...    ${dest_iscsi_target_name_urlencoding}    ${dest_iscsi_lun_name}
    ...    AND    Wait Until Keyword Succeeds    1m    5s    Delete iSCSI LUN    ${dest_vs_name}
    ...    ${dest_iscsi_target_name_urlencoding}    ${dest_iscsi_lun_name}
    ...    AND    Wait Until Keyword Succeeds    1m    5s    Delete iSCSI Target    ${dest_vs_name}
    ...    ${dest_iscsi_target_name_urlencoding}
    ...    AND    Wait Until Keyword Succeeds    2m    5s    Remove Virtual Storage    ${dest_vs_name}
    ...    AND    Wait Until Keyword Succeeds    1m    5s    Disable iSCSI LUN    ${vs_name}
    ...    ${iscsi_target_name_urlencoding}    ${iscsi_lun_name}
    ...    AND    Wait Until Keyword Succeeds    1m    5s    Delete iSCSI LUN    ${vs_name}
    ...    ${iscsi_target_name_urlencoding}    ${iscsi_lun_name}
    ...    AND    Wait Until Keyword Succeeds    1m    5s    Delete iSCSI Target    ${vs_name}
    ...    ${iscsi_target_name_urlencoding}
    ...    AND    Delete Replication Task    ${task_id}

Create a recurrent replication task for shared folders
    [Documentation]    TestLink ID: Sc-670:Create a recurrent replication task for shared folders
    [Tags]    RAT
    [Setup]    Run Keywords    Add Shared Folder    name=${folder_name}    gateway_group=${vs_name}    pool=${default_pool}    nfs=true
    ...    AND    Switch Connection    @{PUBLICIP}[0]
    ...    AND    Wait Until Keyword Succeeds    1m    5s    Check If SSH Output Is Empty    exportfs -v|grep ${folder_name}
    ...    ${false}
    ...    AND    Add Virtual Storage    ${dest_vs_name}    ${dest_pool}    @{STORAGEIP}[-1]
    ...    AND    Add Shared Folder    name=${dest_folder_name}    gateway_group=${dest_vs_name}    pool=${default_pool}    nfs=true
    ...    AND    Switch Connection    @{PUBLICIP}[-1]
    ...    AND    Wait Until Keyword Succeeds    2m    5s    Check If SSH Output Is Empty    exportfs -v|grep ${dest_folder_name}
    ...    ${false}
    ${schedule}=    Set Variable    *%2F1+*+*+*+*
    ${task_id}=    Create Replication Task    nas-nas-schedule-automation    fstofs    ${dest_vs_name}    ${EMPTY}    ${EMPTY}
    ...    @{PUBLICIP}[-1]    schedule=${schedule}
    Get Replication Task Status    ${task_id}
    Check Schedule Task    ${task_id}
    [Teardown]    Run Keywords    Wait Until Keyword Succeeds    2m    5s    Delete Shared Folder    ${vs_name}    ${folder_name}
    ...    AND    Wait Until Keyword Succeeds    2m    5s    Delete Shared Folder    ${dest_vs_name}    ${dest_folder_name}
    ...    AND    Wait Until Keyword Succeeds    2m    5s    Remove Virtual Storage    ${dest_vs_name}
    ...    AND    Delete Replication Task    ${task_id}
    ...    AND    Switch Connection    @{PUBLICIP}[0]
    ...    AND    Wait Until Keyword Succeeds    1m    5s    Check If SSH Output Is Empty    exportfs -v|grep ${folder_name}    ${true}

Create a recurrent replication task for S3 buckets
    [Documentation]    TestLink ID: Sc-671:Create a recurrent replication task for S3 buckets
    [Tags]    RAT
    [Setup]    Run Keywords    Add Shared Folder    name=${folder_name}    gateway_group=${vs_name}    pool=${default_pool}    nfs=true
    ...    AND    Switch Connection    @{PUBLICIP}[0]
    ...    AND    Wait Until Keyword Succeeds    1m    5s    Check If SSH Output Is Empty    exportfs -v|grep ${folder_name}    ${false}
    log    Create S3 account, create bucket and input some data to bucket
    @{key_list}=    Create Bucket and Input Data
    ${bucket_name_url}=    Set Variable    @{key_list}[0]
    ${bucket_name}=    Evaluate    '${bucket_name_url}'.replace("s3://","")
    ${akey}=    Set Variable    @{key_list}[1]
    ${skey}=    Set Variable    @{key_list}[2]
    ${user_name}=    Set Variable    @{key_list}[3]
    ${schedule}=    Set Variable    *%2F1+*+*+*+*
    ${task_id}=    Create Replication Task    nas-s3-schedule-automation    fstos3    ${vs_name}    ${akey}    ${skey}
    ...    @{PUBLICIP}[-1]    dst=${bucket_name}    schedule=${schedule}
    Get Replication Task Status    ${task_id}
    Check Schedule Task    ${task_id}
    [Teardown]    Run Keywords    Wait Until Keyword Succeeds    2m    5s    Delete Shared Folder    ${vs_name}    ${folder_name}
    ...    AND    Delete User and Clean s3cfg    ${user_name}    ${bucket_name_url}    /var/log/ceph/ceph.log
    ...    AND    Delete Replication Task    ${task_id}
    ...    AND    Switch Connection    @{PUBLICIP}[0]
    ...    AND    Wait Until Keyword Succeeds    1m    5s    Check If SSH Output Is Empty    exportfs -v|grep ${folder_name}    ${true}

Delete selected replication task(s)
    [Documentation]    TestLink ID: Sc-672:Delete selected replication task(s)
    [Tags]    RAT
    [Setup]    Run Keywords    Add Shared Folder    name=${folder_name}    gateway_group=${vs_name}    pool=${default_pool}    nfs=true
    ...    AND    Switch Connection    @{PUBLICIP}[0]
    ...    AND    Wait Until Keyword Succeeds    1m    5s    Check If SSH Output Is Empty    exportfs -v|grep ${folder_name}    ${false}
    ...    AND    Add Virtual Storage    ${dest_vs_name}    ${dest_pool}    @{STORAGEIP}[-1]
    ...    AND    Add Shared Folder    name=${dest_folder_name}    gateway_group=${dest_vs_name}    pool=${default_pool}    nfs=true
    ...    AND    Switch Connection    @{PUBLICIP}[-1]
    ...    AND    Wait Until Keyword Succeeds    2m    5s    Check If SSH Output Is Empty    exportfs -v|grep ${dest_folder_name}
    ...    ${false}
    ${task_id1}=    Create Replication Task    nas-nas-automation    fstofs    ${dest_vs_name}    ${EMPTY}    ${EMPTY}
    ...    @{PUBLICIP}[-1]
    Get Replication Task Status    ${task_id1}
    ${task_id2}=    Create Replication Task    nas-nas-automation    fstofs    ${dest_vs_name}    ${EMPTY}    ${EMPTY}
    ...    @{PUBLICIP}[-1]
    Get Replication Task Status    ${task_id2}
    ${task_id}=    Set Variable    ${task_id1}%2C${task_id2}
    [Teardown]    Run Keywords    Wait Until Keyword Succeeds    2m    5s    Delete Shared Folder    ${vs_name}    ${folder_name}
    ...    AND    Wait Until Keyword Succeeds    2m    5s    Delete Shared Folder    ${dest_vs_name}    ${dest_folder_name}
    ...    AND    Wait Until Keyword Succeeds    2m    5s    Remove Virtual Storage    ${dest_vs_name}
    ...    AND    Delete Replication Task    ${task_id}
    ...    AND    Switch Connection    @{PUBLICIP}[0]
    ...    AND    Wait Until Keyword Succeeds    1m    5s    Check If SSH Output Is Empty    exportfs -v|grep ${folder_name}    ${true}

Edit a selected replication task
    [Documentation]    TestLink ID: Sc-674:Edit a selected replication task
    [Tags]    RAT
    [Setup]    Run Keywords    Add Shared Folder    name=${folder_name}    gateway_group=${vs_name}    pool=${default_pool}    nfs=true
    ...    AND    Switch Connection    @{PUBLICIP}[0]
    ...    AND    Wait Until Keyword Succeeds    1m    5s    Check If SSH Output Is Empty    exportfs -v|grep ${folder_name}    ${false}
    ...    AND    Add Virtual Storage    ${dest_vs_name}    ${dest_pool}    @{STORAGEIP}[-1]
    ...    AND    Add Shared Folder    name=${dest_folder_name}    gateway_group=${dest_vs_name}    pool=${default_pool}    nfs=true
    ...    AND    Switch Connection    @{PUBLICIP}[-1]
    ...    AND    Wait Until Keyword Succeeds    2m    5s    Check If SSH Output Is Empty    exportfs -v|grep ${dest_folder_name}
    ...    ${false}
    ${task_name}=    Set Variable    nas-nas-modify-schedule-automation
    ${schedule}=    Set Variable    *%2F1+*+*+*+*
    ${task_id}=    Create Replication Task    ${task_name}    fstofs    ${dest_vs_name}    ${EMPTY}    ${EMPTY}
    ...    @{PUBLICIP}[-1]    schedule=${schedule}
    Get Replication Task Status    ${task_id}
    Check Schedule Task    ${task_id}
    log    Edit this replication task, set schedule from 1Miniute to 2Miniutes
    ${new_schedule}=    Set Variable    *%2F2+*+*+*+*
    Create Replication Task    ${task_name}    fstofs    ${dest_vs_name}    ${EMPTY}    ${EMPTY}    @{PUBLICIP}[-1]
    ...    schedule=${new_schedule}
    Get Replication Task Status    ${task_id}
    Check Schedule Task    ${task_id}    3
    [Teardown]    Run Keywords    Wait Until Keyword Succeeds    2m    5s    Delete Shared Folder    ${vs_name}    ${folder_name}
    ...    AND    Wait Until Keyword Succeeds    2m    5s    Delete Shared Folder    ${dest_vs_name}    ${dest_folder_name}
    ...    AND    Wait Until Keyword Succeeds    2m    5s    Remove Virtual Storage    ${dest_vs_name}
    ...    AND    Delete Replication Task    ${task_id}
