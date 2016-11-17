*** Settings ***
Documentation     This suite includes cases related to SNMP configuration
Suite Setup       Run Keywords    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
...               AND    Open All SSH Connections    ${USERNAME}    ${PASSWORD}    @{PUBLICIP}
...               AND    Switch Connection    @{PUBLICIP}[0]
Suite Teardown    Close All Connections
Resource          ../00_commonconfig.txt
Resource          ../00_commonkeyword.txt
Resource          00_clusterconfigurationkeywords.txt

*** Test Cases ***
Turn on SNMP configuration
    [Documentation]    TestLink ID: Sc-376:Turn on SNMP configuration
    [Tags]    FAST
    Set SNMP    true    nanjing    admin    public
    log    Check /etc/snmp/snmpd.conf
    Wait Until Keyword Succeeds    2 min    5 sec    SSH Output Should Contain    cat /etc/snmp/snmpd.conf    nanjing
    Wait Until Keyword Succeeds    2 min    5 sec    SSH Output Should Contain    cat /etc/snmp/snmpd.conf    admin
    Wait Until Keyword Succeeds    2 min    5 sec    SSH Output Should Contain    cat /etc/snmp/snmpd.conf    public

Modify SNMP configuration
    [Documentation]    TestLink ID: Sc-377:Modify SNMP configuration
    [Tags]    FAST
    Set SNMP    true    nanjing-2    admin-2    public-2
    log    Check /etc/snmp/snmpd.conf
    Wait Until Keyword Succeeds    2 min    5 sec    SSH Output Should Contain    cat /etc/snmp/snmpd.conf    nanjing-2
    Wait Until Keyword Succeeds    2 min    5 sec    SSH Output Should Contain    cat /etc/snmp/snmpd.conf    admin-2
    Wait Until Keyword Succeeds    2 min    5 sec    SSH Output Should Contain    cat /etc/snmp/snmpd.conf    public-2

Turn off SNMP configuration
    [Documentation]    TestLink ID: Sc-378:Turn off SNMP configuration
    [Tags]    FAST
    Set SNMP    false    nanjing    admin    publi

Add IP for allowed list
    [Documentation]    TestLink ID: Sc-376:Turn on SNMP configuration
    [Tags]    FAST
    Set SNMP    true    nanjing    admin    public
    log    Check /etc/snmp/snmpd.conf
    Wait Until Keyword Succeeds    2 min    5 sec    SSH Output Should Contain    cat /etc/snmp/snmpd.conf    nanjing
    Wait Until Keyword Succeeds    2 min    5 sec    SSH Output Should Contain    cat /etc/snmp/snmpd.conf    admin
    Wait Until Keyword Succeeds    2 min    5 sec    SSH Output Should Contain    cat /etc/snmp/snmpd.conf    public
    Wait Until Keyword Succeeds    2 min    5 sec    SSH Output Should Not Contain    cat /etc/snmp/snmpd.conf    @{PUBLICIP}[-1]
    log    Not set NMS's IP, try to get snmp info from the NMS
    Wait Until Keyword Succeeds    2 min    5 sec    SSH Output Should Contain    snmpget -v 2c -c public @{PUBLICIP}[0] .2.25.31690.11968.43142.4581.44107.2.42453.50459.1    25.31690.11968.43142.4581.44107.2.42453.50459.1
    log    Start to set NMS's IP
    Set SNMP    true    nanjing    admin    public    @{PUBLICIP}[-1]
    log    Check /etc/snmp/snmpd.conf
    Wait Until Keyword Succeeds    2 min    5 sec    SSH Output Should Contain    cat /etc/snmp/snmpd.conf    @{PUBLICIP}[-1]
    log    Try to get snmp info from NMS
    Switch Connection    @{PUBLICIP}[1]
    Wait Until Keyword Succeeds    2 min    5 sec    SSH Output Should Not Contain    snmpget -v 2c -c public @{PUBLICIP}[0] .2.25.31690.11968.43142.4581.44107.2.42453.50459.1    25.31690.11968.43142.4581.44107.2.42453.50459.1
    Switch Connection    @{PUBLICIP}[-1]
    Wait Until Keyword Succeeds    2 min    5 sec    SSH Output Should Contain    snmpget -v 2c -c public @{PUBLICIP}[0] .2.25.31690.11968.43142.4581.44107.2.42453.50459.1    25.31690.11968.43142.4581.44107.2.42453.50459.1
    log    Get snmp info from NMS success

Remove IP for allowed list
    [Documentation]    TestLink ID: Sc-382:Remove IP for allowed list
    [Tags]    FAST
    Set SNMP    true    nanjing    admin    public    @{PUBLICIP}[-1]
    log    Check /etc/snmp/snmpd.conf
    Wait Until Keyword Succeeds    2 min    5 sec    SSH Output Should Contain    cat /etc/snmp/snmpd.conf    nanjing
    Wait Until Keyword Succeeds    2 min    5 sec    SSH Output Should Contain    cat /etc/snmp/snmpd.conf    admin
    Wait Until Keyword Succeeds    2 min    5 sec    SSH Output Should Contain    cat /etc/snmp/snmpd.conf    public
    Wait Until Keyword Succeeds    2 min    5 sec    SSH Output Should Contain    cat /etc/snmp/snmpd.conf    @{PUBLICIP}[-1]
    log    Now we have set the NMS's IP, try to get snmp info from the NMS
    Switch Connection    @{PUBLICIP}[1]
    Wait Until Keyword Succeeds    2 min    5 sec    SSH Output Should Not Contain    snmpget -v 2c -c public @{PUBLICIP}[0] .2.25.31690.11968.43142.4581.44107.2.42453.50459.1    25.31690.11968.43142.4581.44107.2.42453.50459.1
    Switch Connection    @{PUBLICIP}[-1]
    Wait Until Keyword Succeeds    2 min    5 sec    SSH Output Should Contain    snmpget -v 2c -c public @{PUBLICIP}[0] .2.25.31690.11968.43142.4581.44107.2.42453.50459.1    25.31690.11968.43142.4581.44107.2.42453.50459.1
    log    Start to delete NMS's IP
    Set SNMP    true    nanjing    admin    public
    log    Check /etc/snmp/snmpd.conf
    Wait Until Keyword Succeeds    2 min    5 sec    SSH Output Should Not Contain    cat /etc/snmp/snmpd.conf    @{PUBLICIP}[-1]
    log    Try to get snmp info from NMS
    Switch Connection    @{PUBLICIP}[1]
    Wait Until Keyword Succeeds    2 min    5 sec    SSH Output Should Contain    snmpget -v 2c -c public @{PUBLICIP}[0] .2.25.31690.11968.43142.4581.44107.2.42453.50459.1    25.31690.11968.43142.4581.44107.2.42453.50459.1
    Switch Connection    @{PUBLICIP}[-1]
    Wait Until Keyword Succeeds    2 min    5 sec    SSH Output Should Contain    snmpget -v 2c -c public @{PUBLICIP}[0] .2.25.31690.11968.43142.4581.44107.2.42453.50459.1    25.31690.11968.43142.4581.44107.2.42453.50459.1

Check cluster name in SNMP response
    [Documentation]    TestLink ID: \ Sc-386:Check cluster name in SNMP response
    [Tags]    FAST
    Set SNMP    true    nanjing    admin    public
    log    Check /etc/snmp/snmpd.conf
    Wait Until Keyword Succeeds    2 min    5 sec    SSH Output Should Contain    cat /etc/snmp/snmpd.conf    nanjing
    Wait Until Keyword Succeeds    2 min    5 sec    SSH Output Should Contain    cat /etc/snmp/snmpd.conf    admin
    Wait Until Keyword Succeeds    2 min    5 sec    SSH Output Should Contain    cat /etc/snmp/snmpd.conf    public
    Wait Until Keyword Succeeds    2 min    5 sec    SSH Output Should Not Contain    cat /etc/snmp/snmpd.conf    @{PUBLICIP}[-1]
    log    Not set NMS's IP, try to get snmp info from the NMS
    Wait Until Keyword Succeeds    2 min    5 sec    SSH Output Should Contain    snmpget -v 2c -c public @{PUBLICIP}[0] .2.25.31690.11968.43142.4581.44107.2.42453.50459.1    25.31690.11968.43142.4581.44107.2.42453.50459.1
    log    Start to set NMS's IP
    Set SNMP    true    nanjing    admin    public    @{PUBLICIP}[-1]
    log    Check /etc/snmp/snmpd.conf
    Wait Until Keyword Succeeds    2 min    5 sec    SSH Output Should Contain    cat /etc/snmp/snmpd.conf    @{PUBLICIP}[-1]
    log    Try to get snmp info from NMS
    Switch Connection    @{PUBLICIP}[-1]
    Wait Until Keyword Succeeds    2 min    5 sec    SSH Output Should Contain    snmpget -v 2c -c public @{PUBLICIP}[0] .2.25.31690.11968.43142.4581.44107.2.42453.50459.1    AutoTest
    log    Get cluster name success
