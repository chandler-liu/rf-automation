*** Settings ***
Documentation     This suite includes cases related to NAS migration
Suite Setup       Run Keywords    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
...               AND    Open All SSH Connections    ${USERNAME}    ${PASSWORD}    @{PUBLICIP}
...               AND    Open Connection    127.0.0.1    alias=127.0.0.1
...               AND    Login    ${LOCALUSER}    ${LOCALPASS}
...               AND    Prepare External NAS
Suite Teardown    Run Keywords    Close All Connections    # Close SSH connections
...               AND    Delete External NAS
Library           OperatingSystem
Library           SSHLibrary
Library           HttpLibrary.HTTP
Resource          ../00_commonconfig.txt
Resource          ../00_commonkeyword.txt
Resource          00_virtual_storage_keyword.txt

*** Variables ***
${external_nas_name}    source
${vs_name}        Default
${default_pool}    Default

*** Test Cases ***
Read/write/create/delete/list Files Before Migration(NFS)
    [Documentation]    Testlink ID:
    ...    Sc-464:Read/write/create/delete/list files before migration
    [Tags]    FAST
    ${folder_name} =    Set Variable    nfs_dest
    ${mount_point} =    Set Variable    /mnt/nfs
    Add Shared Folder    name=${folder_name}    gateway_group=${vs_name}    pool=${default_pool}    smb=false    migrate_folder=true    migrate_gw_ip=@{STORAGEIP}[0]
    ...    migrate_server=@{PUBLICIP}[2]    migrate_fs_type=nfs    migrate_windows_host=false    migrate_path=%2Fvol%2F${external_nas_name}    migrate_copyup=open
    Switch Connection    @{PUBLICIP}[0]
    Wait Until Keyword Succeeds    1m    5s    Check If SSH Output Is Empty    mount|grep aufs    ${false}
    Wait Until Keyword Succeeds    1m    5s    Check If SSH Output Is Empty    exportfs -v|grep ${folder_name}    ${false}
    Switch Connection    127.0.0.1
    Execute Command Successfully    mkdir -p ${mount_point}; mount -t nfs @{PUBLICIP}[0]:/vol/${folder_name} ${mount_point}
    # Check Read
    SSH Output Should Be Equal    cat ${mount_point}/1.txt    origin_1   
    # Check Modify
    Execute Command Successfully    echo "Modify_2" > ${mount_point}/2.txt
    SSH Output Should Be Equal    cat ${mount_point}/2.txt    Modify_2
    # Check Write
    Execute Command Successfully    echo "Write new file before migration" > ${mount_point}/nfs_new.txt
    SSH Output Should Be Equal    cat ${mount_point}/nfs_new.txt    Write new file before migration
    # Check Delete
    Execute Command Successfully    rm -f ${mount_point}/3.txt
    Check If SSH Output Is Empty    ls ${mount_point}/|grep 3.txt    ${true}
    # Check List
    SSH Output Should Be Equal    ls ${mount_point}/| wc -l    10
    [Teardown]    Run Keywords    Execute Command     umount ${mount_point}
    ...           AND             Delete Shared Folder    ${vs_name}    ${folder_name}

#Start Migration In Case of "Copy on Open"(NFS)
#    [Documentation]    Testlink ID:
#    ...     Sc-477:Start backend migration in case of "copy on open"
#    [Tags]    FAST
    


*** Keywords ***
Prepare External NAS
    Add Shared Folder    name=${external_nas_name}    gateway_group=${vs_name}    pool=${default_pool}
    Switch Connection    @{PUBLICIP}[0]
    Wait Until Keyword Succeeds    1m    5s    Check If SSH Output Is Empty    exportfs -v|grep ${external_nas_name}   ${false}
    Wait Until Keyword Succeeds    1m    5s    Check If SSH Output Is Empty    cat /etc/samba/smb.conf|grep ${external_nas_name}    ${false}
    Execute Command Successfully    cd /vol/${external_nas_name}; for i in `seq 10`;do echo "origin_"$i > $i.txt;done

Delete External NAS
    Delete Shared Folder    ${vs_name}    ${external_nas_name}
