*** Settings ***
Resource          ../00_commonconfig.txt
Resource          ../00_commonkeyword.txt
Resource          00_accountkeywords.txt

*** Test Cases ***
Add SDS admin with single virtual storage
    [Documentation]    Testlink ID: Sc-66:Add SDS admin with single virtual storage
    [Tags]    RAT
    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
    log    Create a user
    ${user_name}    Evaluate    ''.join([random.choice(string.ascii_lowercase) for i in xrange(6)])    string, random
    Return Code Should be    /cgi-bin/ezs3/json/add_user?user_id=${user_name}&display_name=${user_name}&email=${user_name}%40qq.com&password=1&confirm_password=1&type=&dn=    0
    log    Set the use as SDSADMIN
    SDS Admin Add    ${user_name}    Default
    Delete User    ${user_name}

Add virtual storage for SDS admin
    [Documentation]    Testlink ID: Sc-66:Add SDS admin with single virtual storage
    [Tags]    FAST
    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
    log    Create a user
    ${user_name}    Evaluate    ''.join([random.choice(string.ascii_lowercase) for i in xrange(6)])    string, random
    Return Code Should be    /cgi-bin/ezs3/json/add_user?user_id=${user_name}&display_name=${user_name}&email=${user_name}%40qq.com&password=1&confirm_password=1&type=&dn=    0
    log    Set the use as SDSADMIN
    SDS Admin Add    ${user_name}    Default
    log    Edit the user, then set it as ADSAdmin again
    SDS Admin Add    ${user_name}    Default
    Delete User    ${user_name}

Remove virtual storage for SDS admin
    [Documentation]    Testlink ID: Sc-66:Add SDS admin with single virtual storage
    [Tags]    FAST
    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
    log    Create a user
    ${user_name}    Evaluate    ''.join([random.choice(string.ascii_lowercase) for i in xrange(6)])    string, random
    Return Code Should be    /cgi-bin/ezs3/json/add_user?user_id=${user_name}&display_name=${user_name}&email=${user_name}%40qq.com&password=1&confirm_password=1&type=&dn=    0
    log    Set the use as SDSADMIN
    SDS Admin Add    ${user_name}    Default
    log    Remove virtual storage for SDSAdmin
    SDS Admin Edit    ${user_name}
    log    Delete user
    Delete User    ${user_name}

Remove single SDS admin account
    [Documentation]    Testlink ID: Sc-66:Add SDS admin with single virtual storage
    [Tags]    FAST
    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
    log    Create a user
    ${user_name}    Evaluate    ''.join([random.choice(string.ascii_lowercase) for i in xrange(6)])    string, random
    Return Code Should be    /cgi-bin/ezs3/json/add_user?user_id=${user_name}&display_name=${user_name}&email=${user_name}%40qq.com&password=1&confirm_password=1&type=&dn=    0
    log    Set the use as SDSADMIN
    SDS Admin Add    ${user_name}    Default
    log    Remove user form SDSAdmin
    SDS Admin Remove    ${user_name}
    log    Delete user
    Delete User    ${user_name}
