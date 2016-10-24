*** Settings ***
Documentation     This suite includes cases related to general cases about iSCSI configuration
Suite Setup       Run Keywords    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
...               AND    Open All SSH Connections    ${USERNAME}    ${PASSWORD}    @{PUBLICIP}
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

*** Test Cases ***
Add iSCSI target
    [Documentation]    Testlink ID:
    ...    Sc-530:Add iSCSI target
    [Tags]    RAT    
    Add iSCSI Target    gateway_group=${vs_name}    target_id=${iscsi_target_name_urlencoding}    pool_id=${default_pool}
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
    ${output} =    Run    sudo iscsiadm -m discovery -t st -p @{PUBLICIP}[0]
    Should Contain    ${output}    ${iscsi_target_name}
    ${rc} =    Run and Return RC    sudo iscsiadm -m node -o delete
    Should Be Equal As Integers    ${rc}    0

Disable iSCSI volume
    [Documentation]    Testlink ID:
    ...    Sc-544:Disable iSCSI volume
    [Tags]    RAT    
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
    ${dummy_initiator} =    Set Variable    thisisadummyinitiator
    ${initiator_name} =    Get Initiator Name
    Modify iSCSI LUN    gateway_group=${vs_name}    allowed_initiators=${dummy_initiator}    iscsi_id=${iscsi_lun_name}    target_id=${iscsi_target_name_urlencoding}    size=${iscsi_lun_size}
    Wait Until Keyword Succeeds    30s    5s    Run Output Should Contain    sudo iscsiadm -m discovery -t st -p @{PUBLICIP}[0]    No portals found
    Modify iSCSI LUN    gateway_group=${vs_name}    allowed_initiators=${initiator_name}    iscsi_id=${iscsi_lun_name}    target_id=${iscsi_target_name_urlencoding}    size=${iscsi_lun_size}
    Wait Until Keyword Succeeds    30s    5s    Run Output Should Contain    sudo iscsiadm -m discovery -t st -p @{PUBLICIP}[0]    ${iscsi_target_name}
    ${rc} =    Run and Return RC    sudo iscsiadm -m node -o delete
    Should Be Equal As Integers    ${rc}    0

Delete iSCSI volume
    [Documentation]    Testlink ID:
    ...    Sc-545:Delete iSCSI volume
    [Tags]    RAT    
    Disable iSCSI LUN    ${vs_name}    ${iscsi_target_name_urlencoding}    ${iscsi_lun_name}
    Wait Until Keyword Succeeds    30s    5s    SSH Output Should Be Equal    scstadmin --list_device | grep vdisk_blockio | awk '{print \$2}'    -
    Wait Until Keyword Succeeds    30s    5s    Check If SSH Output Is Empty    rbd showmapped    ${true}
    Delete iSCSI LUN    ${vs_name}    ${iscsi_target_name_urlencoding}    ${iscsi_lun_name}
    Wait Until Keyword Succeeds    30s    5s    Check If SSH Output Is Empty    rbd ls    ${true}

Delete iSCSI target
    [Documentation]    Testlink ID:
    ...    Sc-539:Delete iSCSI target
    [Tags]    RAT    
    Delete iSCSI Target    ${vs_name}    ${iscsi_target_name_urlencoding}
    Wait Until Keyword Succeeds    30s    5s    SSH Output Should Not Contain    cat /etc/scst.conf    DEVICE


*** Keywords ***
Get Initiator Name
    ${ret} =    Run    sudo cat /etc/iscsi/initiatorname.iscsi | grep InitiatorName= | cut -d '=' -f 2
    [Return]    ${ret}
