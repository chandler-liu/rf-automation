*** Settings ***
Documentation     This suite includes cases related to general cases about iSCSI configuration
Suite Setup       Run Keywords    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
...               AND    Open All SSH Connections    ${USERNAME}    ${PASSWORD}    @{PUBLICIP}
...               AND    Open Connection    127.0.0.1    alias=127.0.0.1
...               AND    Login    ${LOCALUSER}    ${LOCALPASS}
Suite Teardown    Close All Connections    # Close SSH connections
Library           OperatingSystem
Library           SSHLibrary
Library           HttpLibrary.HTTP
Library           ./JsonParser.py
Resource          ../00_commonconfig.txt
Resource          ../00_commonkeyword.txt
Resource          00_virtual_storage_keyword.txt

*** Variables ***
${vs_name}           Default
${default_pool}      Default
${gateway_group}     Default
${iscsi_target_name}                iqn.2016-01.bigtera.com:auto
${iscsi_target_name_urlencoding}    iqn.2016-01.bigtera.com%3Aauto
${iscsi_group01}                    iSCSI_Initiator_Group_01
${iscsi_group02}                    iSCSI_Initiator_Group_02
${iscsi_group03}                    iSCSI_Initiator_Group_03
${fc_group01}                       FC_Initiator_Group_01
${fc_group02}                       FC_Initiator_Group_02
#${iscsi_initiator_name}             [{"name":"iqn.2022-12.com.bigtera:01:1234567890ab","alias":"robot test"}]
#@{iscsi_initiator_name}             {"name":"iqn.2022-12.com.bigtera:01:1234567890ab","alias":"robot test"}
&{iscsi_initiator_name_dict}        name=iqn.2022-12.com.bigtera:01:1234567890ab    alias=robot test
@{iscsi_initiator_name_list}        &{iscsi_initiator_name_dict}
${iscsi_volume_name}                lun1
${iscsi_volume_size}                5368709120    # 5G
${read_maxbw_M}                     5
${read_maxbw_bytes}                 5242750
${read_maxiops}                     50
${write_maxbw_M}                    5
${write_maxbw_bytes}                5242750
${write_maxiops}                    50
#Global Variables

*** Test Cases ***
Create Test Environment
    [Documentation]    Prepare Volume Access Control test environment
    Create iSCSI Target

Enable ACL on iSCSI Volume
    [Documentation]    Testlink ID:
    ...    Sc-896:Enable ACL on iSCSI Volume
    [Tags]    RAT
    Create iSCSI Volume and Check ACL Work

Only Listed Client Can Access
    [Documentation]    Testlink ID:
    ...    Sc-549:Only listed client can Access
    [Tags]    FAST
    Listed Client can Access iSCSI Volume
    No Listed Client can not Access iSCSI Volume

Create Initiator Group
    [Documentation]    Testlink ID:
    ...    Sc-851:Create initiator group
    [Tags]    FAST
    Create iSCSI Initiator Group without Initiators
    Create FC Initiator Group without Initiators

Create Initiator Group and Add Initiators At The Same Time
    [Documentation]    Testlink ID:
    ...    Sc-852:Create group and add initiatiors at the same time
    [Tags]    TOFT
    Create iSCSI Initiator Group with Initiators

Delete Null Group after Group Assign to Enable iSCSI Volume
    [Documentation]    Testlink ID:
    ...    Sc-853:Delete null group after group assign to enable iSCSI Volume
    [Tags]    TOFT
    Can Delete Null Group Asigned to Enable iSCSI Volume

Delete Initiator Group after Group Assign to Enable iSCSI Volume
    [Documentation]    Testlink ID:
    ...    Sc-856:Delete initiator group after group assign to enable iSCSI volume
    [Tags]    FAST
    Can Delete Group Asigned to Enable iSCSI Volume

Delete Non-Null Initiator Group after Group Assign to Disabled iSCSI Volume
    [Documentation]    Testlink ID:
    ...    Sc-857:Delete non-null group after group assign to disabled iSCSI volume
    [Tags]    TOFT
    Can Delete Group Asigned to Disabled iSCSI Volume

Delete Null Initiator Group Before Group Assigned
    [Documentation]    Testlink ID:
    ...    Sc-860:Delete null group before group assigned
    [Tags]    TOFT
    Can Delete Null Initiator Group Without Assigned

Delete Non-Null Initiator Group Before Group Assigned
    [Documentation]    Testlink ID:
    ...    Sc-861:Delete non-null group before group assigned
    [Tags]    TOFT
    Can Delete Non-Null Initiator Group Without Assigned

Apply Initiator Group to Enable iSCSI Volume
    [Documentation]    Testlink ID:
    ...    Sc-862:Apply initiator group to enable iSCSI volume
    [Tags]    FAST
    Can Apply Initiator Group to Enable iSCSI Volume
















Destroy Test Environment
    [Documentation]    Destroy Volume Access Control test environment
    Remove iSCSI target

*** Keywords ***
#Do what=================================================================================================================
Create iSCSI Volume and Check ACL Work
    Create iSCSI Volume without ACL
    Enable All Initiators ACL on Volume
    Check iSCIS Volume can Access
    Remove iSCSI Volume

Listed Client can Access iSCSI Volume
    Create iSCSI Volume without ACL
    Enable Special Initiator ACL on Volume
    Check iSCIS Volume can Access
    Remove iSCSI Volume

No Listed Client can not Access iSCSI Volume
    Create iSCSI Volume without ACL
    Enable Dummy Initiator ACL on Volume
    Check iSCIS Volume can not Access
    Remove iSCSI Volume

Create iSCSI Initiator Group without Initiators
    Create Initiator Group    group_name=${iscsi_group01}    protocol=iscsi
    Check Initiator Group Create Successly    group_name=${iscsi_group01}
    Delete All Initiator Group

Create FC Initiator Group without Initiators
    Create Initiator Group    group_name=${fc_group01}    protocol=fc
    Check Initiator Group Create Successly    group_name=${fc_group01}
    Delete All Initiator Group

Create iSCSI Initiator Group with Initiators
    Create Initiator Group    group_name=${iscsi_group01}    protocol=iscsi    initiator_list=${iscsi_initiator_name_list}
    Check Initiator Group Create Successly    group_name=${iscsi_group01}
#   Check Initiator in Initiator Group
    Delete All Initiator Group

Can Delete Null Group Asigned to Enable iSCSI Volume
    Create iSCSI Volume without ACL
    Create Initiator Group    group_name=${iscsi_group01}    protocol=iscsi
    Check Initiator Group Create Successly    group_name=${iscsi_group01}
    Enable Initiator Groups on Volume
#   Check Initiator Group assign Successly
    Delete Selected Initiator Group
#   Check Initiator Group Delete Successly
    Delete All Initiator Group
    Remove iSCSI Volume

Can Delete Null Initiator Group Without Assigned
    Create Initiator Group    group_name=${iscsi_group01}    protocol=iscsi
    Check Initiator Group Create Successly    group_name=${iscsi_group01}
    Delete Selected Initiator Group
#   Check Initiator Group Delete Successly
    Delete All Initiator Group

Can Delete Non-Null Initiator Group Without Assigned
    Create Initiator Group    group_name=${iscsi_group01}    protocol=iscsi
    Check Initiator Group Create Successly    group_name=${iscsi_group01}
    Edit Initiator Group    group_name=${iscsi_group01}    protocol=iscsi    initiator_list=${iscsi_initiator_name_list}
#   Check Initiator in Initiator Group
    Delete Selected Initiator Group
#   Check Initiator Group Delete Successly
    Delete All Initiator Group

Can Delete Group Asigned to Enable iSCSI Volume
    Create iSCSI Volume without ACL
    Create Initiator Group    group_name=${iscsi_group01}    protocol=iscsi
    Check Initiator Group Create Successly    group_name=${iscsi_group01}
    Edit Initiator Group    group_name=${iscsi_group01}    protocol=iscsi    initiator_list=${iscsi_initiator_name_list}
#   Check Initiator in Initiator Group
    Enable Initiator Groups on Volume
#   Check Initiator Group assign Successly
    Delete Selected Initiator Group
#   Check Initiator Group Delete Successly
    Delete All Initiator Group
    Remove iSCSI Volume

Can Delete Group Asigned to Disabled iSCSI Volume
    Create iSCSI Volume without ACL
    Create Initiator Group    group_name=${iscsi_group01}    protocol=iscsi
    Check Initiator Group Create Successly    group_name=${iscsi_group01}
    Edit Initiator Group    group_name=${iscsi_group01}    protocol=iscsi    initiator_list=${iscsi_initiator_name_list}
#   Check Initiator in Initiator Group
    Enable Initiator Groups on Volume
#   Check Initiator Group assign Successly
    Disable iSCSI volume    volume_name=${iscsi_volume_name}
    Delete Selected Initiator Group
#   Check Initiator Group Delete Successly
    Delete All Initiator Group
    Remove iSCSI Volume

Can Apply Initiator Group to Enable iSCSI Volume
    Create iSCSI Volume without ACL
    Create Initiator Group    group_name=${iscsi_group01}    protocol=iscsi
    Check Initiator Group Create Successly    group_name=${iscsi_group01}
    Add Client Initiator to Initiator Group
    Enable Initiator Groups on Volume
#   Check Initiator Group assign Successly
    Delete All Initiator Group
    Remove iSCSI Volume











#############################################################################################################################3
Create iSCSI Volume without ACL
    Create iSCSI Volume    allow_all=false

Enable All Initiators ACL on Volume
    Enable Special ACL on Volume    allow_all=true    volume_name=${iscsi_volume_name}

Enable Special Initiator ACL on Volume
    ${client_initiator_name}=    Get Client Initiator Name
    Enable Special ACL on Volume    allow_all=false    allowed_initiators=${client_initiator_name}    volume_name=${iscsi_volume_name}

Enable Dummy Initiator ACL on Volume
    ${dummy_initiator_name}=    Set Variable    iqn.2014-02.thisisadummy:initiator
    Enable Special ACL on Volume    allow_all=false    allowed_initiators=${dummy_initiator_name}    volume_name=${iscsi_volume_name}

Delete All Initiator Group
    Delete Initiator Group    group_name=all

Enable Initiator Groups on Volume
    Enable ACL Group on Volume    allow_all=false    allowed_initiator_groups=${iscsi_group01}    volume_name=${iscsi_volume_name}

Delete Selected Initiator Group
    Delete Initiator Group    group_name=${iscsi_group01}

Add Client Initiator to Initiator Group
    ${client_initiator_name}=    Get Client Initiator Name
    &{client_initiator_name_dict}=    Create Dictionary    name=${client_initiator_name}    alias=test client
    @{initiator_list}=    Copy List    ${iscsi_initiator_name_list}
    Append To List     ${initiator_list}    ${client_initiator_name_dict}
    Edit Initiator Group    group_name=${iscsi_group01}   protocol=iscsi    initiator_list=${initiator_list}

















#Do how================================================================================================================
Create iSCSI Target
    Add iSCSI Target    gateway_group=${vs_name}    target_id=${iscsi_target_name_urlencoding}
    Switch Connection    @{PUBLICIP}[0]
    Wait Until Keyword Succeeds    30s    5s    SSH Output Should Be Equal    scstadmin --list_target|grep ${iscsi_target_name}|awk '{print $2}'    ${iscsi_target_name}

Remove iSCSI target
    Delete iSCSI Target    ${vs_name}    ${iscsi_target_name_urlencoding}
    Wait Until Keyword Succeeds    30s    5s    SSH Output Should Not Contain    cat /etc/scst.conf    DEVICE

Create iSCSI Volume
    [Arguments]    ${allow_all}=false
    Add iSCSI Volume    gateway_group=${vs_name}    pool_id=${default_pool}    target_id=${iscsi_target_name_urlencoding}    iscsi_id=${iscsi_volume_name}    size=${iscsi_volume_size}    allow_all=${allow_all}
    ${rbd_image}=    Get RBD Image Name
    Switch Connection    @{PUBLICIP}[0]
    Wait Until Keyword Succeeds    30s    5s    SSH Output Should Be Equal    rbd showmapped | grep ${rbd_image} | awk '{print $3}'    ${rbd_image}

Remove iSCSI Volume
    ${rbd_image}=    Get RBD Image Name
    Switch Connection    @{PUBLICIP}[0]
    Disable iSCSI LUN    ${vs_name}    ${iscsi_target_name_urlencoding}    ${iscsi_volume_name}
    Wait Until Keyword Succeeds    30s    5s    Check If SSH Output Is Empty    rbd showmapped | grep ${rbd_image}    ${true}
    Delete iSCSI LUN    ${vs_name}    ${iscsi_target_name_urlencoding}    ${iscsi_volume_name}
    Wait Until Keyword Succeeds    2m    5s    Check If SSH Output Is Empty    rbd ls | grep ${rbd_image}    ${true}

Get RBD Image Name
    [Arguments]    ${volume_name}=${iscsi_volume_name}
    ${rbd_entry}=    Get Return Json    /cgi-bin/ezs3/json/iscsi_list?target_id=${iscsi_target_name_urlencoding}    /response/entry
    ${rbd_entry_parse}=    Parse Json    ${rbd_entry}
    ${length}=    Get Length    ${rbd_entry_parse}
    :FOR    ${INDEX}    IN RANGE    0    ${length}
    \    ${rbd_image}=    Run Keyword If    '${rbd_entry_parse[${INDEX}]['scsi_id']}' == '${volume_name}'
    \    ...    Set Variable    ${rbd_entry_parse[${INDEX}]['rbd_img']}
    \    Exit For Loop If    '${rbd_entry_parse[${INDEX}]['scsi_id']}' == '${volume_name}'
    [Return]    ${rbd_image}

Get Client Initiator Name
    Switch Connection    127.0.0.1
    ${client_initiator}=    Execute Command    cat /etc/iscsi/initiatorname.iscsi | grep InitiatorName= | cut -d '=' -f 2
    [Return]    ${client_initiator}

Check iSCIS Volume can Access
    Switch Connection    127.0.0.1
    Wait Until Keyword Succeeds    30s    5s    SSH Output Should Contain    iscsiadm -m discovery -t st -p @{PUBLICIP}[0]    ${iscsi_target_name}
    Execute Command Successfully    iscsiadm -m node -o delete

Check iSCIS Volume can not Access
    Switch Connection    127.0.0.1
    Wait Until Keyword Succeeds    30s    5s    SSH Output Should Not Contain    iscsiadm -m discovery -t st -p @{PUBLICIP}[0]    ${iscsi_target_name}
    Execute Command    iscsiadm -m node -o delete

Create Initiator Group
    [Arguments]    ${group_name}=    ${protocol}=    ${initiator_list}=[]
    ${initiator_list_urlencode}=    URL Encode    ${initiator_list}
    ${post_request}=    Set Variable    gateway_group=${gateway_group}&group_name=${group_name}&protocol=${protocol}&initiator_list=${initiator_list_urlencode}
    Post Return Code Should be 0    ${post_request}    /cgi-bin/ezs3/json/initiator_group_create

Edit Initiator Group
    [Arguments]    ${group_name}=    ${protocol}=    ${initiator_list}=[]
    ${initiator_group}=    Search Initiator Group Key    group_name=${group_name}
    ${initiator_group_key}=    Get Dictionary Keys    ${initiator_group}
    ${group_id}=    Set Variable    ${initiator_group_key[0]}
    ${initiator_list_urlencode}=    URL Encode    ${initiator_list}
    ${post_request}=    Set Variable    gateway_group=${gateway_group}&group_id=${group_id}&group_name=${group_name}&protocol=${protocol}&initiator_list=${initiator_list_urlencode}
    Post Return Code Should be 0    ${post_request}    /cgi-bin/ezs3/json/initiator_group_edit

Check Initiator Group Create Successly
    [Arguments]    ${group_name}=
    ${initiator_entry}=    Get Initiator Group List
    ${group_name_list}=    Query Keyword Value    group_name    ${initiator_entry}
    Should Contain Match    ${group_name_list}    ${group_name}

Delete Initiator Group
    [Arguments]    ${group_name}=all
    ${initiator_entry_selected}=    Search Initiator Group Key    group_name=${group_name}
    ${group_ids_key}=    Query Key    ${initiator_entry_selected}
    ${group_ids_key_urlencode}=    URL Encode    ${group_ids_key}
    Return Code Should be    /cgi-bin/ezs3/json/initiator_group_delete?gateway_group=${gateway_group}&group_ids=${group_ids_key_urlencode}    0

Get Initiator Group List
    ${initiator_entry}=    Get Return Json    /cgi-bin/ezs3/json/initiator_group_list?gateway_group=${gateway_group}    /response
    ${initiator_entry_parse}=    Parse Json    ${initiator_entry}
    [Return]    ${initiator_entry_parse}

Search Initiator Group Key
    [Arguments]    ${group_name}=all
    ${initiator_entry}=    Get Initiator Group List
    ${initiator_entry_selected}=    Run Keyword If    '${group_name}' == 'all'
    ...    Set Variable    ${initiator_entry}
    ...    ELSE
    ...    Search Key Value    group_name    ${group_name}    ${initiator_entry}
    [Return]    ${initiator_entry_selected}

Enable Special ACL on Volume
    [Arguments]    ${allow_all}=true    ${allowed_initiators}=    ${volume_name}=${iscsi_volume_name}
    Modify iSCSI LUN    allow_all=${allow_all}    gateway_group=${vs_name}    allowed_initiators=${allowed_initiators}    iscsi_id=${volume_name}    target_id=${iscsi_target_name_urlencoding}    size=${iscsi_volume_size}

Enable ACL Group on Volume
    [Arguments]    ${allow_all}=false    ${allowed_initiator_groups}=    ${allowed_initiators}=    ${volume_name}=${iscsi_volume_name}
    ${initiator_group}=    Search Initiator Group Key    group_name=${allowed_initiator_groups}
    ${initiator_group_key}=    Get Dictionary Keys    ${initiator_group}
    ${allowed_initiator_groups_uuid}=    Set Variable    ${initiator_group_key[0]}
    Modify iSCSI LUN    allow_all=${allow_all}    gateway_group=${vs_name}    allowed_initiator_groups=${allowed_initiator_groups_uuid}    allowed_initiators=${allowed_initiators}    iscsi_id=${volume_name}    target_id=${iscsi_target_name_urlencoding}    size=${iscsi_volume_size}

Enable iSCSI volume
    [Arguments]    ${volume_name}=${iscsi_volume_name}
    ${rbd_image}=    Get RBD Image Name    volume_name=${volume_name}
    Enable iSCSI LUN    ${vs_name}    ${iscsi_target_name_urlencoding}    ${volume_name}
    Switch Connection    @{PUBLICIP}[0]
    Wait Until Keyword Succeeds    30s    5s    SSH Output Should Be Equal    rbd showmapped | grep ${rbd_image} | awk '{print $3}'    ${rbd_image}

Disable iSCSI volume
    [Arguments]    ${volume_name}=${iscsi_volume_name}
    ${rbd_image}=    Get RBD Image Name    volume_name=${volume_name}
    Switch Connection    @{PUBLICIP}[0]
    Disable iSCSI LUN    ${vs_name}    ${iscsi_target_name_urlencoding}    ${volume_name}
    Wait Until Keyword Succeeds    30s    5s    Check If SSH Output Is Empty    rbd showmapped | grep ${rbd_image}    ${true}

