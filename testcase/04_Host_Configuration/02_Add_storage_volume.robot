*** Settings ***
Documentation     This suite includes cases related to general cases about add storage volume
Suite Setup       Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
Resource          ../00_commonconfig.txt
#Resource          ../00_commonkeyword.txt
Resource          00_hostconfigurationkeywords.txt
Resource          ../keyword/keyword_verify.txt
Resource          ../keyword/keyword_system.txt
Resource          ../keyword/keyword_cgi.txt

*** Variables ***
${osd_name_single}    osd_single_partition
${osd_name_batch}    osd_batch_partition
@{osd_name_batch_list}    g-osd_batch_partition-0    g-osd_batch_partition-1
${data_dev}     /dev/sdc
@{data_devs_batch}      /dev/sdd    /dev/sde

*** Test Cases ***
Single partition
    [Documentation]    Testlink ID: Sc-80:Single partition
    [Tags]    RAT
    Enable Single partition OSD 
    Disable Single partition OSD
    Delete Single partition OSD
#    [Teardown]    Remove OSD    @{STORAGEIP}[0]    ${osd_name_single}  

Batch partition
    [Documentation]    Testlink ID: Sc-81:Batch partition
    [Tags]    RAT
    Enable Batch partition OSD
    Disable Batch partition OSD
    Delete Batch partition OSD
#    [Teardown]    Remove OSD    @{STORAGEIP}[0]    g-${osd_name_batch}-0+g-${osd_name_batch}-1  

*** Keywords ***
Enable Single partition OSD
    Run Keyword    Create OSD and Volume     public_ip=@{PUBLICIP}[0]    storage_ip=@{STORAGEIP}[0]    osd_name=${osd_name_single}   fsType=ext4    osdEngineType=FileStore    data_dev=${data_dev}
    Wait Until Keyword Succeeds    4 min    5 sec    Check Role Status    @{STORAGEIP}[0]    role=osd    status=enabled

Disable Single partition OSD
    Run Keyword    Disable OSD    storage_ip=@{STORAGEIP}[0]    osd_name=${osd_name_single}
    Wait Until Keyword Succeeds    4 min    5 sec    Check Role Status Is Not   @{STORAGEIP}[0]    role=osd    status=stoping

Delete Single partition OSD
    Run Keyword    Delete OSD    storage_ip=@{STORAGEIP}[0]    osd_name=${osd_name_single}
    Wait Until Keyword Succeeds    4 min    5 sec    Check Storage Volume Nonexist    storage_ip=@{STORAGEIP}[0]    osd_name=${osd_name_single}

Enable Batch partition OSD
    Run Keyword    Create Batch OSD and Volume     public_ip=@{PUBLICIP}[0]    storage_ip=@{STORAGEIP}[0]    osd_name=${osd_name_batch}    fsType=ext4    osdEngineType=FileStore    data_devs=@{data_devs_batch}
    Wait Until Keyword Succeeds    4 min    5 sec    Check Role Status    @{STORAGEIP}[0]    role=osd    status=enabled

Disable Batch partition OSD
    Run Keyword    Disable Batch OSD    storage_ip=@{STORAGEIP}[0]    osd_name=${osd_name_batch}    data_devs=@{data_devs_batch}
    Wait Until Keyword Succeeds    4 min    5 sec    Check Role Status Is Not   @{STORAGEIP}[0]    role=osd    status=stoping

Delete Batch partition OSD
    Run Keyword    Delete Batch OSD    storage_ip=@{STORAGEIP}[0]    osd_name=${osd_name_batch}    data_devs=@{data_devs_batch}
    Wait Until Keyword Succeeds    4 min    5 sec    Check Storage Volume Nonexist    storage_ip=@{STORAGEIP}[0]    osd_name=g-${osd_name_batch}-0
    Wait Until Keyword Succeeds    4 min    5 sec    Check Storage Volume Nonexist    storage_ip=@{STORAGEIP}[0]    osd_name=g-${osd_name_batch}-1
