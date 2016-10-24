*** Settings ***
Resource          ../00_commonconfig.txt
Resource          ../00_commonkeyword.txt
Resource          00_accountkeywords.txt

*** Test Cases ***
Add valid user
    [Documentation]    Testlink ID: Sc-48:Create new user
    [Tags]    RAT
    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
    ${user_name}    Evaluate    ''.join([random.choice(string.ascii_lowercase) for i in xrange(6)])    string, random
    Return Code Should be    /cgi-bin/ezs3/json/add_user?user_id=${user_name}&display_name=${user_name}&email=${user_name}%40qq.com&password=1&confirm_password=1&type=&dn=    0
    Delete User    ${user_name}

Disable and Enable user
    [Documentation]    Testlink ID: Sc-58:Enable users
    [Tags]    FAST
    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
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
    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
    ${user_name}    Evaluate    ''.join([random.choice(string.ascii_lowercase) for i in xrange(6)])    string, random
    Return Code Should be    /cgi-bin/ezs3/json/add_user?user_id=${user_name}&display_name=${user_name}&email=${user_name}%40qq.com&password=1&confirm_password=1&type=&dn=    0
    Delete User    ${user_name}

Enable AD/LDAP
    [Documentation]    Testlink ID: Sc-60:AD/LDAP settings
    [Tags]    FAST
    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
    log    Start to set AD/LDAP
    Return Code Should be    /cgi-bin/ezs3/json/set_ad_settings?enabled=True&server=${ADIP}&port=389&base_dn=DC%3Dhype%2CDC%3Dcom&use_https=False&search_dn=CN%3Dusers%2CDC%3Dhype%2CDC%3Dcom&ad_account=hype%5CAdministrator&ad_password=${ADPASS}    0

Import user from AD/LDAP
    [Documentation]    Testlink ID: Sc-61:Import user from AD/LDAP
    [Tags]    FAST
    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
    log    Start to set AD/LDAP
    Return Code Should be    /cgi-bin/ezs3/json/set_ad_settings?enabled=True&server=${ADIP}&port=389&base_dn=DC%3Dhype%2CDC%3Dcom&use_https=False&search_dn=CN%3Dusers%2CDC%3Dhype%2CDC%3Dcom&ad_account=hype%5CAdministrator&ad_password=${ADPASS}    0
    Return Code Should be    /cgi-bin/ezs3/json/add_user?user_id=zhangsan&display_name=%E5%BC%A0%E4%B8%89&email=&password=&confirm_password=&type=AD&dn=CN%3D%E5%BC%A0%E4%B8%89%2CCN%3DUsers%2CDC%3Dhype%2CDC%3Dcom    0
