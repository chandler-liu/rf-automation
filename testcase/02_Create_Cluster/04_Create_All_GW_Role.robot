*** Settings ***
Documentation     Initial Gateway Role
Suite Setup       Network Setup
Suite Teardown    Network Teardown
Resource          ../00_commonconfig.txt
Resource          ../keyword/keyword_verify.txt
Resource          ../keyword/keyword_system.txt
Resource          ../keyword/keyword_cgi.txt


*** Variables ***


*** Test Cases ***
Create All GW Role
    [Tags]    Initial
    Enable All MDS Role    num_nodes=${CLUSTERNODES}
    Enable All GW Role    num_nodes=${CLUSTERNODES}


*** Keywords ***
Enable All GW Role
    [Arguments]     ${num_nodes}
    : FOR    ${i}    IN RANGE    ${num_nodes}
    \    Run Keyword    Enable Gateway     public_ip=@{PUBLICIP}[${i}]    storage_ip=@{STORAGEIP}[${i}]
    \    Wait Until Keyword Succeeds    3 min    5 sec    Check Role Status    @{STORAGEIP}[${i}]    role=gw    status=enabled
    Wait Until Keyword Succeeds    4 min    5 sec    Check CTDB Status    num_nodes=${num_nodes}

Enable All MDS Role
    [Arguments]     ${num_nodes}
    : FOR    ${i}    IN RANGE    ${num_nodes}
    \    Run Keyword    CGI MDS Role Enable     ip=@{STORAGEIP}[${i}]
    \    Wait Until Keyword Succeeds    30 sec    5 sec    Check Role Status    @{STORAGEIP}[${i}]    role=mds    status=enabled


