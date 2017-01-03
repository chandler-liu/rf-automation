*** Settings ***
Documentation     This suite includes cases related to OSD_auto-reweight_settings
Suite Setup       Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
Resource          ../00_commonconfig.txt
Resource          ../00_commonkeyword.txt
Resource          00_clusterconfigurationkeywords.txt

*** Test Cases ***
Check config when turn it on
    [Documentation]    TestLink ID: Sc-316:Check config when turn it on
    [Tags]    FAST
    log    Check Default pool of config when turn on auto-reweight
    Enable OSD Auto-reweight    Default    20

Check config when turn it off
    [Documentation]    TestLink ID: Sc-317:Check config when turn it off
    [Tags]    FAST
    log    Check Default pool of config when turn on auto-reweight
    Enable OSD Auto-reweight    Default    0
