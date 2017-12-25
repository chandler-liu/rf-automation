*** Settings ***
Documentation     This suite includes cases related to Cluster Managerment
Suite Setup       Run Keywords    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
...               AND    Open All SSH Connections    ${USERNAME}    ${PASSWORD}    @{PUBLICIP}
...               AND    Switch Connection    @{PUBLICIP}[0]
Suite Teardown    Close All Connections
Resource          ../00_commonconfig.txt
Resource          ../keyword/keyword_verify.txt
Resource          ../keyword/keyword_system.txt
Resource          ../keyword/keyword_cgi.txt

*** Variables ***
${data_dev}     /dev/sdc
${osd_name}    incremental-test
${shared_folder_name}    incremental_folder

*** Test Cases ***
Enable/Disable Maintenance Mode
    [Documentation]    TestLink ID: Sc-360:Enable/Disable Maintenance Mode
    [Tags]    FAST
    Cluster Enable Maintenance Mode
    [Teardown]    Cluster Disable Maintenance Mode

Incremental Recovery In Case OSD In
    [Documentation]    TestLink ID: Sc-361:Incremental recovery in case OSD in
    [Tags]    FAST
    Cluster Enable Incremental Recovery
    Add OSD & Join Default pool
    Get OSD Reweight Increasing
    [Teardown]    Run Keywords    Cluster Disable Incremental Recovery
    ...    AND    Remove OSD    @{STORAGEIP}[0]    ${osd_name}

Incremental recovery in case OSD out
    [Documentation]    TestLink ID: Sc-362:Incremental recovery in case OSD out
    [Tags]    FAST
    Add OSD & Join Default pool
    Wait Cluster Status Is Health_OK
    Cluster Enable Incremental Recovery
    Disable The OSD Gracefully
    Get OSD Reweight Diminishing
    [Teardown]    Run Keywords    Cluster Disable Incremental Recovery
    ...    AND    Remove OSD    @{STORAGEIP}[0]    ${osd_name}

Incremental recovery in case OSD down and up
    [Documentation]    TestLink ID: Sc-363:Incremental recovery in case OSD down and up
    [Tags]    FAST
    Cluster Enable Incremental Recovery
    Stop OSD & Start OSD Check Reweight Change
    [Teardown]    Run Keywords    Cluster Disable Incremental Recovery
    ...    AND    Delete Shared Folder    gateway_group=Default    name=${shared_folder_name}
    ...    AND    Run Keyword If Test Failed    SSH Output Should Contain    /etc/init.d/ceph start osd.0    Starting Ceph osd.0
    ...    AND    Wait Until Keyword Succeeds    4 min    5 sec    Check Cluster Health

*** Keywords ***
Cluster Enable Maintenance Mode
    Run Keyword    Enable Maintenance Mode

Cluster Disable Maintenance Mode
    Run Keyword    Disable Maintenance Mode

Cluster Enable Incremental Recovery
    Run Keyword    Enable Incremental Recovery

Cluster Disable Incremental Recovery
    Run Keyword    Disable Incremental Recovery

Add OSD & Join Default pool
    Run Keyword    Create OSD and Volume     public_ip=@{PUBLICIP}[0]    storage_ip=@{STORAGEIP}[0]    osd_name=${osd_name}   fsType=ext4    osdEngineType=FileStore    data_dev=${data_dev}
    Wait Until Keyword Succeeds    4 min    5 sec    Check Role Status    @{STORAGEIP}[0]    role=osd    status=enabled

Get OSD Reweight Increasing
    Get OSD Reweight    default    increasing

Get OSD Reweight Diminishing
    Get OSD Reweight    default    diminishing

Wait Cluster Status Is Health_OK
    Wait Until Keyword Succeeds    4 min    5 sec    Check Cluster Health

Disable The OSD Gracefully
    Wait Until Keyword Succeeds    4 min    5 sec    Check Cluster Health
    Run Keyword    Disable OSD    storage_ip=@{STORAGEIP}[0]    osd_name=${osd_name}    force=false

Stop OSD & Start OSD Check Reweight Change
    Run Keyword    Down Up Reweight Change    incremental_folder    Default
