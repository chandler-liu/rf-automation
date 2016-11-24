*** Settings ***
Suite Setup       Run Keywords    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
...               AND    Open All SSH Connections    ${USERNAME}    ${PASSWORD}    @{PUBLICIP}
...               AND    Switch Connection    @{PUBLICIP}[1]
Suite Teardown    Run Keywords    Switch Connection    @{PUBLICIP}[1]
...               AND    Close All Connections    # Close SSH connections
Resource          ../00_commonconfig.txt
Resource          ../00_commonkeyword.txt
Resource          00_hostconfigurationkeywords.txt

*** Test Cases ***
Enable/Disable FS cache
    [Documentation]    TestLink ID: Sc-125 Enable/Disable FS cache
    [Tags]    FAST
    log    Start to enable FS cache
    ${cache_disk}=    Set Variable    sdd
    Add FS Cache    ${cache_disk}
    [Teardown]    Disable FS Cache

Add SAN Volume Cache when volume is enabled
    [Documentation]    TestLink ID: Sc-127:Add SAN Volume Cache when volume is enabled
    [Tags]    FAST
    ${cache_disk}=    Set Variable    sdd
    log    Start to create iSCSI target
    Return Code Should be 0    /cgi-bin/ezs3/json/iscsi_add_target?gateway_group=Default&target_id=iqn.2016-09.rf%3Aautotest&pool_id=Default
    log    Create iSCSI volume
    Return Code Should Be 0    /cgi-bin/ezs3/json/iscsi_add?allowed_initiators=&gateway_group=Default&iscsi_id=autltest_lv&qos_enabled=false&size=1073741824&snapshot_enabled=false&target_id=iqn.2016-09.rf:autotest
    sleep    10
    log    Get rbd image name
    ${rbd_image_name}=    Do SSH CMD    @{PUBLICIP}[1]    ${USERNAME}    ${PASSWORD}    rbd ls
    Add SAN Cache    ${rbd_image_name}    ${cache_disk}
    [Teardown]    Run Keywords    Disable SAN Cache    ${cache_disk}
    ...    AND    Remove iSCSI Volume And Target
