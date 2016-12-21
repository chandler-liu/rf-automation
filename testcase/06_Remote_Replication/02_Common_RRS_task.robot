*** Settings ***
Documentation     This suite includes cases related to general cases about Common RRS Task
Suite Setup       Run Keywords    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
...               AND    Open All SSH Connections    ${USERNAME}    ${PASSWORD}    @{PUBLICIP}
...               AND    Login    ${LOCALUSER}    ${LOCALPASS}
...               AND    Switch Connection    @{PUBLICIP}[0]
...               AND    Add iSCSI Target    gateway_group=${vs_name}    target_id=${iscsi_target_name_urlencoding}    pool_id=${default_pool}
...               AND    Add iSCSI Volume    gateway_group=${vs_name}    pool_id=${default_pool}    target_id=${iscsi_target_name_urlencoding}    iscsi_id=${iscsi_lun_name}    size=${iscsi_lun_size}
...               AND    Wait Until Keyword Succeeds    30s    5s    SSH Output Should Match    scstadmin --list_device | grep vdisk_blockio | awk '{print \$2}'    tgt*
...               AND    Add Virtual Storage    ${dest_vs_name}    ${dest_pool}    @{STORAGEIP}[-1]
...               AND    Switch Connection    @{PUBLICIP}[-1]
...               AND    Add iSCSI Target    gateway_group=${dest_vs_name}    target_id=${dest_iscsi_target_name_urlencoding}    pool_id=${dest_pool}
...               AND    Add iSCSI Volume    gateway_group=${dest_vs_name}    pool_id=${dest_pool}    target_id=${dest_iscsi_target_name_urlencoding}    iscsi_id=${dest_iscsi_lun_name}    size=${iscsi_lun_size}
...               AND    Wait Until Keyword Succeeds    30s    5s    SSH Output Should Match    scstadmin --list_device | grep vdisk_blockio | awk '{print \$2}'    tgt*
...               AND    Wait Until Keyword Succeeds    60s    5s    Disable iSCSI LUN    ${dest_vs_name}    ${dest_iscsi_target_name_urlencoding}
...               ${dest_iscsi_lun_name}
Suite Teardown    Run Keywords    Close All Connections
...               AND    Wait Until Keyword Succeeds    60s    5s    Disable iSCSI LUN    ${dest_vs_name}    ${dest_iscsi_target_name_urlencoding}
...               ${dest_iscsi_lun_name}
...               AND    Wait Until Keyword Succeeds    60s    5s    Delete iSCSI LUN    ${dest_vs_name}    ${dest_iscsi_target_name_urlencoding}
...               ${dest_iscsi_lun_name}
...               AND    Wait Until Keyword Succeeds    60s    5s    Delete iSCSI Target    ${dest_vs_name}    ${dest_iscsi_target_name_urlencoding}
...               AND    Wait Until Keyword Succeeds    60s    5s    Remove Virtual Storage    ${dest_vs_name}
...               AND    Wait Until Keyword Succeeds    60s    5s    Disable iSCSI LUN    ${vs_name}    ${iscsi_target_name_urlencoding}
...               ${iscsi_lun_name}
...               AND    Wait Until Keyword Succeeds    60s    5s    Delete iSCSI LUN    ${vs_name}    ${iscsi_target_name_urlencoding}
...               ${iscsi_lun_name}
...               AND    Wait Until Keyword Succeeds    60s    5s    Delete iSCSI Target    ${vs_name}    ${iscsi_target_name_urlencoding}
Library           SSHLibrary
Library           HttpLibrary.HTTP
Resource          ../00_commonconfig.txt
Resource          ../00_commonkeyword.txt
Resource          ../05_Virtual_Storage/00_virtual_storage_keyword.txt
Resource          00_remote_replicate_keywords.txt

*** Test Cases ***
One time replication task for iSCSI/FC volumes
    [Documentation]    TestLinkID Sc-666:One time replication task for iSCSI/FC volumes
    log    First, create target in parepre
    log    Disable target lun
    ${task_id}=    Create Replication Task    iscsi-iscsi-automation    rbdtorbd    ${dest_vs_name}    \    ${EMPTY}
    ...    @{PUBLICIP}[-1]
    log    taks id is ${task_id}
    Get Replication Task Status    ${task_id}
