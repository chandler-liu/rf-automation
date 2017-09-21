*** Settings ***
Documentation     Initial first OSD pool  
Suite Setup       Network Setup
Suite Teardown    Network Teardown
Resource          ../00_commonconfig.txt
Resource          ../keyword/keyword_verify.txt
Resource          ../keyword/keyword_system.txt
Resource          ../keyword/keyword_cgi.txt


*** Variables ***
${osd_name_prefix}      osd_
${osd_volume}           /dev/sdb


*** Test Cases ***
Create All OSD Role
    [Tags]    Initial
    Enable All OSD Role    num_nodes=${CLUSTERNODES}


*** Keywords ***
Enable All OSD Role
    [Arguments]     ${num_nodes}
    : FOR    ${i}    IN RANGE    ${num_nodes}
    \    Run Keyword    Create OSD and Volume     public_ip=@{PUBLICIP}[${i}]    storage_ip=@{STORAGEIP}[${i}]    osd_name=${osd_name_prefix}${i}    data_dev=${osd_volume}
    \    Wait Until Keyword Succeeds    4 min    5 sec    Check Role Status    @{STORAGEIP}[${i}]    role=osd    status=enabled


