*** Settings ***
Documentation     This suite includes cases related to general cases about NAS configuration
Suite Setup       Run Keywords    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
...               AND    Open All SSH Connections    ${USERNAME}    ${PASSWORD}    @{PUBLICIP}
...               AND    Open Connection    127.0.0.1    alias=127.0.0.1
...               AND    Login    ${LOCALUSER}    ${LOCALPASS}
...               AND    Create S3 Account    ${account_name}
Suite Teardown    Run Keywords    Close All Connections    # Close SSH connections
...               AND    Delete S3 Account    ${account_name}
Library           OperatingSystem
Library           SSHLibrary
Library           HttpLibrary.HTTP
Resource          ../00_commonconfig.txt
Resource          ../00_commonkeyword.txt
Resource          00_virtual_storage_keyword.txt

*** Variables ***
${vs_name}        Default
${pool_name}    Default
${account_name}    s3fs_account
${folder_nfs_name}    s3_nfs
${folder_cifs_name}    s3_cifs
${bucket_name}    bucket1
${nfs_mount_point}    /mnt/nfs
${cifs_mount_point}    /mnt/cifs

*** Test Cases ***
Add NFS on top of S3
    [Documentation]    Testlink ID: Sc-502:Add NFS on top of S3
    [Tags]    FAST
    Switch Connection    @{PUBLICIP}[0]
    ${access_key} =    Execute Command    radosgw-admin user info --uid=${account_name}|grep access_key|awk -F \\\" '{print $4}'
    ${secret_key} =    Execute Command    radosgw-admin user info --uid=${account_name}|grep secret_key|awk -F \\\" '{print $4}' | head -n 1
    Execute Command Successfully    rm -f /root/.s3cfg;
    Setup S3cmd Config    ${access_key}    ${secret_key}
    Execute Command Successfully    sed -i 's/s3.amazonaws.com/@{PUBLICIP}[0]/g' /root/.s3cfg;
    Execute Command Successfully    s3cmd mb s3://${bucket_name}
    Execute Command Successfully    touch /tmp/nfs_flag;
    Execute Command Successfully    s3cmd put /tmp/nfs_flag s3://${bucket_name}
    Add Shared Folder    name=${folder_nfs_name}    gateway_group=${vs_name}    pool=    s3_folder=true    bucket=${bucket_name}    nfs=true
    Wait Until Keyword Succeeds    2m    5s    Check If SSH Output Is Empty    exportfs -v | grep ${folder_nfs_name}    ${false}
    Switch Connection   127.0.0.1
    Execute Command Successfully    mkdir -p ${nfs_mount_point}; mount -t nfs @{PUBLICIP}[0]:/vol/${folder_nfs_name} ${nfs_mount_point}
    SSH Output Should Contain    ls ${nfs_mount_point}    nfs_flag

Add CIFS on top of S3
    [Documentation]    Testlink ID: Sc-503:Add CIFS on top of S3
    [Tags]    FAST
    Add Shared Folder    name=${folder_cifs_name}    gateway_group=${vs_name}    pool=    s3_folder=true    bucket=${bucket_name}    smb=true    guest_ok=true
    Switch Connection    @{PUBLICIP}[0]
    Execute Command Successfully    touch /tmp/cifs_flag; s3cmd put /tmp/cifs_flag s3://${bucket_name}
    Wait Until Keyword Succeeds    2m    5s    Check If SSH Output Is Empty    cat /etc/samba/smb.conf|grep ${folder_cifs_name}    ${false}
    Switch Connection   127.0.0.1
    Execute Command Successfully    mkdir -p ${cifs_mount_point}; mount -t cifs -o guest //@{PUBLICIP}[0]/${folder_cifs_name} ${cifs_mount_point}
    SSH Output Should Contain    ls ${cifs_mount_point}    cifs_flag

Check create/read/write/delete files in NFS
    [Documentation]    Testlink ID: Sc-504:Check create/read/write/delete files in NFS
    [Tags]    FAST
    Switch Connection   127.0.0.1
    Execute Command Successfully    echo "test nfs on top of s3" > ${nfs_mount_point}/test.txt
    SSH Output Should Be Equal    cat ${nfs_mount_point}/test.txt    test nfs on top of s3    
    Execute Command Successfully    rm -f ${nfs_mount_point}/test.txt
    Check If SSH Output Is Empty    ls ${nfs_mount_point}/test.txt    ${true}

Check create/list/delete folders in NFS
    [Documentation]    Testlink ID: Sc-505:Check create/list/delete folders in NFS
    [Tags]    FAST
    Switch Connection   127.0.0.1
    Execute Command Successfully    mkdir -p ${nfs_mount_point}/subfolder;touch ${nfs_mount_point}/subfolder/test.txt
    SSH Output Should Be Equal    ls ${nfs_mount_point}/subfolder/    test.txt
    Execute Command Successfully    rm -rf ${nfs_mount_point}/subfolder
    SSH Output Should Not Contain    ls ${nfs_mount_point}    subfolder
    
Check create/read/write/delete files in CIFS
    [Documentation]     Testlink ID: Sc-509:Check create/read/write/delete files in CIFS
    [Tags]    FAST
    Switch Connection   127.0.0.1
    Execute Command Successfully    echo "test cifs on top of s3" > ${cifs_mount_point}/test.txt
    SSH Output Should Be Equal    cat ${cifs_mount_point}/test.txt    test cifs on top of s3    
    Execute Command Successfully    rm -f ${cifs_mount_point}/test.txt
    Check If SSH Output Is Empty    ls ${cifs_mount_point}/test.txt    ${true}

#Check create/list/delete folders in CIFS
#    [Documentation]    Testlink ID: Sc-510:Check create/list/delete folders in CIFS
#    [Tags]    FAST    KnownIssue
#    Switch Connection   127.0.0.1
#    Execute Command Successfully    mkdir -p ${cifs_mount_point}/subfolder;touch ${cifs_mount_point}/subfolder/test.txt
#    SSH Output Should Be Equal    ls ${cifs_mount_point}/subfolder/    test.txt
#    Execute Command Successfully    rm -rf ${cifs_mount_point}/subfolder
#    SSH Output Should Not Contain    ls ${cifs_mount_point}    subfolder
   
Delete NFS folder on S3
    [Documentation]    Testlink ID: Sc-514:Delete NFS folder on S3
    [Tags]    FAST
    Switch Connection   127.0.0.1
    Execute Command Successfully    umount ${nfs_mount_point}
    Delete Shared Folder    ${vs_name}    ${folder_nfs_name}
    Switch Connection    @{PUBLICIP}[0]
    Wait Until Keyword Succeeds    2m    5s    Check If SSH Output Is Empty    exportfs -v | grep ${folder_nfs_name}    ${true}
    SSH Output Should Contain    s3cmd la s3://${bucket_name}    nfs_flag

Delete CIFS folder on S3
    [Documentation]    Testlink ID: Sc-515:Delete CIFS folder on S3
    [Tags]    FAST
    Switch Connection   127.0.0.1
    Execute Command Successfully    umount ${cifs_mount_point}
    Delete Shared Folder    ${vs_name}    ${folder_cifs_name}
    Switch Connection    @{PUBLICIP}[0]
    Wait Until Keyword Succeeds    2m    5s    Check If SSH Output Is Empty    cat /etc/samba/smb.conf|grep ${folder_cifs_name}    ${true}
    SSH Output Should Contain    s3cmd la s3://${bucket_name}    cifs_flag

*** Keywords ***
Create S3 Account
    [Arguments]    ${user_name}
    Return Code Should be 0    /cgi-bin/ezs3/json/add_user?user_id=${user_name}&display_name=${user_name}&email=${user_name}%40qq.com&password=1&confirm_password=1&type=&dn=

Delete S3 Account
    [Arguments]    ${user_name}
    Set Request Body    user_ids=%5B%22${user_name}%22%5D
    POST    /cgi-bin/ezs3/json/del_multi_user
    Response Status Code Should Equal    200 OK

Setup S3cmd Config
    [Arguments]    ${access_key}    ${secret_key}
    Write    s3cmd --configure
    Read Until    Access Key     
    Write    ${access_key}
    Read Until    Secret Key
    Write    ${secret_key}
    Read Until    password:
    Write Bare    \n
    Read Until    GPG program
    Write Bare    \n
    Read Until    Use HTTPS protocol
    Write Bare    \n
    Read Until    HTTP Proxy server name:
    Write Bare    \n  
    Read Until    Test access
    Write    n
    Read Until    Save settings?
    Write    y
    Read Until    Configuration saved
