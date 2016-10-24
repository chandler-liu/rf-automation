*** Settings ***
Resource          ../00_commonconfig.txt
Resource          ../00_commonkeyword.txt
Resource          00_hostconfigurationkeywords.txt

*** Test Cases ***
Stop Node Monitor via UI,which is not the last one
    [Documentation]    Testlink ID: Sc-119:Stop Node Monitor via UI,which is not the last one
    [Tags]    Fast
    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
    log    Get ceph-mon status
    ${mon_status}=    Get ceph-mon Status
    log    ceph-mon current status is: ${mon_status}
    Run Keyword If    ${mon_status}==2    Disable ceph-mon

Start Node Monitor via UI
    [Documentation]    Testlink ID: Sc-118:Start Node Monitor via UI
    [Tags]    Fast
    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
    log    Get ceph-mon status
    ${mon_status}=    Get ceph-mon Status
    log    ceph-mon current status is: ${mon_status}
    Run Keyword If    ${mon_status}==2    First Disable ceph-mon
    ...    ELSE    First Enable ceph-mon
