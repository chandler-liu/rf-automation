*** Settings ***
Documentation     This suite includes cases related to general cases about Login with SDS admin account
Suite Setup       Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
Resource          ../00_commonconfig.txt
Resource          ../00_commonkeyword.txt
Resource          00_accountkeywords.txt

*** Test Cases ***
Limited access and management
    [Documentation]    Testlink ID: Sc-73:Limited access and management
    [Tags]    RAT
    log    Create a user
    ${user_name}    Evaluate    ''.join([random.choice(string.ascii_lowercase) for i in xrange(6)])    string, random
    Return Code Should be    /cgi-bin/ezs3/json/add_user?user_id=${user_name}&display_name=${user_name}&email=${user_name}%40qq.com&password=1&confirm_password=1&type=&dn=    0
    log    Set the use as SDSADMIN
    SDS Admin Add    ${user_name}    Default
    log    Log in use ADS admin account
    Return Code Should be    /cgi-bin/ezs3/json/login?user_id=${user_name}&password=1    0
    log    Log in with admin, to delete created user
    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
    log    Remove user form SDSAdmin
    SDS Admin Remove    ${user_name}
    log    Delete user
    Delete User    ${user_name}

Delete user that in SDS admin, then login
    [Documentation]    Testlink ID: Sc-79:Delete user that in SDS admin, then login
    [Tags]    FAST
    log    Create a user
    ${user_name}    Evaluate    ''.join([random.choice(string.ascii_lowercase) for i in xrange(6)])    string, random
    Return Code Should be    /cgi-bin/ezs3/json/add_user?user_id=${user_name}&display_name=${user_name}&email=${user_name}%40qq.com&password=1&confirm_password=1&type=&dn=    0
    log    Set the use as SDSADMIN
    SDS Admin Add    ${user_name}    Default
    log    Log in use ADS admin account
    Return Code Should be    /cgi-bin/ezs3/json/login?user_id=${user_name}&password=1    0
    log    Log in with admin, edit the user is not a SDS Admin
    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
    log    Remove user form SDSAdmin
    SDS Admin Remove    ${user_name}
    log    Use this user login UI again, now it's not a SDS Admin user
    Return Code Should be    /cgi-bin/ezs3/json/login?user_id=${user_name}&password=1    300
    log    Delete user
    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
    Delete User    ${user_name}
