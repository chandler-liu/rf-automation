*** Settings ***
Documentation     This suite includes cases related to general cases about edit storage volume
Suite Setup       Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
Resource          ../00_commonconfig.txt
#Resource          ../00_commonkeyword.txt
#Resource          00_hostconfigurationkeywords.txt
Resource          ../keyword/keyword_verify.txt
Resource          ../keyword/keyword_system.txt
Resource          ../keyword/keyword_cgi.txt

*** Variables ***
${osd_name}       osd_add_cache_partion
${data_dev}    /dev/sdc
${cache_dev}    /dev/sdd

*** Test Cases ***
Add cache partition
    [Documentation]    Testlink ID: Sc-87:Add cache partition
    [Tags]    RAT
    Create Single partition OSD
    Start to add cache partition
    Check if add cache partition success
    [Teardown]    Delete OSD    @{STORAGEIP}[0]    ${osd_name}

*** Keywords ***
Create Single partition OSD
    Run Keyword    Create Volume    storage_ip=@{STORAGEIP}[0]    osd_name=${osd_name}   fsType=ext4    osdEngineType=FileStore    data_dev=${data_dev}

Start to add cache partition
    Run Keyword    Edit Volume    storage_ip=@{STORAGEIP}[0]    osd_name=${osd_name}    cache_dev=${cache_dev}   

Check if add cache partition success
    Wait Until Keyword Succeeds    4 min    5 sec    Do SSH CMD    @{PUBLICIP}[0]    ${USERNAME}    ${PASSWORD}
    ...    lsblk | grep -i ${osd_name} | wc -l    True    2
    
