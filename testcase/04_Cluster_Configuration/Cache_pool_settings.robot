*** Settings ***
Resource          ../00_commonconfig.txt
Resource          ../00_commonkeyword.txt
Resource          00_clusterconfigurationkeywords.txt

*** Test Cases ***
Set cache pool for EC pool
    [Documentation]    TestLink ID: Sc-273:Set cache pool for EC pool
    [Tags]    RAT
    ${base_pool_name}=    Set Variable    EC-pool-need-cache
    ${cache_pool_name}=    Set Variable    replica-cache-pool
    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
    Create Pool    1    ${cache_pool_name}
    Add OSD To Pool    ${cache_pool_name}    0+1+2
    Wait Until Keyword Succeeds    6 min    5 sec    Get Cluster Health Status
    Create Pool    3    ${base_pool_name}
    Add OSD To Pool    ${base_pool_name}    0+1+2
    Wait Until Keyword Succeeds    6 min    5 sec    Get Cluster Health Status
    Add Cache Pool    ${base_pool_name}    ${cache_pool_name}
    Wait Until Keyword Succeeds    3 min    5 sec    Get Cluster Health Status
    # Remove Cache Pool    ${base_pool_name}    ${cache_pool_name}
    # Wait Until Keyword Succeeds    3 min    5 sec    Get Cluster Health Status
    [Teardown]    Run Keywords    Remove Cache Pool    ${base_pool_name}    ${cache_pool_name}
    ...    AND    Delete Pool    ${base_pool_name}

Set cache pool for replicated pool
    [Documentation]    TestLink ID: Sc-274:Set cache pool for replicated pool
    [Tags]    RAT
    ${base_pool_name}=    Set Variable    base-replicate-pool
    ${cache_pool_name}=    Set Variable    replica-cache-pool
    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
    Create Pool    1    ${cache_pool_name}
    Add OSD To Pool    ${cache_pool_name}    0+1+2
    Wait Until Keyword Succeeds    6 min    5 sec    Get Cluster Health Status
    Create Pool    1    ${base_pool_name}
    Add OSD To Pool    ${base_pool_name}    0+1+2
    Wait Until Keyword Succeeds    6 min    5 sec    Get Cluster Health Status
    Add Cache Pool    ${base_pool_name}    ${cache_pool_name}
    Wait Until Keyword Succeeds    3 min    5 sec    Get Cluster Health Status
    # Remove Cache Pool    ${base_pool_name}    ${cache_pool_name}
    # Wait Until Keyword Succeeds    3 min    5 sec    Get Cluster Health Status
    # [Teardown]    Delete Pool    base-replicate-pool
    [Teardown]    Run Keywords    Remove Cache Pool    ${base_pool_name}    ${cache_pool_name}
    ...    AND    Delete Pool    ${base_pool_name}

Remove cache pool for replicated pool
    [Documentation]    TestLink ID: Sc-275:Remove cache pool for replicated pool
    [Tags]    RAT
    ${folder_name}=    Set Variable    nasfolder
    ${vs_name}=    Set Variable    Default
    ${base_pool_name}=    Set Variable    base-replicate-pool
    ${cache_pool_name}=    Set Variable    replica-cache-pool
    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
    Create Pool    1    ${cache_pool_name}
    Add OSD To Pool    ${cache_pool_name}    0+1+2
    Wait Until Keyword Succeeds    6 min    5 sec    Get Cluster Health Status
    Create Pool    1    ${base_pool_name}
    Add OSD To Pool    ${base_pool_name}    0+1+2
    Wait Until Keyword Succeeds    6 min    5 sec    Get Cluster Health Status
    Add Cache Pool    ${base_pool_name}    ${cache_pool_name}
    Wait Until Keyword Succeeds    3 min    5 sec    Get Cluster Health Status
    Add Shared Folder    name=${folder_name}    gateway_group=${vs_name}    pool=${base_pool_name}    nfs=true
    log    Get objects of base pool
    ${base_pool_objects}=    DO SSH CMD    @{PUBLICIP}[0]    ${USERNAME}    ${PASSWORD}    ceph df | grep ${base_pool_name} | head -n 1 | awk -F " " '{print $NF}'
    log    Write data to cache pool
    sleep    5
    Write    cd /vol/${folder_name}
    Write    dd if=/dev/zero of=/vol/${folder_name}/test.txt bs=1M count=32
    Remove Cache Pool    ${base_pool_name}    ${cache_pool_name}
    Wait Until Keyword Succeeds    3 min    5 sec    Get Cluster Health Status
    log    Get objects of base pool again
    ${after_base_pool_objects}=    DO SSH CMD    @{PUBLICIP}[0]    ${USERNAME}    ${PASSWORD}    ceph df | grep ${base_pool_name} | head -n 1 | awk -F " " '{print $NF}'
    Should Be True    ${after_base_pool_objects}>${base_pool_objects}
    [Teardown]    Run Keywords    Delete Shared Folder    ${vs_name}    ${folder_name}
    ...    AND    Delete Pool    ${base_pool_name}
