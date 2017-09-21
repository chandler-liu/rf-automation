*** Settings ***
Documentation     Initial Cluster
Suite Teardown    Network Teardown
Resource          ../00_commonconfig.txt
Resource          ../keyword/keyword_verify.txt
Resource          ../keyword/keyword_system.txt
Resource          ../keyword/keyword_cgi.txt


*** Variables ***


*** Test Cases ***
Create Cluster
    [Tags]    Initial
    Create New Cluster    mon_num=3
    Input All Nodes License    num_nodes=${CLUSTERNODES}


*** Keywords ***
Input All Nodes License
    [Arguments]     ${num_nodes}
    Wait Until Keyword Succeeds    30 sec    10 sec     Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
    : FOR    ${i}    IN RANGE    ${num_nodes}
    \    Input License    @{STORAGEIP}[${i}]    ${i}

Create New Cluster
    [Arguments]     ${mon_num}
    CGI Create Cluster    mon_num=${mon_num}
    Wait Until Keyword Succeeds    4 min    5 sec    Get Create Cluster Progress


