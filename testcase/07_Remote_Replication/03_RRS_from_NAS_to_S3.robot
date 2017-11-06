*** Settings ***
Documentation     This suite includes cases related to general cases about RRS from NAS to S3
Suite Setup       Run Keywords    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
...               AND    Open All SSH Connections    ${USERNAME}    ${PASSWORD}    @{PUBLICIP}
Suite Teardown    Run Keywords    Close All Connections
Library           SSHLibrary
Library           HttpLibrary.HTTP
Resource          ../00_commonconfig.txt
Resource          ../00_commonkeyword.txt
Resource          ../06_Virtual_Storage/00_virtual_storage_keyword.txt
Resource          00_remote_replicate_keywords.txt

*** Test Cases ***
No side effect to legacy replications
    [Documentation]    TestLink ID: Sc-678:No side effect to legacy replications
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
    ...    AND    Add Shared Folder    name=${folder_name}    gateway_group=${vs_name}    nfs=true
    ...    AND    Wait Until Keyword Succeeds    1m    5s    Check If SSH Output Is Empty    exportfs -v|grep ${folder_name}
    ...    ${false}
    ...    AND    Add Shared Folder    name=${dest_folder_name}    gateway_group=${dest_vs_name}    nfs=true
    ...    AND    Switch Connection    @{PUBLICIP}[-1]
    ...    AND    Wait Until Keyword Succeeds    2m    5s    Check If SSH Output Is Empty    exportfs -v|grep ${dest_folder_name}
    ...    ${false}
    log    Create three RRS Task,nas-nas; iscsi-iscsi;nas-s3
    log    prepare, to create S3 account, create bucket and input some data to bucket
    @{key_list}=    Create Bucket and Input Data
    ${bucket_name_url}=    Set Variable    @{key_list}[0]
    ${bucket_name}=    Evaluate    '${bucket_name_url}'.replace("s3://","")
    ${akey}=    Set Variable    @{key_list}[1]
    ${skey}=    Set Variable    @{key_list}[2]
    ${user_name}=    Set Variable    @{key_list}[3]
    log    Create iscsi-iscsi/nas-nas/nas-s3 RRS task
    ${iscsi_task_id}=    Create Replication Task    iscsi-iscsi-automation    rbdtorbd    ${dest_vs_name}    ${EMPTY}    ${EMPTY}
    ...    @{PUBLICIP}[-1]
    ${nas_task_id}=    Create Replication Task    nas-nas-automation    fstofs    ${dest_vs_name}    ${EMPTY}    ${EMPTY}
    ...    @{PUBLICIP}[-1]
    ${to_s3_task_id}=    Create Replication Task    nas-s3-automation    fstos3    ${vs_name}    ${akey}    ${skey}
    ...    @{PUBLICIP}[-1]    dst=${bucket_name}
    log    To get three RRS Task running info
    Get Replication Task Status    ${iscsi_task_id}
    Get Replication Task Status    ${nas_task_id}
    Get Replication Task Status    ${to_s3_task_id}
    ${task_id}=    Set Variable    ${iscsi_task_id}%2C${nas_task_id}%2C${to_s3_task_id}
    [Teardown]    Run Keywords    Wait Until Keyword Succeeds    1m    5s    Disable iSCSI LUN    ${dest_vs_name}
    ...    ${dest_iscsi_target_name_urlencoding}    ${dest_iscsi_lun_name}
    ...    AND    Wait Until Keyword Succeeds    1m    5s    Delete iSCSI LUN    ${dest_vs_name}
    ...    ${dest_iscsi_target_name_urlencoding}    ${dest_iscsi_lun_name}
    ...    AND    Wait Until Keyword Succeeds    1m    5s    Delete iSCSI Target    ${dest_vs_name}
    ...    ${dest_iscsi_target_name_urlencoding}
    ...    AND    Wait Until Keyword Succeeds    1m    5s    Disable iSCSI LUN    ${vs_name}
    ...    ${iscsi_target_name_urlencoding}    ${iscsi_lun_name}
    ...    AND    Wait Until Keyword Succeeds    1m    5s    Delete iSCSI LUN    ${vs_name}
    ...    ${iscsi_target_name_urlencoding}    ${iscsi_lun_name}
    ...    AND    Wait Until Keyword Succeeds    1m    5s    Delete iSCSI Target    ${vs_name}
    ...    ${iscsi_target_name_urlencoding}
    ...    AND    Delete Replication Task    ${task_id}
    ...    AND    Wait Until Keyword Succeeds    2m    5s    Delete Shared Folder    ${vs_name}    ${folder_name}
    ...    AND    Wait Until Keyword Succeeds    2m    5s    Delete Shared Folder    ${dest_vs_name}    ${dest_folder_name}
    ...    AND    Wait Until Keyword Succeeds    2m    5s    Remove Virtual Storage    ${dest_vs_name}
    ...    AND    Delete User and Clean s3cfg    ${user_name}    ${bucket_name_url}    /var/log/ceph/ceph.log
