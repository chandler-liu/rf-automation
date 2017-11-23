*** Settings ***
Documentation     This suite includes cases related to general cases about repair storage volume
Suite Setup       Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
Resource          ../00_commonconfig.txt
Resource          ../keyword/keyword_verify.txt
Resource          ../keyword/keyword_system.txt
Resource          ../keyword/keyword_cgi.txt

*** Variables ***
${osd_name}       osd_1

*** Test Cases ***
scan/fix storage volumes
    [Documentation]    TestLink ID: Sc-111 scan/fix storage volumes
    [Tags]    TOFT
    Select&Repair OSD select Scan

reformat storage volumes
    [Documentation]    TestLink ID: Sc-112 reformat storage volumes
    [Tags]    TOFT
    Select&Repair OSD select Reformat    
    
*** Keywords ***
Select&Repair OSD select Scan
    Run Keyword    Scan Fix OSD    @{STORAGEIP}[1]    ${osd_name}
    Wait Until Keyword Succeeds    4 min    5 sec    Check OSD State    @{STORAGEIP}[1]    ${osd_name}    ONLINE

Select&Repair OSD select Reformat
    Run Keyword    Reformat OSD    @{STORAGEIP}[1]    ${osd_name}
    Wait Until Keyword Succeeds    4 min    5 sec    Check OSD State    @{STORAGEIP}[1]    ${osd_name}    ONLINE
    Wait Until Keyword Succeeds    4 min    5 sec    Check Cluster Health
