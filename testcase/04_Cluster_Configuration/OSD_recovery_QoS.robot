*** Settings ***
Documentation     This suite includes cases related to OSD recovery qos
Suite Setup       Run Keywords    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
...               AND    Open All SSH Connections    ${USERNAME}    ${PASSWORD}    @{PUBLICIP}
...               AND    Switch Connection    @{PUBLICIP}[0]
Suite Teardown    Close All Connections
Resource          ../00_commonconfig.txt
Resource          ../00_commonkeyword.txt
Resource          00_clusterconfigurationkeywords.txt

*** Test Cases ***
Check config when turn it on
    [Documentation]    TestLink ID: Sc-365:Check config when turn it on
    [Tags]    RAT
    ${recovery_maxbw_size}=    Set Variable    2097152
    Set OSD QoS    enabled=true    recovery_maxbw=${recovery_maxbw_size}
    log    Check OSD QOS set result
    Wait Until Keyword Succeeds    2 min    5 sec    SSH Output Should Contain    ceph config-key get osd_recovery_qos    "enabled": true
    Wait Until Keyword Succeeds    2 min    5 sec    SSH Output Should Contain    ceph daemon osd.0 config get osd_recovery_max_bytes_per_second    ${recovery_maxbw_size}
    log    Set OSD Qos success
    [Teardown]    Set OSD QoS    false    0

Check config when turn it off
    [Documentation]    TestLink ID: Sc-366:Check config when turn it off
    [Tags]    RAT
    Set OSD QoS    enabled=false    recovery_maxbw=0
    log    Check OSD QOS set result
    Wait Until Keyword Succeeds    2 min    5 sec    SSH Output Should Contain    ceph config-key get osd_recovery_qos    "enabled": false
    log    Set OSD Qos success

Check config when modify the value
    [Documentation]    TestLink ID: Sc-367:Check config when modify the value
    [Tags]    RAT
    ${recovery_maxbw_size}=    Set Variable    2097152
    ${recovery_maxbw_resize}=    Set Variable    3145728
    Set OSD QoS    enabled=true    recovery_maxbw=${recovery_maxbw_size}
    log    Check OSD QOS set result
    Wait Until Keyword Succeeds    2 min    5 sec    SSH Output Should Contain    ceph config-key get osd_recovery_qos    "enabled": true
    Wait Until Keyword Succeeds    2 min    5 sec    SSH Output Should Contain    ceph daemon osd.0 config get osd_recovery_max_bytes_per_second    ${recovery_maxbw_size}
    log    Modify OSD QOS setting
    Set OSD QoS    enabled=true    recovery_maxbw=${recovery_maxbw_resize}
    log    Check reset OSD QOS result
    Wait Until Keyword Succeeds    2 min    5 sec    SSH Output Should Contain    ceph daemon osd.0 config get osd_recovery_max_bytes_per_second    ${recovery_maxbw_resize}
    log    Set OSD Qos success
    [Teardown]    Set OSD QoS    false    0
