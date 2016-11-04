*** Settings ***
Documentation     This suite includes cases related to Cluster Managerment
Resource          ../00_commonconfig.txt
Resource          ../00_commonkeyword.txt
Resource          00_clusterconfigurationkeywords.txt

*** Test Cases ***
Enable/Disable Maintenance Mode
    [Documentation]    TestLink ID: Sc-360:Enable/Disable Maintenance Mode
    [Tags]    FAST
    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
    Enable Disable Maintenance Mode    True
    [Teardown]    Enable Disable Maintenance Mode    False

Incremental recovery in case OSD in
    [Documentation]    TestLink ID: Sc-361:Incremental recovery in case OSD in
    [Tags]    FAST
    ${osd_name}=    Set Variable    osd-incremental-test
    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
    log    Enable Incremental recovery
    Incremental Recovery    True
    log    Add OSD,and join Default pool
    Create OSD    ${osd_name}
    log    Check incremental recovery work results
    Get OSD Reweight
    [Teardown]    Run Keywords    Incremental Recovery    False
    ...    AND    Disable and Delete OSD    @{STORAGEIP}[0]    ${osd_name}
