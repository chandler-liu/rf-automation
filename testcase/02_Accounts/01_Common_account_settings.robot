*** Settings ***
Documentation     This suite includes cases related to general cases about common account settings
Suite Setup       Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
Resource          ../00_commonconfig.txt
Resource          ../00_commonkeyword.txt
Resource          00_accountkeywords.txt

*** Test Cases ***
Add valid user
    [Documentation]    Testlink ID: Sc-48:Create new user
    [Tags]    RAT
    ${user_name}    Evaluate    ''.join([random.choice(string.ascii_lowercase) for i in xrange(6)])    string, random
    Return Code Should be    /cgi-bin/ezs3/json/add_user?user_id=${user_name}&display_name=${user_name}&email=${user_name}%40qq.com&password=1&confirm_password=1&type=&dn=    0
    Delete User    ${user_name}

Disable and Enable user
    [Documentation]    Testlink ID: Sc-58:Enable users
    [Tags]    FAST
    ${user_name}    Evaluate    ''.join([random.choice(string.ascii_lowercase) for i in xrange(6)])    string, random
    Return Code Should be    /cgi-bin/ezs3/json/add_user?user_id=${user_name}&display_name=${user_name}&email=${user_name}%40qq.com&password=1&confirm_password=1&type=&dn=    0
    log    Start to disable user
    Return Code Should be    /cgi-bin/ezs3/json/suspend_user?user_id=${user_name}    0
    log    Start to enable user
    Return Code Should be    /cgi-bin/ezs3/json/enable_user?user_id=${user_name}    0
    log    Start to delete user
    Delete User    ${user_name}

Delete users
    [Documentation]    Testlink ID: Sc-59:Delete users
    [Tags]    FAST
    ${user_name}    Evaluate    ''.join([random.choice(string.ascii_lowercase) for i in xrange(6)])    string, random
    Return Code Should be    /cgi-bin/ezs3/json/add_user?user_id=${user_name}&display_name=${user_name}&email=${user_name}%40qq.com&password=1&confirm_password=1&type=&dn=    0
    Delete User    ${user_name}

Enable AD/LDAP
    [Documentation]    Testlink ID: Sc-60:AD/LDAP settings
    [Tags]    FAST
    log    Start to set AD/LDAP
    Return Code Should be    /cgi-bin/ezs3/json/set_ad_settings?enabled=True&server=${ADIP}&port=389&base_dn=DC%3Dhype%2CDC%3Dcom&use_https=False&search_dn=CN%3Dusers%2CDC%3Dhype%2CDC%3Dcom&ad_account=hype%5CAdministrator&ad_password=${ADPASS}    0

Import user from AD/LDAP
    [Documentation]    Testlink ID: Sc-61:Import user from AD/LDAP
    [Tags]    FAST
    log    Start to set AD/LDAP
    ${user_name}=    Set Variable    zhangsan
    Return Code Should be    /cgi-bin/ezs3/json/set_ad_settings?enabled=True&server=${ADIP}&port=389&base_dn=DC%3Dhype%2CDC%3Dcom&use_https=False&search_dn=CN%3Dusers%2CDC%3Dhype%2CDC%3Dcom&ad_account=hype%5CAdministrator&ad_password=${ADPASS}    0
    Return Code Should be    /cgi-bin/ezs3/json/add_user?user_id=${user_name}&display_name=%E5%BC%A0%E4%B8%89&email=&password=&confirm_password=&type=AD&dn=CN%3D%E5%BC%A0%E4%B8%89%2CCN%3DUsers%2CDC%3Dhype%2CDC%3Dcom    0
    [Teardown]    Delete User    ${user_name}

Create new user with invalid ID
    [Documentation]    Test LinkID: Sc-49:Create new user with invalid ID
    [Tags]    FET
    log    Create new user with invalid ID
    ${user_name}=    Set Variable    111111
    Return Code Should be    /cgi-bin/ezs3/json/add_user?user_id=${user_name}&display_name=${user_name}&email=${user_name}%40qq.com&password=1&confirm_password=1&type=&dn=    402
    log    "INVALID_USER_ID": 402

Create new user with empty ID
    [Documentation]    Test LinkID: Sc-50:Create new user with empty ID
    [Tags]    FET
    log    Create new user with empty ID
    Return Code Should be    /cgi-bin/ezs3/json/add_user?user_id=&display_name=${user_name}&email=${user_name}%40qq.com&password=1&confirm_password=1&type=&dn=    5
    log    "USER_ID_TOO_SHORT": 5

Create new user with empty display name.
    [Documentation]    Test LinkID: Sc-51:Create new user with empty display name.
    [Tags]    FET
    log    Create new user with empty display name.
    ${user_name}    Evaluate    ''.join([random.choice(string.ascii_lowercase) for i in xrange(6)])    string, random
    Return Code Should be    /cgi-bin/ezs3/json/add_user?user_id=${user_name}&display_name=&email=${user_name}%40qq.com&password=1&confirm_password=1&type=&dn=    10000
    log    "GENERAL_ERROR": 10000
