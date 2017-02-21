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
UI should refresh the progress
    [Documentation]    TestLink ID: Sc-697:UI should refresh the progress
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
    log    Create automation test file usd dd command in /vol/${folder_name}/
    ${source_file}=    Set Variable    /vol/${folder_name}/rrs_progress_test.dd
    ${dst_file}=    Set Variable    /vol/${dest_folder_name}/rrs_progress_test.dd
    Execute Command Successfully    dd if=/dev/zero of=${source_file} bs=1M count=512
    ${task_id}=    Create Replication Task    nas-nas-progress-automation    fstofs    ${dest_vs_name}    ${EMPTY}    ${EMPTY}
    ...    @{PUBLICIP}[-1]
    Wait Until Keyword Succeeds    4m    5s    Get Replication Task Status For UI    ${task_id}
    Wait Until Keyword Succeeds    30s    5s    MD5 Check    ${source_file}    ${dst_file}
    [Teardown]    Run Keywords    Wait Until Keyword Succeeds    2m    5s    Delete Shared Folder    ${vs_name}    ${folder_name}
    ...    AND    Wait Until Keyword Succeeds    2m    5s    Delete Shared Folder    ${dest_vs_name}    ${dest_folder_name}
    ...    AND    Wait Until Keyword Succeeds    2m    5s    Remove Virtual Storage    ${dest_vs_name}
    ...    AND    Delete Replication Task    ${task_id}
