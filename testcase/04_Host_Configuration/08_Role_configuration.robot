*** Settings ***
Documentation     This suite includes cases related to general cases about role configuration
Suite Setup       Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
Resource          ../00_commonconfig.txt
Resource          ../keyword/keyword_verify.txt
Resource          ../keyword/keyword_system.txt
Resource          ../keyword/keyword_cgi.txt

*** Test Cases ***
Enable/Disable gateway
    [Documentation]    Testlink ID: \ Sc-113:Enable/Disable gateway
    [Tags]    RAT
	Enable/Disable gateway
    
Enable/Disable RRS
    [Documentation]    Testlink ID: Sc-114:Enable/Disable RRS
    [Tags]    RAT
	Enable/Disable RRS
	
*** Keywords ***
Enable/Disable gateway
    log    Get GW or RRS state, if state=0, execute the enable-->disable-->enable operation; If state=2, do disable then enable GW or RRS
    ${gw_state}=    Get Role Status    @{STORAGEIP}[1]    gw
    Run Keyword If    ${gw_state}==0    First Enable GW
    ...    ELSE IF    ${gw_state}==2    First Disable GW
	
Enable/Disable RRS
    log    Get RRS state, if state=0, execute the enable-->disable-->enable operation; If state=2, do disable then enable RRS
    ${rrs_state}=    Get Role Status    @{STORAGEIP}[0]    rrs
    Run Keyword If    ${rrs_state}==0    First Enable RRS
    ...    ELSE IF    ${rrs_state}==2    First Disable RRS