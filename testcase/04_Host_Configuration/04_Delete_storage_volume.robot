*** Settings ***
Documentation     This suite includes cases related to general cases about delete storage volume
Suite Setup       Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
Resource          ../00_commonconfig.txt
#Resource          ../00_commonkeyword.txt
Resource          00_hostconfigurationkeywords.txt
Resource          ../keyword/keyword_verify.txt
Resource          ../keyword/keyword_system.txt
Resource          ../keyword/keyword_cgi.txt


*** Variables ***
${osd_name}       osd_will_be_deleted
${data_dev}    /dev/sdc

*** Test Cases ***
Delete volume when OSD disabled
    [Documentation]    Testlink ID: Sc-93:Delete volume when OSD disabled
    [Tags]    RAT
    Create&Enable OSD
    Disable The OSD
    Delete The OSD    

*** Keywords ***
Create&Enable OSD
    Run Keyword    Create OSD and Volume     public_ip=@{PUBLICIP}[0]    storage_ip=@{STORAGEIP}[0]    osd_name=${osd_name}   fsType=ext4    osdEngineType=FileStore    data_dev=${data_dev}
    Wait Until Keyword Succeeds    4 min    5 sec    Check Role Status    @{STORAGEIP}[0]    role=osd    status=enabled

Disable The OSD
    Run Keyword    Disable OSD    storage_ip=@{STORAGEIP}[0]    osd_name=${osd_name}
    Wait Until Keyword Succeeds    4 min    5 sec    Check Role Status Is Not   @{STORAGEIP}[0]    role=osd    status=stoping

Delete The OSD
    Run Keyword    Delete OSD    storage_ip=@{STORAGEIP}[0]    osd_name=${osd_name}
    Wait Until Keyword Succeeds    4 min    5 sec    Check Storage Volume Nonexist    storage_ip=@{STORAGEIP}[0]    osd_name=${osd_name}

