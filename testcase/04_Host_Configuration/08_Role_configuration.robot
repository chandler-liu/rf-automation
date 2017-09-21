*** Settings ***
Documentation     This suite includes cases related to general cases about role configuration
Suite Setup       Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
Resource          ../00_commonconfig.txt
Resource          ../00_commonkeyword.txt
Resource          00_hostconfigurationkeywords.txt

*** Test Cases ***
Enable/Disable gateway
    [Documentation]    Testlink ID: \ Sc-113:Enable/Disable gateway
    [Tags]    RAT
    log    Get GW or RRS state, if state=0, execute the enable-->disable-->enable operation; If state=2, do disable then enable GW or RRS
    ${gw_state}=    Get GW or RRS Status    @{STORAGEIP}[1]    0    gw    False
    Run Keyword If    ${gw_state}==0    First Enable GW or RRS    gw
    ...    ELSE IF    ${gw_state}==2    First Disable GW or RRS    gw

Enable/Disable RRS
    [Documentation]    Testlink ID: Sc-114:Enable/Disable RRS
    [Tags]    RAT
    log    Get RRS state, if state=0, execute the enable-->disable-->enable operation; If state=2, do disable then enable RRS
    ${rrs_state}=    Get GW or RRS Status    @{STORAGEIP}[0]    0    rrs    False
    Run Keyword If    ${rrs_state}==0    First Enable GW or RRS    rrs
    ...    ELSE IF    ${rrs_state}==2    First Disable GW or RRS    rrs
