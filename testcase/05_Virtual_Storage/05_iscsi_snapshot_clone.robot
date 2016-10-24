*** Settings ***
Documentation     This suite includes cases related to general cases about iSCSI configuration
Suite Setup       Run Keywords    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
...               AND    Open All SSH Connections    ${USERNAME}    ${PASSWORD}    @{PUBLICIP}
...               AND    Open Connection    127.0.0.1    alias=127.0.0.1
...               AND    Login    ${LOCALUSER}    ${LOCALPASS}
...               AND    Switch Connection    @{PUBLICIP}[0]
...               AND    Add iSCSI Target    gateway_group=${vs_name}    target_id=${iscsi_target_name_urlencoding}    pool_id=${default_pool}
...               AND    Add iSCSI Volume    gateway_group=${vs_name}    pool_id=${default_pool}    target_id=${iscsi_target_name_urlencoding}    iscsi_id=${iscsi_lun_name}    size=${iscsi_lun_size}
...               AND    Wait Until Keyword Succeeds    30s    5s    SSH Output Should Match    scstadmin --list_device | grep vdisk_blockio | awk '{print \$2}'    tgt*
Suite Teardown    Run Keywords    Disable iSCSI LUN    ${vs_name}    ${iscsi_target_name_urlencoding}    ${iscsi_lun_name}
...               AND    Wait Until Keyword Succeeds    30s    5s    Check If SSH Output Is Empty    rbd showmapped    ${true}
...               AND    Delete iSCSI LUN    ${vs_name}    ${iscsi_target_name_urlencoding}    ${iscsi_lun_name}
...               AND    Wait Until Keyword Succeeds    30s    5s    Check If SSH Output Is Empty    rbd ls    ${true}
...               AND    Delete iSCSI Target    ${vs_name}    ${iscsi_target_name_urlencoding}
...               AND    Wait Until Keyword Succeeds    30s    5s    SSH Output Should Not Contain    cat /etc/scst.conf    DEVICE
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
${iscsi_lun_size}    1073741824    # 1G
${snapshot_name}    snap1

*** Test Cases ***
iSCSI target is normal after taking snapshot
    [Documentation]    Testlink ID:
    ...    Sc-565:iSCSI target is normal after taking snapshot
    [Tags]    FAST    
    Switch Connection    127.0.0.1
    SSH Output Should Match    sudo iscsiadm -m discovery -t st -p @{PUBLICIP}[0]    *${iscsi_target_name}
    Execute Command Successfully    sudo iscsiadm -m node -T ${iscsi_target_name} -l
    ${sdx} =    Execute Command    sudo iscsiadm -m session -P 3|grep -A 47 ${iscsi_target_name}|tail -n 1|awk '{print $4}'
    Should Match    ${sdx}    sd*
    Write    mkfs.ext4 /dev/${sdx}
    ${output}=    Read    delay=20s
    Should Contain    ${output}    Writing superblocks and filesystem accounting information:
    Execute Command Successfully    mkdir -p /mnt/iscsi; mount /dev/${sdx} /mnt/iscsi; echo "Before take snapshot" > /mnt/iscsi/mark.txt
    # Take iSCSI snapshot...
    Take iSCSI Snapshot    ${vs_name}    ${iscsi_lun_name}    ${iscsi_target_name_urlencoding}    ${snapshot_name}
    Execute Command Successfully    umount /mnt/iscsi; sudo iscsiadm -m node -T ${iscsi_target_name} -u; sudo iscsiadm -m node -T ${iscsi_target_name} -l
    ${sdx} =    Execute Command    sudo iscsiadm -m session -P 3|grep -A 47 ${iscsi_target_name}|tail -n 1|awk '{print $4}'
    Execute Command Successfully    mount /dev/${sdx} /mnt/iscsi
    SSH Output Should Be Equal    cat /mnt/iscsi/mark.txt    Before take snapshot
    [Teardown]
    Execute Command Successfully    umount /mnt/iscsi
    Execute Command Successfully    sudo iscsiadm -m node -u
    Execute Command Successfully    sudo iscsiadm -m node -o delete

*** Keywords ***
Take iSCSI Snapshot
    [Arguments]    ${gateway_group}    ${lun_name}    ${target_id}    ${snap_name}
    Return Code Should be 0    /cgi-bin/ezs3/json/iscsi_create_snap?gateway_group=${gateway_group}&iscsi_id=${lun_name}&target_id=${target_id}&snap_name=${snap_name}
