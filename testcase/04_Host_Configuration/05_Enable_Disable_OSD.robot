*** Settings ***
Documentation     This suite includes cases related to general cases about enable and disable OSD
Suite Setup       Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
Resource          ../00_commonconfig.txt
#Resource          ../00_commonkeyword.txt
Resource          00_hostconfigurationkeywords.txt
Resource          ../keyword/keyword_verify.txt
Resource          ../keyword/keyword_system.txt
Resource          ../keyword/keyword_cgi.txt


*** Variables ***
${osd_name}       enable_disable_osd
${data_dev}    /dev/sdc

*** Test Cases ***
Enable/Disable OSD
    [Documentation]    Testlink ID: Sc-95:Enable/Disable OSD
    [Tags]    RAT
    Create&Enable OSD
    Disable The OSD
    Enable&Disable The OSD
    [Teardown]    Delete OSD    @{STORAGEIP}[0]    ${osd_name}

*** Keywords ***
Create&Enable OSD
    Run Keyword    Create OSD and Volume     public_ip=@{PUBLICIP}[0]    storage_ip=@{STORAGEIP}[0]    osd_name=${osd_name}   fsType=ext4    osdEngineType=FileStore    data_dev=${data_dev}
    Wait Until Keyword Succeeds    4 min    5 sec    Check Role Status    @{STORAGEIP}[0]    role=osd    status=enabled

Disable The OSD
    Run Keyword    Disable OSD    storage_ip=@{STORAGEIP}[0]    osd_name=${osd_name}
    Wait Until Keyword Succeeds    4 min    5 sec    Check Role Status Is Not   @{STORAGEIP}[0]    role=osd    status=stoping

Enable&Disable The OSD
    Run Keyword    Enable OSD    public_ip=@{PUBLICIP}[0]    storage_ip=@{STORAGEIP}[0]    osd_name=${osd_name}
    Wait Until Keyword Succeeds    4 min    5 sec    Check Role Status    @{STORAGEIP}[0]    role=osd    status=enabled
    Run Keyword    Disable OSD    storage_ip=@{STORAGEIP}[0]    osd_name=${osd_name}
    Wait Until Keyword Succeeds    4 min    5 sec    Check Role Status Is Not   @{STORAGEIP}[0]    role=osd    status=stoping

