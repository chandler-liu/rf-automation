*** Settings ***
Resource          ../00_commonconfig.txt
Resource          ../00_commonkeyword.txt
Resource          00_clusterconfigurationkeywords.txt

*** Test Cases ***
Add a new replicated pool
    [Documentation]    TestLink ID: Sc-254 Add a new replicated pool
    [Tags]    RAT
    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
    Create Pool    1    replica-pool
    Add OSD To Pool    replica-pool    0+1+2
    [Teardown]    Delete Pool    replica-pool

Add a new EC pool
    [Documentation]    TestLink ID: Sc-255:Add a new EC pool
    [Tags]    RAT
    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
    Create Pool    3    EC-pool
    Add OSD To Pool    EC-pool    0+1+2
    [Teardown]    Delete Pool    EC-pool

Add nodes to a custom pool with nodes
    [Documentation]    TestLink ID: Sc-256:Add nodes to a custom pool with nodes
    [Tags]    FAST
    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
    Create Pool    1    add-osd-replica-pool
    Add OSD To Pool    add-osd-replica-pool    0+1
    Wait Until Keyword Succeeds    6 min    5 sec    Get Cluster Health Status
    Add OSD To Pool    add-osd-replica-pool    2
    Wait Until Keyword Succeeds    6 min    5 sec    Get Cluster Health Status
    [Teardown]    Delete Pool    add-osd-replica-pool

Remove nodes from a custom pool with nodes
    [Documentation]    TestLink ID: Sc-257:Remove nodes from a custom pool with nodes
    [Tags]    FAST
    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
    Create Pool    1    remove-osd-from-pool
    Add OSD To Pool    remove-osd-from-pool    0+1+2
    Wait Until Keyword Succeeds    6 min    5 sec    Get Cluster Health Status
    log    Remove OSD from pool [remove-osd-from-pool]
    Remove OSD From Pool    remove-osd-from-pool    2
    Wait Until Keyword Succeeds    6 min    5 sec    Get Cluster Health Status
    [Teardown]    Delete Pool    remove-osd-from-pool

Edit replication number of replicated pool
    [Documentation]    TestLink ID: Sc-258:Edit replication number of replicated pool
    [Tags]    FAST
    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
    log    Create a pool which replication number of replicated is 2
    Create Pool    1    replica-no-pool
    Add OSD To Pool    replica-no-pool    0+1+2
    log    Edit replication number of replicated pool, replica=2 --> replica=3
    Modify Pool Replication NO    replica-no-pool    1    3
    [Teardown]    Delete Pool    replica-no-pool

Change quota of a non-default pool
    [Documentation]    TestLink ID: Sc-259:Change quota of a non-default pool
    [Tags]    RAT
    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
    Create Pool    1    replica-pool-quota
    Add OSD To Pool    replica-pool-quota    0+1+2
    Set Pool Quota    replica-pool-quota    10737418240
    [Teardown]    Delete Pool    replica-pool-quota

Remove a replicated pool
    [Documentation]    TestLink ID: Sc-260:Remove a replicated pool
    [Tags]    RAT
    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
    Create Pool    1    replica-pool-remove
    Add OSD To Pool    replica-pool-remove    0+1+2
    [Teardown]    Delete Pool    replica-pool-remove

Remove a EC pool
    [Documentation]    TestLink ID: Sc-261:Remove a EC pool
    [Tags]    RAT
    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
    Create Pool    3    EC-pool-remove
    Add OSD To Pool    EC-pool-remove    0+1+2
    [Teardown]    Delete Pool    EC-pool-remove
