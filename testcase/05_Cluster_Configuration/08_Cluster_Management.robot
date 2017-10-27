*** Settings ***
Documentation     This suite includes cases related to Cluster Managerment
Suite Setup       Run Keywords    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
...               AND    Open All SSH Connections    ${USERNAME}    ${PASSWORD}    @{PUBLICIP}
...               AND    Switch Connection    @{PUBLICIP}[0]
Suite Teardown    Close All Connections
Resource          ../00_commonconfig.txt
Resource          ../00_commonkeyword.txt
Resource          00_clusterconfigurationkeywords.txt

*** Variables ***
${data_dev}     /dev/sdc
${osd_name}    incremental-test

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
	Get OSD Reweight Increase
	[Teardown]    Cluster Disable Incremental Recovery
	...    AND    Remove OSD    @{STORAGEIP}[0]    ${osd_name}

Incremental recovery in case OSD out
    [Documentation]    TestLink ID: Sc-362:Incremental recovery in case OSD out
    [Tags]    FAST
	Add OSD & Join Default pool
	Wait Cluster Status Is Health_OK
	Cluster Enable Incremental Recovery
	Disable The OSD
	Get OSD Reweight Diminishing
	[Teardown]    Cluster Disable Incremental Recovery
	...    AND    Remove OSD    @{STORAGEIP}[0]    ${osd_name}

Incremental recovery in case OSD down and up
    [Documentation]    TestLink ID: Sc-363:Incremental recovery in case OSD down and up
    [Tags]    FAST
	Cluster Enable Incremental Recovery
	Stop OSD & Start OSD Check Reweight Change
	[Teardown]    Cluster Disable Incremental Recovery
	...    AND    Delete Shared Folder    gateway_group=Default    names=    Create List    incremental_folder
    ...    AND    SSH Output Should Contain    /etc/init.d/ceph start osd.0    Starting Ceph osd.0
	
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
	
Disable The OSD
	Run Keyword    Disable OSD    storage_ip=@{STORAGEIP}[0]    osd_name=${osd_name}
    Wait Until Keyword Succeeds    4 min    5 sec    Check Role Status Is Not   @{STORAGEIP}[0]    role=osd    status=stoping
	
Stop OSD & Start OSD Check Reweight Change
	Run Keyword    Down Up Reweight Change    incremental_folder    Default
	
	

	
*** Test Cases ***
Enable/Disable Maintenance Mode
    [Documentation]    TestLink ID: Sc-360:Enable/Disable Maintenance Mode
    [Tags]    FAST
    Enable Disable Maintenance Mode    True
    [Teardown]    Enable Disable Maintenance Mode    False

Incremental recovery in case OSD in
    [Documentation]    TestLink ID: Sc-361:Incremental recovery in case OSD in
    [Tags]    FAST
    ${osd_name}=    Set Variable    osd-incremental-test
    log    Enable Incremental recovery
    Incremental Recovery    True
    log    Add OSD,and join Default pool
    Create OSD    ${osd_name}
    log    Check incremental recovery work results
    Get OSD Reweight
    [Teardown]    Run Keywords    Incremental Recovery    False
    ...    AND    Disable and Delete OSD    @{STORAGEIP}[0]    ${osd_name}

Incremental recovery in case OSD out
    [Documentation]    TestLink ID: Sc-362:Incremental recovery in case OSD out
    [Tags]    FAST
    ${osd_name}=    Set Variable    osd-incremental-test
    log    Add OSD,and join Default pool
    Create OSD    ${osd_name}
    log    Wait cluster status is Health_OK
    Wait Until Keyword Succeeds    6 min    5 sec    Get Cluster Health Status
    log    Enable Incremental recovery
    Incremental Recovery    True
    log    Check incremental recovery work results, first, delete OSD
    Disable OSD    @{STORAGEIP}[0]    ${osd_name}
    Get OSD Reweight    default    False
    [Teardown]    Run Keywords    Incremental Recovery    False
    ...    AND    Delete OSD    @{STORAGEIP}[0]    ${osd_name}

Incremental recovery in case OSD down and up
    [Documentation]    TestLink ID: Sc-363:Incremental recovery in case OSD down and up
    [Tags]    FAST
    ${folder_name}=    Set Variable    incremental_folder
    ${vs_name}=    Set Variable    Default
    log    Start enable incremental rcovery
    Incremental Recovery    True
    log    Stop OSD at backend
    Wait Until Keyword Succeeds    3 min    5 sec    SSH Output Should Contain    /etc/init.d/ceph stop osd.0    Exit Code: 0x00
    log    Create share folder and input data to this folder
    Add Shared Folder    name=${folder_name}    gateway_group=${vs_name}    pool=${vs_name}    nfs=true
    log    Check share folder create result
    Wait Until Keyword Succeeds    2 min    5 sec    SSH Output Should Contain    ls -l /vol    ${folder_name}
    log    Write data to folder of ${folder_name}
    Write    cd /vol/${folder_name}
    Write    dd if=/dev/zero of=/vol/${folder_name}/test.txt bs=1M count=200
    log    type ceph osd dump to get recovery_weight
    ${before_recovery_weight}=    Do SSH CMD    @{PUBLICIP}[0]    ${USERNAME}    ${PASSWORD}    ceph osd dump | grep osd.0 | awk -F " " '{print $7}'
    log    Start OSD
    Wait Until Keyword Succeeds    3 min    5 sec    SSH Output Should Contain    /etc/init.d/ceph start osd.0    /data/osd.0
    log    Check osd status
    Wait Until Keyword Succeeds    3 min    5 sec    SSH Output Should Contain    ceph osd tree | grep osd.0    up
    log    type ceph osd dump again, to get recovery_weight
    ${after_recovery_weight}=    Do SSH CMD    @{PUBLICIP}[0]    ${USERNAME}    ${PASSWORD}    ceph osd dump | grep osd.0 | awk -F " " '{print $7}'
    Should Be True    ${after_recovery_weight}<${before_recovery_weight}
    log    Check incremental rcovery speed
    ${first_get_recovery_weight}=    Do SSH CMD    @{PUBLICIP}[0]    ${USERNAME}    ${PASSWORD}    ceph osd dump | grep osd.0 | awk -F " " '{print $7}'
    sleep    10
    ${second_get_recovery_weight}=    Do SSH CMD    @{PUBLICIP}[0]    ${USERNAME}    ${PASSWORD}    ceph osd dump | grep osd.0 | awk -F " " '{print $7}'
    Should Be True    ${first_get_recovery_weight}<${second_get_recovery_weight}
    Should Be True    ${second_get_recovery_weight}<${before_recovery_weight}
    [Teardown]    Run Keywords    Incremental Recovery    False
    ...    AND    Delete Shared Folder    ${vs_name}    ${folder_name}
    ...    AND    SSH Output Should Contain    /etc/init.d/ceph start osd.0    Starting Ceph osd.0
