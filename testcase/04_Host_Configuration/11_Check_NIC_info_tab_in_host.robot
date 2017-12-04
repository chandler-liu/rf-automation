*** Settings ***
Documentation     This suite includes cases related to general cases about check NIC info tab in host
Suite Setup       Run Keywords    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
...               AND    Open All SSH Connections    ${USERNAME}    ${PASSWORD}    @{PUBLICIP}
Suite Teardown    Close All Connections    # Close SSH connections
Resource          ../00_commonconfig.txt
Resource          ../00_commonkeyword.txt
Resource          00_hostconfigurationkeywords.txt
*** Test Cases ***
Check "Network Interface" page in UI
    [Documentation]    Testlink ID: Sc-140:Check "Network Interface" page in UI
    [Tags]    FAST
    Switch Connection    @{PUBLICIP}[0]
    ${nic_name}=    Execute Command    ifconfig | grep -E "ens|enp|eno|enx" |awk '{print $1}' | tail -1
    log    Check "Network Interface" page in UI
    ${net_info}=    Get Return Json    /cgi-bin/ezs3/json/host_nic_list?host=@{STORAGEIP}[1]&exclude_ha_iface=false    /response/interface_list/${nic_name}/link
    Should Be Equal    ${net_info}    "on"
