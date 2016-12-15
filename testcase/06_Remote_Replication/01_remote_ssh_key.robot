# The cluster RRS uses itself as remote RRS, to reduce dependency on other cluster

*** Settings ***
Documentation     This suite includes cases related to general cases about virtual storage
Suite Setup       Run Keywords    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
...               AND    Open All SSH Connections    ${USERNAME}    ${PASSWORD}    @{PUBLICIP}
Suite Teardown    Close All Connections    # Close SSH connections
Library           OperatingSystem
Library           SSHLibrary
Library           HttpLibrary.HTTP
Resource          ../00_commonconfig.txt
Resource          ../00_commonkeyword.txt

*** Variables ***
#${external_rrs}    172.16.146.101
#${external_user}    root
#${external_password}    1
${external_rrs}    172.16.146.220
${external_user}    root
${external_password}    p@ssw0rd

*** Test Cases ***
Add public key of remote cluster
    [Documentation]    Testlink ID:
    ...    Sc-661:Add public key of remote cluster
    [Tags]    FAST
    Open Connection    ${external_rrs}    alias=${external_rrs}
    Login    ${external_user}    ${external_password}
    ${name_raw} =    Execute Command    cat ~/.ssh/id_dsa.pub | awk '{print $NF}'
    ${name_url} =    Evaluate    '${name_raw}'.replace('@','%40')
    ${name_url} =    Set Variable    ${name_url}%0A
    ${content_raw} =    Execute Command    cat ~/.ssh/id_dsa.pub | awk '{print $2}'
    ${content_url} =    Evaluate    '${content_raw}'.replace('+','%2B').replace('/','%2F').replace('=','%3D')
    ${content_url} =    Set Variable    ssh-dss+${content_url}
    Add Remote SSH Key    ${name_url}    ${content_url}
    Switch Connection    ${external_rrs}
    Execute Command Successfully    ssh-keygen -f "/root/.ssh/known_hosts" -R @{PUBLICIP}[0]
    Execute Command Successfully    ssh @{PUBLICIP}[0] "date"

*** Keywords ***
Add Remote SSH Key
    [Arguments]    ${name}    ${content}
    Return Code Should Be 0    /cgi-bin/ezs3/json/add_replication_key?name=${name}&content=${content}
