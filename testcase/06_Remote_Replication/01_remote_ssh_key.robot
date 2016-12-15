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

*** Test Cases ***
Add public key of remote cluster
    [Documentation]    Testlink ID:
    ...    Sc-661:Add public key of remote cluster
    [Tags]    FAST
    Open Connection    ${DUMMYRRSIP}    alias=${DUMMYRRSIP}
    Login    ${DUMMYRRSUSER}    ${DUMMYRRSPASS}
    ${name_raw} =    Execute Command    cat ~/.ssh/id_dsa.pub | awk '{print $NF}'
    ${name_url} =    Evaluate    '${name_raw}'.replace('@','%40')
    ${content_raw} =    Execute Command    cat ~/.ssh/id_dsa.pub | awk '{print $2}'
    ${content_url} =    Evaluate    '${content_raw}'.replace('+','%2B').replace('/','%2F').replace('=','%3D')
    ${content_url} =    Set Variable    ssh-dss+${content_url}
    Add Remote SSH Key    ${name_url}    ${content_url}
    
Display public key of local cluster
    [Documentation]    Testlink ID:
    ...    Sc-663:Display public key of local cluster
    [Tags]    FAST
    Switch Connection    @{PUBLICIP}[0]
    ${local_public_key} =    Execute Command    cat ~/.ssh/id_dsa.pub | awk '{print $2}'
    ${public_key} =    Get Local Public Key Content
    Should Contain    ${public_key}    ${local_public_key}

Verify the public key by remote access
    [Documentation]    Testlink ID:
    ...    Sc-664:Verify the public key by remote access
    [Tags]    FAST
    Switch Connection    ${DUMMYRRSIP}
    Execute Command Successfully    ssh-keygen -f "/root/.ssh/known_hosts" -R @{PUBLICIP}[0]
    Wait Until Keyword Succeeds    3x    2s    SSH Output Should Be Equal    ssh @{PUBLICIP}[0] "echo 'Test RRS Key'"    Test RRS Key

Delete select public key(s)
    [Documentation]    Testlink ID:
    ...     Sc-662:Delete select public key(s)
    [Tags]    FAST
    Switch Connection    ${DUMMYRRSIP}
    ${name_raw} =    Execute Command    cat ~/.ssh/id_dsa.pub | awk '{print $NF}'
    ${name_url} =    Evaluate    '${name_raw}'.replace('@','%40')
    Delete Remote SSH Key    ${name_url}
    Remote Public Key Should Be Empty
    Sleep    5
    ${rc}=    Execute Command    ssh @{PUBLICIP}[0] "echo 'Test RRS Key'"    return_stdout=False    return_rc=True
    Should Be Equal As Integers    ${rc}    255

*** Keywords ***
Add Remote SSH Key
    [Arguments]    ${name}    ${content}
    Return Code Should Be 0    /cgi-bin/ezs3/json/add_replication_key?name=${name}%0A&content=${content}

Delete Remote SSH Key
    [Arguments]    ${name}
    Return Code Should Be 0    /cgi-bin/ezs3/json/delete_multi_replication_key?name_list=${name}
    
Get Local Public Key Content
    ${ret} =    Get Json Path Value    /cgi-bin/ezs3/json/ssh_pubkey_get    /response/content
    [Return]    ${ret}

Remote Public Key Should Be Empty
    ${ret} =    Get Json Path Value    /cgi-bin/ezs3/json/list_replication_key    /response/keys/key
    Should Be Equal    ${ret}    []
