*** Settings ***
Documentation     This suite includes cases related to Misc Cluster COnfiguration
Suite Setup       Run Keywords    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
...               AND    Open All SSH Connections    ${USERNAME}    ${PASSWORD}    @{PUBLICIP}
...               AND    Switch Connection    @{PUBLICIP}[0]
Suite Teardown    Close All Connections
Resource          ../00_commonconfig.txt
Resource          ../00_commonkeyword.txt
Resource          00_clusterconfigurationkeywords.txt

*** Test Cases ***
Load balancing
    [Documentation]    TestLink ID: Sc-401:Load balancing
    [Tags]    FAST
    ${host_s3webdav}    Set Variable    autotest
    Set Load Balance    ${DNSIP}    true    ${host_s3webdav}    com
    log    For client to ping this domain, need set this ${DNSIP} as DNS-Server,so we use the last node of cluster as client
    Modify DNS Settings    @{PUBLICIP}[-1]    ${DNSIP}
    log    From client ping this domain name
    ${ping_host_name01}=    Do SSH CMD    @{PUBLICIP}[-1]    ${USERNAME}    ${PASSWORD}    ping -c 1 ${host_s3webdav}.com | grep -i icmp_req | awk -F ":" '{print $1}' | awk -F " " '{print $NF}'
    ${ping_host_name02}=    Do SSH CMD    @{PUBLICIP}[-1]    ${USERNAME}    ${PASSWORD}    ping -c 1 ${host_s3webdav}.com | grep -i icmp_req | awk -F ":" '{print $1}' | awk -F " " '{print $NF}'
    log    ${ping_host_name01} ;${ping_host_name02}
    Should Not Be Equal    ${ping_host_name01}    ${ping_host_name02}
    Rollback DNS Settings    @{PUBLICIP}[-1]    ${DNSIP}
    [Teardown]    Set Load Balance    ${DNSIP}    false

S3 domain name
    [Documentation]    TestLink ID: Sc-407:S3 domain name
    [Tags]    FAST
    ${s3_domain_name}    Set Variable    s3.domain.test
    Set S3 Domain    ${s3_domain_name}
    log    Check s3 domain setting result
    Wait Until Keyword Succeeds    2 min    5 sec    SSH Output Should Contain    rados -p .ezs3 get s3_domain -    ${s3_domain_name}
    [Teardown]    Set S3 Domain    domain_name=
