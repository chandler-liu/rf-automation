*** Settings ***
Documentation     This suite includes cases related to general cases about iSCSI configuration
Suite Setup       Run Keywords    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
...               AND    Open All SSH Connections    ${USERNAME}    ${PASSWORD}    @{PUBLICIP}
...               AND    Open Connection    127.0.0.1    alias=127.0.0.1
...               AND    Login    ${LOCALUSER}    ${LOCALPASS}
Suite Teardown    Close All Connections    # Close SSH connections
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
${iscsi_lun_size}    5368709120    # 5G
${read_maxbw_M}    5
${read_maxbw_bytes}    5242750
${read_maxiops}    50
${write_maxbw_M}    5
${write_maxbw_bytes}    5242750
${write_maxiops}    50

*** Test Cases ***
Add iSCSI target
    [Documentation]    Testlink ID:
    ...    Sc-530:Add iSCSI target
    [Tags]    RAT    
    Add iSCSI Target    gateway_group=${vs_name}    target_id=${iscsi_target_name_urlencoding}
    Switch Connection    @{PUBLICIP}[0]
    Wait Until Keyword Succeeds    30s    5s    SSH Output Should Be Equal    scstadmin --list_target|grep ${iscsi_target_name}|awk '{print \$2}'    ${iscsi_target_name}

Add iSCSI volume
    [Documentation]    Testlink ID:
    ...    Sc-540:Add iSCSI volume
    [Tags]    RAT    
    SSH Output Should Be Equal    scstadmin --list_device | grep vdisk_blockio | awk '{print \$2}'    -
    Add iSCSI Volume    gateway_group=${vs_name}    pool_id=${default_pool}    target_id=${iscsi_target_name_urlencoding}    iscsi_id=${iscsi_lun_name}    size=${iscsi_lun_size}
    Wait Until Keyword Succeeds    30s    5s    Check If SSH Output Is Empty    rbd showmapped    ${false}
    Wait Until Keyword Succeeds    30s    5s    SSH Output Should Match    scstadmin --list_device | grep vdisk_blockio | awk '{print \$2}'    tgt*
    Switch Connection    127.0.0.1
    SSH Output Should Contain    iscsiadm -m discovery -t st -p @{PUBLICIP}[0]    ${iscsi_target_name}
    Execute Command Successfully    iscsiadm -m node -o delete

Disable iSCSI volume
    [Documentation]    Testlink ID:
    ...    Sc-544:Disable iSCSI volume
    [Tags]    RAT    
    Switch Connection    @{PUBLICIP}[0]
    Check If SSH Output Is Empty    rbd showmapped    ${false}
    Disable iSCSI LUN    ${vs_name}    ${iscsi_target_name_urlencoding}    ${iscsi_lun_name}
    Wait Until Keyword Succeeds    30s    5s    SSH Output Should Be Equal    scstadmin --list_device | grep vdisk_blockio | awk '{print \$2}'    -
    Wait Until Keyword Succeeds    30s    5s    Check If SSH Output Is Empty    rbd showmapped    ${true}

Enable iSCSI volume
    [Documentation]    Testlink ID:
    ...    Sc-543:Enable iSCSI volume
    [Tags]    RAT    
    Check If SSH Output Is Empty    rbd showmapped    ${true}
    Enable iSCSI LUN    ${vs_name}    ${iscsi_target_name_urlencoding}    ${iscsi_lun_name}
    Wait Until Keyword Succeeds    30s    5s    Check If SSH Output Is Empty    rbd showmapped    ${false}
    Wait Until Keyword Succeeds    30s    5s    SSH Output Should Match    scstadmin --list_device | grep vdisk_blockio | awk '{print \$2}'    tgt*

Only listed client can access
    [Documentation]    Testlink ID:
    ...    Sc-549:Only listed client can access
    [Tags]    FAST    
    Switch Connection    127.0.0.1
    ${dummy_initiator} =    Set Variable    iqn.2014-02.thisisadummy:initiator
    Modify iSCSI LUN    allow_all=false    gateway_group=${vs_name}    allowed_initiators=${dummy_initiator}    iscsi_id=${iscsi_lun_name}    target_id=${iscsi_target_name_urlencoding}    size=${iscsi_lun_size}
    Wait Until Keyword Succeeds    30s    5s    SSH Output Should Contain    iscsiadm -m discovery -t st -p @{PUBLICIP}[0]    ${iscsi_target_name}
    Wait Until Keyword Succeeds    30s    5s    Check If Disk Output Is Empty    iscsiadm -m session -P 3 | grep sd    ${true}
	${initiator_name} =    Execute Command    cat /etc/iscsi/initiatorname.iscsi | grep InitiatorName= | cut -d '=' -f 2
    Modify iSCSI LUN    allow_all=false    gateway_group=${vs_name}    allowed_initiators=${initiator_name}    iscsi_id=${iscsi_lun_name}    target_id=${iscsi_target_name_urlencoding}    size=${iscsi_lun_size}
    Wait Until Keyword Succeeds    30s    5s    SSH Output Should Contain    iscsiadm -m discovery -t st -p @{PUBLICIP}[0]    ${iscsi_target_name}
    Wait Until Keyword Succeeds    30s    5s    Check If Disk Output Is Empty    iscsiadm -m session -P 3 | grep sd    ${false}
	
QoS of iops takes effect
    [Documentation]     Testlink ID:
    ...    Sc-558:QoS of iops takes effect
    [Tags]    FAST
    Switch Connection    127.0.0.1
    ${sdx} =    Execute Command    iscsiadm -m session -P 3 > /tmp/iscsi_debug;iscsiadm -m session -P 3|grep -A 50 @{PUBLICIP}[0] |awk '/Attached scsi disk/ {print $4}'
    Wait Until Keyword Succeeds    30s    5s    Should Match    ${sdx}    sd*
    # Before set QoS
    Execute Command Successfully    fio --name=randwrite --rw=randwrite --bs=4k --size=100M --runtime=20 --ioengine=libaio --iodepth=16 --numjobs=1 --filename=/dev/${sdx} --direct=1 --group_reporting --output=fio.result
    ${randwrite_iops} =    Execute Command    cat fio.result | sed -ne 's/.*iops=\\(.*\\),.*/\\1/p'
    Log    Before set QoS: ${randwrite_iops}
    Should Be True    ${randwrite_iops} > ${write_maxiops}
    Enable iSCSI QoS    gateway_group=${vs_name}    iscsi_id=${iscsi_lun_name}    target_id=${iscsi_target_name}    size=${iscsi_lun_size}    
    ...               read_maxbw=${read_maxbw_bytes}    read_maxiops=${read_maxiops}    write_maxbw=${write_maxbw_bytes}    write_maxiops=${write_maxiops}
    Switch Connection    @{PUBLICIP}[0]
    SSH Output Should Be Equal   cat /sys/bus/rbd/devices/0/read_maxiops    ${read_maxiops}
    SSH Output Should Be Equal   cat /sys/bus/rbd/devices/0/write_maxiops    ${write_maxiops}
    # After set QoS
    Switch Connection    127.0.0.1
    Execute Command Successfully    fio --name=randwrite --rw=randwrite --bs=4k --size=100M --runtime=20 --ioengine=libaio --iodepth=16 --numjobs=1 --filename=/dev/${sdx} --direct=1 --group_reporting --output=fio.result
    ${randwrite_iops} =    Execute Command    cat fio.result | sed -ne 's/.*iops=\\(.*\\),.*/\\1/p'
    Log    After set QoS: ${randwrite_iops}
    Should Be True    ${randwrite_iops} <= ${write_maxiops}
    [Teardown]    Disable iSCSI QoS    gateway_group=${vs_name}    iscsi_id=${iscsi_lun_name}    target_id=${iscsi_target_name}    size=${iscsi_lun_size}
    
QoS of bandwidth takes effect
    [Documentation]     Testlink ID:
    ...    Sc-559:QoS of bandwidth takes effect
    [Tags]    FAST
    Switch Connection    127.0.0.1
    ${sdx} =    Execute Command    iscsiadm -m session -P 3 > /tmp/iscsi_debug;iscsiadm -m session -P 3|grep -A 50 @{PUBLICIP}[0] |awk '/Attached scsi disk/ {print $4}'
    Wait Until Keyword Succeeds    30s    5s    Should Match    ${sdx}    sd*
    # Before set QoS
    Execute Command Successfully    fio --name=randwrite --rw=randwrite --bs=1M --size=100M --runtime=20 --ioengine=libaio --iodepth=16 --numjobs=1 --filename=/dev/${sdx} --direct=1 --group_reporting --output=fio.result
    ${randwrite_iops} =    Execute Command    cat fio.result | sed -ne 's/.*iops=\\(.*\\),.*/\\1/p'
    Log    Before set QoS: ${randwrite_iops}
    Should Be True    ${randwrite_iops} > ${write_maxbw_M}
    Enable iSCSI QoS    gateway_group=${vs_name}    iscsi_id=${iscsi_lun_name}    target_id=${iscsi_target_name}    size=${iscsi_lun_size}    
    ...               read_maxbw=${read_maxbw_bytes}    read_maxiops=${read_maxiops}    write_maxbw=${write_maxbw_bytes}    write_maxiops=${write_maxiops}
    Switch Connection    @{PUBLICIP}[0]
    SSH Output Should Be Equal   cat /sys/bus/rbd/devices/0/read_maxbw    ${read_maxbw_bytes}
    SSH Output Should Be Equal   cat /sys/bus/rbd/devices/0/write_maxbw    ${write_maxbw_bytes}
    # After set QoS
    Switch Connection    127.0.0.1
    Execute Command Successfully    fio --name=randwrite --rw=randwrite --bs=1M --size=100M --runtime=20 --ioengine=libaio --iodepth=16 --numjobs=1 --filename=/dev/${sdx} --direct=1 --group_reporting --output=fio.result
    ${randwrite_iops} =    Execute Command    cat fio.result | sed -ne 's/.*iops=\\(.*\\),.*/\\1/p'
    Log    After set QoS: ${randwrite_iops}
    Should Be True    ${randwrite_iops} <= ${write_maxbw_M}
    [Teardown]    Execute Command Successfully     iscsiadm -m node -u; iscsiadm -m node -o delete

Delete iSCSI volume
    [Documentation]    Testlink ID:
    ...    Sc-545:Delete iSCSI volume
    [Tags]    RAT    
    Switch Connection    @{PUBLICIP}[0]
    Disable iSCSI LUN    ${vs_name}    ${iscsi_target_name_urlencoding}    ${iscsi_lun_name}
    Wait Until Keyword Succeeds    30s    5s    SSH Output Should Be Equal    scstadmin --list_device | grep vdisk_blockio | awk '{print \$2}'    -
    Wait Until Keyword Succeeds    30s    5s    Check If SSH Output Is Empty    rbd showmapped    ${true}
    Delete iSCSI LUN    ${vs_name}    ${iscsi_target_name_urlencoding}    ${iscsi_lun_name}
    Wait Until Keyword Succeeds    2m    5s    Check If SSH Output Is Empty    rbd ls    ${true}

Delete iSCSI target
    [Documentation]    Testlink ID:
    ...    Sc-539:Delete iSCSI target
    [Tags]    RAT    
    Delete iSCSI Target    ${vs_name}    ${iscsi_target_name_urlencoding}
    Wait Until Keyword Succeeds    30s    5s    SSH Output Should Not Contain    cat /etc/scst.conf    DEVICE


*** Keywords ***
Enable iSCSI QoS
    [Arguments]    ${gateway_group}    ${iscsi_id}    ${read_maxbw}    ${read_maxiops}    ${write_maxbw}    ${write_maxiops}
    ...            ${size}    ${target_id}
    Modify iSCSI LUN    gateway_group=${gateway_group}    iscsi_id=${iscsi_id}    target_id=${target_id}    size=${size}    qos_enabled=true    read_maxbw=${read_maxbw}    read_maxiops=${read_maxiops}    write_maxbw=${write_maxbw}    write_maxiops=${write_maxiops} 
    Switch Connection    @{PUBLICIP}[0]
    Wait Until Keyword Succeeds    4x    5s    SSH Output Should Be Equal   cat /sys/bus/rbd/devices/0/qos    1

Disable iSCSI QoS
    [Arguments]    ${gateway_group}    ${iscsi_id}    ${size}    ${target_id}
    Modify iSCSI LUN    gateway_group=${gateway_group}    iscsi_id=${iscsi_id}    target_id=${target_id}    size=${size}    qos_enabled=false
    Switch Connection    @{PUBLICIP}[0]
    Wait Until Keyword Succeeds    4x    5s    SSH Output Should Be Equal   cat /sys/bus/rbd/devices/0/qos    0

Check If Disk Output Is Empty
	[Arguments]    ${cmd}    ${true_false}
	Execute Command    iscsiadm -m node --logout -T ${iscsi_target_name}
	Execute Command Successfully    iscsiadm -m node -T ${iscsi_target_name} -l
    ${output}=    Execute Command    ${cmd}
    Run Keyword If    '${true_false}' == '${true}'    Should Be Empty    ${output}
    ...    ELSE IF    '${true_false}' == '${false}'    Should Not Be Empty    ${output}
    ...    ELSE    Fail    The parameter should be '${true}' or '${false}'
	