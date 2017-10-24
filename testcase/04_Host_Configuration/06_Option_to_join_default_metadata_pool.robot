*** Settings ***
Documentation     This suite includes cases related to general cases about options to join Default or Metedata pool
Suite Setup       Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
Resource          ../00_commonconfig.txt
#Resource          ../00_commonkeyword.txt
Resource          00_hostconfigurationkeywords.txt
Resource          ../keyword/keyword_verify.txt
Resource          ../keyword/keyword_system.txt
Resource          ../keyword/keyword_cgi.txt


*** Variables ***
${osd_name}       osd_join_pool_meta
${data_dev}    /dev/sdc
${pool_type}    1
${pool_name}    common-pool-test
@{node_ids}    0    1    2

*** Test Cases ***
The pool information in a drop-down box
    [Documentation]    Testlink ID: Sc-98:The pool information in a drop-down box
    [Tags]    FAST
    Create a common pool
    Delete The Pool

OSD join newly created pool
    [Documentation]    Testlink ID: Sc-103:OSD join newly created pool
    [Tags]    FAST
    Create a common pool
    Join OSD in newly created pool
    Delete The Pool

OSD join metadata pool
    [Documentation]    Testlink ID: Sc-101:OSD join metadata pool
    [Tags]    FAST
    Create a Volume
    Enable the OSD join none&metadata   
    [Teardown]    Remove OSD    @{STORAGEIP}[0]    ${osd_name}    

*** Keywords ***
Create a common pool
    Run Keyword    Create Pool    pool_name=${pool_name}    pool_type=${pool_type}
    Wait Until Keyword Succeeds    4 min    5 sec    Check Pool Exist UI    ${pool_name}
    
Delete The Pool
    Run Keyword    Delete Pool    pool_name=${pool_name}
    Wait Until Keyword Succeeds    4 min    5 sec    Check Pool Nonexist UI    ${pool_name}

Join OSD in newly created pool
    Run Keyword    Add Node To Pool    ${pool_name}    @{node_ids}
    Wait Until Keyword Succeeds    4 min    5 sec    Check Pool UI Contain Node    ${pool_name}    @{node_ids}

Create a Volume
    Run Keyword    Create Volume    storage_ip=@{STORAGEIP}[0]    osd_name=${osd_name}   fsType=ext4    osdEngineType=FileStore    data_dev=${data_dev}

Enable the OSD join none&metadata
    Run Keyword    Enable OSD    public_ip=@{PUBLICIP}[0]    storage_ip=@{STORAGEIP}[0]    osd_name=${osd_name}    pool_to_join=none    add_metadata_pool=true
    Wait Until Keyword Succeeds    4 min    5 sec    Check Role Status    @{STORAGEIP}[0]    role=osd    status=enabled
