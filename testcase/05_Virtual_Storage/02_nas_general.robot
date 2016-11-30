*** Settings ***
Documentation     This suite includes cases related to general cases about NAS configuration
Suite Setup       Run Keywords    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
...               AND    Open All SSH Connections    ${USERNAME}    ${PASSWORD}    @{PUBLICIP}
Suite Teardown    Close All Connections    # Close SSH connections
Library           OperatingSystem
Library           SSHLibrary
Library           HttpLibrary.HTTP
Resource          ../00_commonconfig.txt
Resource          ../00_commonkeyword.txt
Resource          00_virtual_storage_keyword.txt

*** Variables ***
${vs_name}        Default
${default_pool}    Default

*** Test Cases ***
Create NFS share folder
    [Documentation]    Testlink ID:
    ...    Sc-432:Create NFS share folder
    [Tags]    RAT
    ${folder_name} =    Set Variable    nfsfolder
    ${mount_point} =    Set Variable    /mnt/nfs
    Add Shared Folder    name=${folder_name}    gateway_group=${vs_name}    pool=${default_pool}    nfs=true
    Assign Gateway to Virtual Storage    ${vs_name}    @{STORAGEIP}[0]
    Switch Connection    @{PUBLICIP}[0]
    Wait Until Keyword Succeeds    2m    5s    Check If SSH Output Is Empty    exportfs -v|grep ${folder_name}    ${false}
    ${rc} =    Run and Return RC    mkdir -p ${mount_point};sudo umount ${mount_point};sudo mount -t nfs @{PUBLICIP}[0]:/vol/${folder_name} ${mount_point}
    Should Be Equal As Integers    ${rc}    0
    ${rc} =    Run and Return RC    sudo umount ${mount_point}
    Should Be Equal As Integers    ${rc}    0
    [Teardown]    Delete Shared Folder    ${vs_name}    ${folder_name}

Create CIFS share folder
    [Documentation]    Testlink ID:
    ...    Sc-433:Create CIFS share folder
    [Tags]    RAT
    ${folder_name} =    Set Variable    cifsfolder
    ${mount_point} =    Set Variable    /mnt/cifs
    Add Shared Folder    name=${folder_name}    gateway_group=${vs_name}    pool=${default_pool}    smb=true    guest_ok=true
    Assign Gateway to Virtual Storage    ${vs_name}    @{STORAGEIP}[0]
    Switch Connection    @{PUBLICIP}[0]
    Wait Until Keyword Succeeds    2m    5s    Check If SSH Output Is Empty    cat /etc/samba/smb.conf|grep ${folder_name}    ${false}
    ${rc} =    Run and Return RC    mkdir -p ${mount_point};sudo umount ${mount_point};sudo mount -t cifs -o guest //@{PUBLICIP}[0]/${folder_name} ${mount_point}
    Should Be Equal As Integers    ${rc}    0
    ${rc} =    Run and Return RC    sudo umount ${mount_point}
    Should Be Equal As Integers    ${rc}    0
    [Teardown]    Delete Shared Folder    ${vs_name}    ${folder_name}

Create share folder for both NFS and CIFS
    [Documentation]    Testlink ID:
    ...    Sc-434:Create share folder for both NFS and CIFS
    [Tags]    FAST
    ${folder_name} =    Set Variable    nfscifsfolder
    ${nfs_mount_point} =    Set Variable    /mnt/nfs
    ${cifs_mount_point} =    Set Variable    /mnt/cifs
    Add Shared Folder    name=${folder_name}    gateway_group=${vs_name}    pool=${default_pool}    nfs=true    smb=true    guest_ok=true
    Assign Gateway to Virtual Storage    ${vs_name}    @{STORAGEIP}[0]
    Switch Connection    @{PUBLICIP}[0]
    Wait Until Keyword Succeeds    2m    5s    Check If SSH Output Is Empty    exportfs -v|grep ${folder_name}    ${false}
    Wait Until Keyword Succeeds    2m    5s    Check If SSH Output Is Empty    cat /etc/samba/smb.conf|grep ${folder_name}    ${false}
    ${rc} =    Run and Return RC    mkdir -p ${nfs_mount_point};sudo umount ${nfs_mount_point};sudo mount -t nfs @{PUBLICIP}[0]:/vol/${folder_name} ${nfs_mount_point}
    Should Be Equal As Integers    ${rc}    0
    ${rc} =    Run and Return RC    mkdir -p ${cifs_mount_point};sudo umount ${cifs_mount_point};sudo mount -t cifs -o guest //@{PUBLICIP}[0]/${folder_name} ${cifs_mount_point}
    Should Be Equal As Integers    ${rc}    0
    Create File    ${nfs_mount_point}/foo.txt    Hello, world!
    Wait Until Created    ${cifs_mount_point}/foo.txt
    ${content} =    OperatingSystem.Get File    ${cifs_mount_point}/foo.txt
    Should Be Equal    ${content}    Hello, world!
    ${rc} =    Run and Return RC    sudo umount ${nfs_mount_point}
    Should Be Equal As Integers    ${rc}    0
    ${rc} =    Run and Return RC    sudo umount ${cifs_mount_point}
    Should Be Equal As Integers    ${rc}    0
    [Teardown]    Delete Shared Folder    ${vs_name}    ${folder_name}

Enable share folder
    [Documentation]    Testlink ID:
    ...    Sc-435:Enable share folder
    [Tags]    FAST
    ${folder_name} =    Set Variable    nfsfolder
    ${mount_point} =    Set Variable    /mnt/nfs
    Add Shared Folder    name=${folder_name}    gateway_group=${vs_name}    pool=${default_pool}    nfs=true
    Assign Gateway to Virtual Storage    ${vs_name}    @{STORAGEIP}[0]
    Disable Shared Folder    name_list=${folder_name}    gateway_group=${vs_name}
    Enable Shared Folder    name_list=${folder_name}    gateway_group=${vs_name}
    Switch Connection    @{PUBLICIP}[0]
    Wait Until Keyword Succeeds    2m    5s    Check If SSH Output Is Empty    exportfs -v    ${false}
    ${rc} =    Run and Return RC    mkdir -p ${mount_point};sudo umount ${mount_point};sudo mount -t nfs @{PUBLICIP}[0]:/vol/${folder_name} ${mount_point}
    Should Be Equal As Integers    ${rc}    0
    ${rc} =    Run and Return RC    sudo umount ${mount_point}
    Should Be Equal As Integers    ${rc}    0
    [Teardown]    Delete Shared Folder    ${vs_name}    ${folder_name}

Disable share folder
    [Documentation]    Testlink ID:
    ...    Sc-436:Disable share folder
    [Tags]    FAST
    ${folder_name} =    Set Variable    nfsfolder
    ${mount_point} =    Set Variable    /mnt/nfs
    Add Shared Folder    name=${folder_name}    gateway_group=${vs_name}    pool=${default_pool}    nfs=true
    Assign Gateway to Virtual Storage    ${vs_name}    @{STORAGEIP}[0]
    Switch Connection    @{PUBLICIP}[0]
    Wait Until Keyword Succeeds    2m    5s    Check If SSH Output Is Empty    exportfs -v    ${false}
    Disable Shared Folder    name_list=${folder_name}    gateway_group=${vs_name}
    Wait Until Keyword Succeeds    1m    5s    Check If SSH Output Is Empty    exportfs -v    ${true}
    ${rc} =    Run and Return RC    mkdir -p ${mount_point};sudo umount ${mount_point};sudo mount -t nfs @{PUBLICIP}[0]:/vol/${folder_name} ${mount_point}
    Should Not Be Equal As Integers    ${rc}    0
    [Teardown]    Delete Shared Folder    ${vs_name}    ${folder_name}

Delete share folder
    [Documentation]    Testlink ID:
    ...    Sc-437:Delete share folder
    [Tags]    FAST
    ${folder_name} =    Set Variable    nfsfolder
    Add Shared Folder    name=${folder_name}    gateway_group=${vs_name}    pool=${default_pool}    nfs=true    smb=true
    Assign Gateway to Virtual Storage    ${vs_name}    @{STORAGEIP}[0]
    Switch Connection    @{PUBLICIP}[0]
    Wait Until Keyword Succeeds    2m    5s    Check If SSH Output Is Empty    exportfs -v    ${false}
    ${ret} =    Get Json Path Value    /cgi-bin/ezs3/json/list_shared_folder?gateway_group=${vs_name}    /response/folders/folder
    Should Contain    ${ret}    ${folder_name}
    Delete Shared Folder    ${vs_name}    ${folder_name}
    ${ret} =    Get Json Path Value    /cgi-bin/ezs3/json/list_shared_folder?gateway_group=${vs_name}    /response/folders/folder
    Should Not Contain    ${ret}    ${folder_name}
    Wait Until Keyword Succeeds    1m    5s    Check If SSH Output Is Empty    exportfs -v    ${true}
    Wait Until Keyword Succeeds    1m    5s    Check If SSH Output Is Empty    cat /etc/samba/smb.conf|grep ${folder_name}    ${true}

Configure NFS server accessing model
    [Documentation]    Testlink ID:
    ...    Sc-438:Configure NFS server accessing model
    [Tags]    TOFT
    ${folder_name} =    Set Variable    sync_async_folder
    Add Shared Folder    name=${folder_name}    gateway_group=${vs_name}    pool=${default_pool}    nfs=true    mode=sync
    Assign Gateway to Virtual Storage    ${vs_name}    @{STORAGEIP}[0]
    Switch Connection    @{PUBLICIP}[0]
    Wait Until Keyword Succeeds    2m    5s    Check If SSH Output Is Empty    cat /etc/exports | grep ",sync,"    ${false}
    Modify Shared Folder    name=${folder_name}    gateway_group=${vs_name}    nfs=true    mode=async
    Wait Until Keyword Succeeds    2m    5s    Check If SSH Output Is Empty    cat /etc/exports | grep ",async,"    ${false}
    [Teardown]    Delete Shared Folder    ${vs_name}    ${folder_name}

Configure storage pool for share folder
    [Documentation]    Testlink ID:
    ...    Sc-439:Configure sotrage pool for share folder
    [Tags]    TOFT
    ${new_pool} =    Set Variable    pool1
    ${osd_ids} =    Set Variable    0
    ${folder_name} =    Set Variable    folder1
    Add Replicted Pool    pool_name=${new_pool}    rep_num=2    osd_ids=${osd_ids}
    Add Shared Folder    name=${folder_name}    gateway_group=${vs_name}    pool=${new_pool}
    Switch Connection    @{PUBLICIP}[0]
    Wait Until Keyword Succeeds    30s    5s    Check If SSH Output Is Empty    exportfs -v    ${false}
    Write    cd /vol/${folder_name}
    Write    dd if=/dev/zero of=1.tst bs=1K count=1 conv=fsync
    ${output}=    Read    delay=3s
    Should Contain    ${output}    copied
    Wait Until Keyword Succeeds    30s    5s    SSH Output Should Be Equal    ceph df|grep ${new_pool}|awk {'print \$3'}    1024
    [Teardown]    Run Keywords    Delete Shared Folder    ${vs_name}    ${folder_name}
    ...    AND    Delete Pool    ${new_pool}

*** Keywords ***
