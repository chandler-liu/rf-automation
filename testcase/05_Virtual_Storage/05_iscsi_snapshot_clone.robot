*** Settings ***
Documentation     This suite includes cases related to general cases about iSCSI configuration
Suite Setup       Run Keywords    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
...               AND    Open All SSH Connections    ${USERNAME}    ${PASSWORD}    @{PUBLICIP}
...               AND    Open Connection    127.0.0.1    alias=127.0.0.1
...               AND    Login    ${LOCALUSER}    ${LOCALPASS}
...               AND    Switch Connection    @{PUBLICIP}[0]
...               AND    Add iSCSI Target    gateway_group=${vs_name}    target_id=${iscsi_target_name_urlencoding}
...               AND    Add iSCSI Volume    gateway_group=${vs_name}    pool_id=${default_pool}    target_id=${iscsi_target_name_urlencoding}    iscsi_id=${iscsi_lun_name}    size=${iscsi_lun_size}
...               AND    Wait Until Keyword Succeeds    30s    5s    SSH Output Should Match    scstadmin --list_device | grep vdisk_blockio | awk '{print \$2}'    tgt*
Library           OperatingSystem
Library           SSHLibrary
Library           HttpLibrary.HTTP
Resource          ../00_commonconfig.txt
Resource          ../00_commonkeyword.txt
Resource          00_virtual_storage_keyword.txt

*** Variables ***
${vs_name}        Default
${default_pool}    Default
${iscsi_target_name}    iqn.2016-01.bigtera.com:auto
${iscsi_target_name_urlencoding}    iqn.2016-01.bigtera.com%3Aauto
${iscsi_lun_name}    lun1
${child_lun_name}    lun2
${iscsi_lun_size}    1073741824    # 1G
${snapshot_name}    snap1

*** Test Cases ***
iSCSI target is normal after taking snapshot
    [Documentation]    Testlink ID:
    ...    Sc-565:iSCSI target is normal after taking snapshot
    [Tags]    FAST    
    Switch Connection    127.0.0.1
    SSH Output Should Match    iscsiadm -m discovery -t st -p @{PUBLICIP}[0]    *${iscsi_target_name}
    Execute Command Successfully    iscsiadm -m node -T ${iscsi_target_name} -l
    ${sdx} =    Execute Command    iscsiadm -m session -P 3 > /tmp/iscsi_debug;iscsiadm -m session -P 3|grep -A 50 ${iscsi_target_name}|awk '/Attached scsi disk/ {print $4}'
    Should Match    ${sdx}    sd*
    Write    mkfs.ext4 -F /dev/${sdx}; echo FINISH_FORMATTING
    Wait Until Keyword Succeeds    1m    5s    Read Until    FINISH_FORMATTING
    Execute Command Successfully    mkdir -p /mnt/iscsi; mount -t ext4 /dev/${sdx} /mnt/iscsi; echo "Before take snapshot" > /mnt/iscsi/mark.txt
    Execute Command Successfully    umount /mnt/iscsi; iscsiadm -m node -u;
    # Take iSCSI snapshot...
    Take iSCSI Snapshot    ${vs_name}    ${iscsi_lun_name}    ${iscsi_target_name_urlencoding}    ${snapshot_name}
    Execute Command Successfully    iscsiadm -m node -T ${iscsi_target_name} -l
    ${sdx} =    Execute Command    iscsiadm -m session -P 3|grep -A 50 ${iscsi_target_name}|awk '/Attached scsi disk/ {print $4}'
    Execute Command Successfully    mount -t ext4 /dev/${sdx} /mnt/iscsi
    SSH Output Should Be Equal    cat /mnt/iscsi/mark.txt    Before take snapshot

Snapshot can be rollbacked correctly
    [Documentation]    Testlink ID:
    ...    Sc-566:Snapshot can be rollbacked correctly
    [Tags]    FAST
    Switch Connection    127.0.0.1
    Execute Command Successfully    echo "After take snapshot" > /mnt/iscsi/mark.txt
    Execute Command Successfully    umount /mnt/iscsi; iscsiadm -m node -u;
    # Login again to make sure the modification
    Execute Command Successfully    iscsiadm -m node -T ${iscsi_target_name} -l
    ${sdx} =    Execute Command     iscsiadm -m session -P 3|grep -A 50 ${iscsi_target_name}|awk '/Attached scsi disk/ {print $4}'
    Execute Command Successfully    mount -t ext4 /dev/${sdx} /mnt/iscsi
    SSH Output Should Be Equal    cat /mnt/iscsi/mark.txt    After take snapshot
    Execute Command Successfully    umount /mnt/iscsi; iscsiadm -m node -u;
    Disable iSCSI LUN   ${vs_name}    ${iscsi_target_name_urlencoding}    ${iscsi_lun_name}
    # Get snapshot_id, due to rollback uses id, rather than name.
    Switch Connection    @{PUBLICIP}[0]
    ${snapshot_id} =    Execute Command    rbd ls -l|awk -F '@' '/${snapshot_name}/ {print $2}'| awk '{print $1}'
    Rollback iSCSI Snapshot     ${vs_name}    ${iscsi_lun_name}    ${iscsi_target_name_urlencoding}    ${snapshot_id}
    Wait Until Keyword Succeeds    1m    5s    Rollback Is Finished    ${vs_name}    ${iscsi_target_name_urlencoding}
    Enable iSCSI LUN   ${vs_name}    ${iscsi_target_name_urlencoding}    ${iscsi_lun_name}
    Wait Until Keyword Succeeds    30s    5s    SSH Output Should Match    scstadmin --list_device | grep vdisk_blockio | awk '{print \$2}'    tgt*
    Switch Connection    127.0.0.1
    Execute Command Successfully    iscsiadm -m node -T ${iscsi_target_name} -l
    ${sdx} =    Execute Command     iscsiadm -m session -P 3|grep -A 50 ${iscsi_target_name}|awk '/Attached scsi disk/ {print $4}'
    Execute Command Successfully    mount -t ext4 /dev/${sdx} /mnt/iscsi
    SSH Output Should Be Equal    cat /mnt/iscsi/mark.txt    Before take snapshot
    [Teardown]    Execute Command Successfully     umount /mnt/iscsi; iscsiadm -m node -u; iscsiadm -m node -o delete

Delete iscsi snapshot
    [Documentation]    Testlink ID:
    ...     Sc-567:Delete snapshot
    [Tags]    FAST
    Switch Connection    @{PUBLICIP}[0]
    ${snapshot_id} =    Execute Command    rbd ls -l|awk -F '@' '/${snapshot_name}/ {print $2}'| awk '{print $1}'
    Delete iSCSI Snapshot    ${vs_name}    ${iscsi_lun_name}    ${iscsi_target_name_urlencoding}    ${snapshot_id}
    Check If SSH Output Is Empty   rbd ls -l|awk -F '@' '/${snapshot_name}/ {print $2}'| awk '{print $1}'    ${true}

Clone iSCSI volume
    [Documentation]    Testlink ID:
    ...      Sc-584:Clone iSCSI volume
    [Tags]    FAST
    ${child_lun_name} =    Set Variable    lun2
    Take iSCSI Snapshot    ${vs_name}    ${iscsi_lun_name}    ${iscsi_target_name_urlencoding}    ${snapshot_name}
    Switch Connection    @{PUBLICIP}[0]
    ${snapshot_id} =    Execute Command    rbd ls -l|awk -F '@' '/${snapshot_name}/ {print $2}'| awk '{print $1}'
    Clone iSCSI Volume    gateway_group=${vs_name}    pool_id=${default_pool}    target_id=${iscsi_target_name}    iscsi_id=${child_lun_name}    size=${iscsi_lun_size}    parent_snap=${snapshot_id}    parent_target=${iscsi_target_name}    parent_lun=${iscsi_lun_name}
    Wait Until Keyword Succeeds    30s    5s    SSH Output Should Be Equal    scstadmin --list_device | grep tgt | wc -l    2
    Switch Connection    127.0.0.1
    SSH Output Should Match    iscsiadm -m discovery -t st -p @{PUBLICIP}[0]    *${iscsi_target_name}
    Execute Command Successfully    iscsiadm -m node -T ${iscsi_target_name} -l
    ${dev_num} =    Execute Command     iscsiadm -m session -P 3|grep -A 50 ${iscsi_target_name}|awk '/Attached scsi disk/ {print $4}'|wc -l
    Should Be Equal    ${dev_num}    2
    ${dev_1} =    Execute Command     iscsiadm -m session -P 3|grep -A 50 ${iscsi_target_name}|awk '/Attached scsi disk/ {print $4}'|head -n 1
    ${dev_2} =    Execute Command     iscsiadm -m session -P 3|grep -A 50 ${iscsi_target_name}|awk '/Attached scsi disk/ {print $4}'|tail -n 1
    Execute Command Successfully    mkdir -p /mnt/iscsi1;mkdir -p /mnt/iscsi2;mount /dev/${dev_1} /mnt/iscsi1;mount /dev/${dev_2} /mnt/iscsi2;
    SSH Output Should Be Equal    cat /mnt/iscsi1/mark.txt    Before take snapshot
    SSH Output Should Be Equal    cat /mnt/iscsi2/mark.txt    Before take snapshot
    [Teardown]    Execute Command Successfully    umount /mnt/iscsi1;umount /mnt/iscsi2;iscsiadm -m node -u;iscsiadm -m node -o delete

Delete snapshot when it has child volume
    [Documentation]    Testlink ID:
    ...      Sc-588:Delete snapshot when it has child volume
    Switch Connection    @{PUBLICIP}[0]
    Disable iSCSI LUN    ${vs_name}    ${iscsi_target_name_urlencoding}    ${iscsi_lun_name}
    Wait Until Keyword Succeeds    30s    5s    SSH Output Should Be Equal    rbd showmapped|wc -l    2
    # Try to delete parent lun when it has child lun
    Return Code Should be    /cgi-bin/ezs3/json/iscsi_multi_remove?gateway_group=${vs_name}&iscsi_id_list=${iscsi_lun_name}&target_id=${iscsi_target_name}    712
    # Flatten the iscsi lun
    Flatten iSCSI Volume    ${iscsi_target_name}    ${child_lun_name}
    # Delete parent lun
    Wait Until Keyword Succeeds    30s    5s    Delete iSCSI LUN    ${vs_name}    ${iscsi_target_name_urlencoding}    ${iscsi_lun_name}
    Wait Until Keyword Succeeds    2m    5s    SSH Output Should Be Equal    rbd ls|wc -l    1 
    # Enable child lun and check its content
    Check If SSH Output Is Empty    rbd showmapped    ${true}
    Enable iSCSI LUN    ${vs_name}    ${iscsi_target_name_urlencoding}    ${child_lun_name}
    Wait Until Keyword Succeeds    30s    5s    SSH Output Should Match    scstadmin --list_device | grep vdisk_blockio | awk '{print \$2}'    tgt*
    Switch Connection    127.0.0.1
    SSH Output Should Match    iscsiadm -m discovery -t st -p @{PUBLICIP}[0]    *${iscsi_target_name}
    Execute Command Successfully    iscsiadm -m node -T ${iscsi_target_name} -l
    ${sdx} =    Execute Command     iscsiadm -m session -P 3|grep -A 50 ${iscsi_target_name}|awk '/Attached scsi disk/ {print $4}'
    Execute Command Successfully    mount -t ext4 /dev/${sdx} /mnt/iscsi
    SSH Output Should Be Equal    cat /mnt/iscsi/mark.txt    Before take snapshot
    Execute Command Successfully    umount /mnt/iscsi;iscsiadm -m node -u;iscsiadm -m node -o delete
    [Teardown]    Run Keywords    Disable iSCSI LUN    ${vs_name}    ${iscsi_target_name_urlencoding}    ${child_lun_name}
    ...           AND             Wait Until Keyword Succeeds    30s    5s    Check If SSH Output Is Empty    rbd showmapped    ${true}
    ...           AND             Delete iSCSI LUN    ${vs_name}    ${iscsi_target_name_urlencoding}    ${child_lun_name}
    ...           AND             Wait Until Keyword Succeeds    2m    5s    Check If SSH Output Is Empty    rbd ls    ${true}
    ...           AND             Delete iSCSI Target    ${vs_name}    ${iscsi_target_name_urlencoding}
    ...           AND             Wait Until Keyword Succeeds    30s    5s    SSH Output Should Not Contain    cat /etc/scst.conf    DEVICE
    

*** Keywords ***
Take iSCSI Snapshot
    [Arguments]    ${gateway_group}    ${lun_name}    ${target_id}    ${snap_name}
    Return Code Should be 0    /cgi-bin/ezs3/json/iscsi_create_snap?gateway_group=${gateway_group}&iscsi_id=${lun_name}&target_id=${target_id}&snap_name=${snap_name}

Rollback iSCSI Snapshot
    [Arguments]    ${gateway_group}    ${lun_name}    ${target_id}    ${snap_id}
    Return Code Should be 0    /cgi-bin/ezs3/json/iscsi_rollback_snap?gateway_group=${gateway_group}&iscsi_id=${lun_name}&target_id=${target_id}&snap_name=${snap_id}

Rollback Is Finished
    [Arguments]    ${gateway_group}    ${target_id}
    ${lun_state} =    Get Json Path Value    /cgi-bin/ezs3/json/iscsi_list?gateway_group=${gateway_group}&target_id=${target_id}&rw=true    /response/entry
    Should Not Contain    ${lun_state}    action_pending
    Should Not Contain    ${lun_state}    rollbacking

Delete iSCSI Snapshot
    [Arguments]    ${gateway_group}    ${lun_name}    ${target_id}    ${snap_id}
    Return Code Should be 0    /cgi-bin/ezs3/json/iscsi_remove_snap?gateway_group=${gateway_group}&iscsi_id=${lun_name}&target_id=${target_id}&snap_name=${snap_id}

Clone iSCSI Volume
    [Arguments]    ${allow_all}=true    ${gateway_group}=Default    ${pool_id}=Default    ${target_id}=    ${iscsi_id}=    ${size}=    ${allowed_initiators}=
    ...    ${qos_enabled}=false    ${snapshot_enabled}=false    ${parent_snap}=    ${parent_target}=    ${parent_lun}=    ${logical_bs}=512    ${physical_bs}=4096
    Return Code Should be 0    /cgi-bin/ezs3/json/iscsi_add?allow_all=${allow_all}&allowed_initiators=${allowed_initiators}&gateway_group=${gateway_group}&iscsi_id=${iscsi_id}&parent_snapshot=${parent_snap}&parent_target=${parent_target}&parent_volume=${parent_lun}&qos_enabled=${qos_enabled}&size=${size}&snapshot_enabled=${snapshot_enabled}&target_id=${target_id}&logical_bs=${logical_bs}&physical_bs=${physical_bs}&pool=${pool_id}

Flatten iSCSI Volume
    [Arguments]    ${target_id}    ${lun_name}
    Return Code Should be 0    /cgi-bin/ezs3/json/flatten_volumes?gateway_group=Default&volumes=${target_id}%2F${lun_name}
