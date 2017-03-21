*** Settings ***
Documentation     This suite includes cases related to general cases about iSCSI configuration
Suite Setup       Run Keywords    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
...               AND    Open All SSH Connections    ${USERNAME}    ${PASSWORD}    @{PUBLICIP}
...               AND    Open Connection    127.0.0.1    alias=127.0.0.1
...               AND    Login    ${LOCALUSER}    ${LOCALPASS}
...               AND    Switch Connection    @{PUBLICIP}[0]
...               AND    Add iSCSI Target    gateway_group=${vs_name}    target_id=${source_target_name_urlencoding}    pool_id=${pool_name}
...               AND    Add iSCSI Volume    gateway_group=${vs_name}    pool_id=${pool_name}    target_id=${source_target_name_urlencoding}    iscsi_id=${source_lun_name}    size=${lun_size}
...               AND    Wait Until Keyword Succeeds    30s    5s    SSH Output Should Match    scstadmin --list_device | grep vdisk_blockio | awk '{print \$2}'    tgt*
Suite Teardown    Run Keywords    Disable iSCSI LUN    ${vs_name}    ${source_target_name_urlencoding}    ${source_lun_name}
...               AND    Delete iSCSI LUN    ${vs_name}    ${source_target_name_urlencoding}    ${source_lun_name}
...               AND    Delete iSCSI Target    ${vs_name}    ${source_target_name_urlencoding}
Library           OperatingSystem
Library           SSHLibrary
Library           HttpLibrary.HTTP
Resource          ../00_commonconfig.txt
Resource          ../00_commonkeyword.txt
Resource          00_virtual_storage_keyword.txt

*** Variables ***
${vs_name}        Default
${pool_name}    Default
${source_target_name}    iqn.2016-01.bigtera.com:source
${source_target_name_urlencoding}    iqn.2016-01.bigtera.com%3Asource
${dest_target_name}    iqn.2016-01.bigtera.com:dest
${dest_target_name_urlencoding}    iqn.2016-01.bigtera.com%3Adest
${source_lun_name}    lun-src
${dest_lun_name}    lun-dst
${lun_size}    2147483648   # 2G
${migrate_host_public}    @{PUBLICIP}[2]
${migrate_host_storage}    @{STORAGEIP}[2]
${source_ip}    @{PUBLICIP}[0]

*** Test Cases ***
Import volume from original iSCSI
    [Documentation]    Testlink ID:
    ...    Sc-624:Import volume from original iSCSI
    [Tags]    RAT
    # Prepare data in original lun
    Switch Connection    127.0.0.1
    SSH Output Should Match    iscsiadm -m discovery -t st -p @{PUBLICIP}[0]    *${source_target_name}
    Execute Command Successfully    iscsiadm -m node -T ${source_target_name} -l
    Sleep    5s
    ${sdx} =    Execute Command    iscsiadm -m session -P 3 > /tmp/iscsi_debug;iscsiadm -m session -P 3|grep -A 50 ${source_target_name}|awk '/Attached scsi disk/ {print $4}'
    Should Match    ${sdx}    sd*
    Write    mkfs.ext4 -F /dev/${sdx}; echo FINISH_FORMATTING
    Wait Until Keyword Succeeds    3m    5s    Read Until    FINISH_FORMATTING
    Execute Command Successfully    mkdir -p /mnt/iscsi; mount -t ext4 /dev/${sdx} /mnt/iscsi; echo "Test import volume." > /mnt/iscsi/mark.txt
    Execute Command Successfully    umount /mnt/iscsi; iscsiadm -m node -u;
    # Import new volume
    Add iSCSI Target    gateway_group=${vs_name}    target_id=${dest_target_name_urlencoding}    pool_id=${pool_name}
    Import iSCSI Volume    ${vs_name}    ${migrate_host_storage}    ${source_ip}    ${source_target_name_urlencoding}    
    ...                    ${dest_target_name_urlencoding}    ${dest_lun_name}    ${lun_size}
    Switch Connection    ${migrate_host_public}
    Wait Until Keyword Succeeds    20s    5s    SSH Output Should Match    scstadmin --list_device | grep vdisk_blockio | awk '{print \$2}'    md*

Check data migration status
    [Documentation]    Testlink ID:
    ...    Sc-637:Check data migration status
    [Tags]    FAST
    Start iSCSI Migration    ${vs_name}    ${dest_target_name_urlencoding}    ${dest_lun_name}
    Wait Until Keyword Succeeds    2m    3s    Migration Progress Is Over    ${vs_name}    ${dest_target_name_urlencoding}    ${0}

Data can be migrated successfully and completely
    [Documentation]    Testlink ID:
    ...    Sc-626:Data can be migrated successfully and completely
    [Tags]    FAST
    # Wait until other gateway has this tgt device exported
    Switch Connection    127.0.0.1
    Wait Until Keyword Succeeds    2m    5s    SSH Output Should Contain    iscsiadm -m discovery -t st -p @{PUBLICIP}[0]    ${dest_target_name}
    Execute Command Successfully    iscsiadm -m node -p @{PUBLICIP}[0] -T ${dest_target_name} -l
    Sleep    5s
    ${sdx} =    Execute Command    iscsiadm -m session -P 3|grep -A 50 ${dest_target_name}|awk '/Attached scsi disk/ {print $4}'
    Execute Command Successfully    mount -t ext4 /dev/${sdx} /mnt/iscsi
    SSH Output Should Be Equal    cat /mnt/iscsi/mark.txt    Test import volume.
    [Teardown]    Run Keywords    Execute Command Successfully    umount /mnt/iscsi; iscsiadm -m node -u;
    ...           AND             Disable iSCSI LUN    ${vs_name}    ${dest_target_name_urlencoding}    ${dest_lun_name}
    ...           AND             Delete iSCSI LUN    ${vs_name}    ${dest_target_name_urlencoding}    ${dest_lun_name}
    ...           AND             Delete iSCSI Target    ${vs_name}    ${dest_target_name_urlencoding}
    

*** Keywords ***
Import iSCSI Volume
    [Arguments]  ${vs_name}    ${migrate_host_storage}    ${source_ip}    ${source_target}    ${dest_target_name}
    ...          ${dest_lun_name}    ${lun_size}    ${max_speed}=200000    ${min_speed}=1000
    Return Code Should be 0    /cgi-bin/ezs3/json/host_iscsi_list_target?host=${migrate_host_storage}&ip=${source_ip}&port=3260
    Return Code Should be 0    /cgi-bin/ezs3/json/host_iscsi_login?gateway_group=${vs_name}&host=${migrate_host_storage}&ip=${source_ip}&port=3260&target=${source_target}
    ${dev_path} =    Wait Until Keyword Succeeds    10s    2s    Get Path Of Session    ${migrate_host_storage}
    Return Code Should be 0    /cgi-bin/ezs3/json/iscsi_add_md?gateway_group=${vs_name}&target_id=${dest_target_name}&src_gw=${migrate_host_storage}&src_dev=${dev_path}&dst_dev=${dest_lun_name}&dst_size=${lun_size}&max_resync_speed=${max_speed}&min_resync_speed=${min_speed}

Get Path Of Session
    [Arguments]    ${migrate_host_storage}
    ${raw_path} =    Get Json Path Value    /cgi-bin/ezs3/json/host_iscsi_disk_list?host=${migrate_host_storage}    /response/0/path
    Should Contain    ${raw_path}    /dev/sd
    ${path} =    Evaluate    '${raw_path}'.replace('"','').replace('/','%2F')   # replace " and /
    [Return]    ${path}

Start iSCSI Migration
    [Arguments]    ${vs_name}    ${dest_target_name_urlencoding}    ${dest_lun_name}
    Return Code Should be 0    /cgi-bin/ezs3/json/iscsi_sync_md?gateway_group=${vs_name}&target_id=${dest_target_name_urlencoding}&dst_dev=${dest_lun_name}

Migration Progress Is Over
    [Arguments]    ${vs_name}    ${dest_target_name_urlencoding}    ${threshold}
    ${raw_pro} =    Get Json Path Value    /cgi-bin/ezs3/json/iscsi_list?gateway_group=${vs_name}&target_id=${dest_target_name_urlencoding}&rw=true    /response/entry/0/md_stats/recovery
    ${pro} =    Evaluate    '${raw_pro}'.replace('"','')   # replace " 
    Should Be True    ${pro} > ${threshold}
