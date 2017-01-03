*** Settings ***
Documentation     This suite includes cases related to PG split
Resource          ../00_commonconfig.txt
Resource          ../00_commonkeyword.txt
Resource          00_clusterconfigurationkeywords.txt

*** Test Cases ***
Enable PG split
    [Documentation]    TestLink ID: Sc-325:Enable PG split
    [Tags]    FAST
    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
    Enable Disable PG Split    True    Default

Diable PG split
    [Documentation]    TestLink ID: Sc-324:Diable PG split
    [Tags]    FAST
    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
    Enable Disable PG Split    False    Default
