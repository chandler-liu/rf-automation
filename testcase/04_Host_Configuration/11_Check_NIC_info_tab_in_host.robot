*** Settings ***
Documentation     This suite includes cases related to general cases about check NIC info tab in host
Suite Setup       Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
Resource          ../00_commonconfig.txt
Resource          ../00_commonkeyword.txt
Resource          00_hostconfigurationkeywords.txt

*** Test Cases ***
Check "Network Interface" page in UI
    [Documentation]    Testlink ID: Sc-140:Check "Network Interface" page in UI
    [Tags]    FAST
    log    Check "Network Interface" page in UI
    ${net_info}=    Get Return Json    /cgi-bin/ezs3/json/host_nic_list?host=@{STORAGEIP}[1]&exclude_ha_iface=false    /response/interface_list/ens192/link
    Should Be Equal    ${net_info}    "on"
