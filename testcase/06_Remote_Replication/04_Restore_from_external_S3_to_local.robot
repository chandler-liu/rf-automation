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
Restore to local S3
    [Documentation]    estLink ID: Sc-689:Restore to local S3
    [Tags]    RAT
    [Setup]    Switch Connection    @{PUBLICIP}[0]
    log    Create S3 account, create bucket and input some data to bucket
    @{key_list}=    Create Bucket and Input Data
    ${bucket_name_url}=    Set Variable    @{key_list}[0]
    ${bucket_name}=    Evaluate    '${bucket_name_url}'.replace("s3://","")
    ${akey}=    Set Variable    @{key_list}[1]
    ${skey}=    Set Variable    @{key_list}[2]
    ${user_name}=    Set Variable    @{key_list}[3]
    log    Create another S3 account, only create a bucket
    Execute Command Successfully    cp /root/.s3cfg /root/.s3cfg_first
    @{key_list_other}=    Create Bucket and Input Data    dst_rrs_account    s3://dst_rrs_bucket_auto    False
    ${bucket_name_url_other}=    Set Variable    @{key_list_other}[0]
    ${bucket_name_other}=    Evaluate    '${bucket_name_url_other}'.replace("s3://","")
    ${user_name_other}=    Set Variable    @{key_list_other}[3]
    log    Start to create a Restore Task, from remote S3 to local S3
    ${task_id}=    Create RestorationTask    remotes3-locals3-automation    s3tos3    ${vs_name}    ${akey}    ${skey}
    ...    @{PUBLICIP}[-1]    src=${bucket_name}    dst=${bucket_name_other}    bucket_owner=${user_name_other}
    Get Replication Task Status    ${task_id}
    [Teardown]    Run Keywords    Delete User and Clean s3cfg    ${user_name_other}    ${bucket_name_url_other}    /var/log/ceph/ceph.log
    ...    AND    Execute Command Successfully    cp /root/.s3cfg_first /root/.s3cfg
    ...    AND    Delete User and Clean s3cfg    ${user_name}    ${bucket_name_url}    /var/log/ceph/ceph.log
    ...    AND    Delete Replication Task    ${task_id}

Restore to local shared folder
    [Documentation]    estLink ID: Sc-690:Restore to local shared folder
    [Tags]    RAT
    [Setup]    Run Keywords    Switch Connection    @{PUBLICIP}[0]
    ...    AND    Add Shared Folder    name=${folder_name}    gateway_group=${vs_name}    pool=${default_pool}    nfs=true
    ...    AND    Wait Until Keyword Succeeds    1m    5s    Check If SSH Output Is Empty    exportfs -v|grep ${folder_name}
    ...    ${false}
    log    Create S3 account, create bucket and input some data to bucket
    @{key_list}=    Create Bucket and Input Data
    ${bucket_name_url}=    Set Variable    @{key_list}[0]
    ${bucket_name}=    Evaluate    '${bucket_name_url}'.replace("s3://","")
    ${akey}=    Set Variable    @{key_list}[1]
    ${skey}=    Set Variable    @{key_list}[2]
    ${user_name}=    Set Variable    @{key_list}[3]
    log    Start to create a Restore Task, from remote S3 to local share folder
    ${task_id}=    Create RestorationTask    remotes3-localfs-automation    s3tofs    ${vs_name}    ${akey}    ${skey}
    ...    @{PUBLICIP}[-1]    src=${bucket_name}
    Get Replication Task Status    ${task_id}
    [Teardown]    Run Keywords    Delete Shared Folder    ${vs_name}    ${folder_name}
    ...    AND    Delete User and Clean s3cfg    ${user_name}    ${bucket_name_url}    /var/log/ceph/ceph.log
    ...    AND    Delete Replication Task    ${task_id}

Scheduled task
    [Documentation]    TestLink ID: Sc-696:Scheduled task
    [Tags]    FAST
    [Setup]    Switch Connection    @{PUBLICIP}[0]
    log    Create S3 account, create bucket and input some data to bucket
    @{key_list}=    Create Bucket and Input Data
    ${bucket_name_url}=    Set Variable    @{key_list}[0]
    ${bucket_name}=    Evaluate    '${bucket_name_url}'.replace("s3://","")
    ${akey}=    Set Variable    @{key_list}[1]
    ${skey}=    Set Variable    @{key_list}[2]
    ${user_name}=    Set Variable    @{key_list}[3]
    log    Create another S3 account, only create a bucket
    Execute Command Successfully    cp /root/.s3cfg /root/.s3cfg_first
    @{key_list_other}=    Create Bucket and Input Data    dst_rrs_account    s3://dst_rrs_bucket_auto    False
    ${bucket_name_url_other}=    Set Variable    @{key_list_other}[0]
    ${bucket_name_other}=    Evaluate    '${bucket_name_url_other}'.replace("s3://","")
    ${user_name_other}=    Set Variable    @{key_list_other}[3]
    log    Start to create a schedule Restore Task, from remote S3 to local S3
    ${schedule}=    Set Variable    *%2F1+*+*+*+*
    ${task_id}=    Create RestorationTask    remotes3-locals3-automation    s3tos3    ${vs_name}    ${akey}    ${skey}
    ...    @{PUBLICIP}[-1]    src=${bucket_name}    dst=${bucket_name_other}    bucket_owner=${user_name_other}    schedule=${schedule}
    Get Replication Task Status    ${task_id}
    Check Schedule Task    ${task_id}
    [Teardown]    Run Keywords    Delete User and Clean s3cfg    ${user_name_other}    ${bucket_name_url_other}    /var/log/ceph/ceph.log
    ...    AND    Execute Command Successfully    cp /root/.s3cfg_first /root/.s3cfg
    ...    AND    Delete User and Clean s3cfg    ${user_name}    ${bucket_name_url}    /var/log/ceph/ceph.log
    ...    AND    Delete Replication Task    ${task_id}
