*** Settings ***
Documentation     This suite includes cases related to general cases about NAS configuration
Suite Setup       Run Keywords    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
...               AND    Open All SSH Connections    ${USERNAME}    ${PASSWORD}    @{PUBLICIP}
...               AND    Open Connection    127.0.0.1    alias=127.0.0.1
...               AND    Login    ${LOCALUSER}    ${LOCALPASS}
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
    Switch Connection    127.0.0.1
    Execute Command Successfully    mkdir -p ${mount_point};umount ${mount_point};mount -t nfs @{PUBLICIP}[0]:/vol/${folder_name} ${mount_point}
    Execute Command Successfully    umount ${mount_point}
    [Teardown]    Delete Shared Folder    ${vs_name}    ${folder_name}

Create CIFS share folder
    [Documentation]    Testlink ID:
    ...    Sc-433:Create CIFS share folder
    [Tags]    RAT
    ${folder_name} =    Set Variable    cifsfolder
    ${mount_point} =    Set Variable    /mnt/cifs
    Add Shared Folder    name=${folder_name}    gateway_group=${vs_name}    pool=${default_pool}    smb=true    guest_ok=true
    Switch Connection    @{PUBLICIP}[0]
    Wait Until Keyword Succeeds    2m    5s    Check If SSH Output Is Empty    cat /etc/samba/smb.conf|grep ${folder_name}    ${false}
    Switch Connection    127.0.0.1
    Execute Command Successfully    mkdir -p ${mount_point};umount ${mount_point};mount -t cifs -o guest //@{PUBLICIP}[0]/${folder_name} ${mount_point}
    Execute Command Successfully    umount ${mount_point}
    [Teardown]    Run Keywords    Delete Shared Folder    ${vs_name}    ${folder_name}
    ...           AND             Switch Connection    @{PUBLICIP}[0]
    ...           AND             Wait Until Keyword Succeeds    1m    5s    Check If SSH Output Is Empty    cat /etc/samba/smb.conf|grep ${folder_name}    ${true}

Create share folder for both NFS and CIFS
    [Documentation]    Testlink ID:
    ...    Sc-434:Create share folder for both NFS and CIFS
    [Tags]    FAST
    ${folder_name} =    Set Variable    nfscifsfolder
    ${nfs_mount_point} =    Set Variable    /mnt/nfs
    ${cifs_mount_point} =    Set Variable    /mnt/cifs
    Add Shared Folder    name=${folder_name}    gateway_group=${vs_name}    pool=${default_pool}    nfs=true    smb=true    guest_ok=true
    Switch Connection    @{PUBLICIP}[0]
    Wait Until Keyword Succeeds    2m    5s    Check If SSH Output Is Empty    exportfs -v|grep ${folder_name}    ${false}
    Wait Until Keyword Succeeds    2m    5s    Check If SSH Output Is Empty    cat /etc/samba/smb.conf|grep ${folder_name}    ${false}
    Switch Connection    127.0.0.1
    Execute Command Successfully    mkdir -p ${nfs_mount_point};umount ${nfs_mount_point};mount -t nfs @{PUBLICIP}[0]:/vol/${folder_name} ${nfs_mount_point}
    Execute Command Successfully    mkdir -p ${cifs_mount_point};umount ${cifs_mount_point};mount -t cifs -o guest //@{PUBLICIP}[0]/${folder_name} ${cifs_mount_point}
    Create File    ${nfs_mount_point}/foo.txt    Hello, world!
    Wait Until Created    ${cifs_mount_point}/foo.txt
    ${content} =    OperatingSystem.Get File    ${cifs_mount_point}/foo.txt
    Should Be Equal    ${content}    Hello, world!
    Execute Command Successfully    umount ${nfs_mount_point}
    Execute Command Successfully    umount ${cifs_mount_point}
    [Teardown]    Run Keywords    Delete Shared Folder    ${vs_name}    ${folder_name}
    ...           AND             Switch Connection    @{PUBLICIP}[0]
    ...           AND             Wait Until Keyword Succeeds    1m    5s    Check If SSH Output Is Empty    exportfs -v    ${true}

Enable share folder
    [Documentation]    Testlink ID:
    ...    Sc-435:Enable share folder
    [Tags]    FAST
    ${folder_name} =    Set Variable    nfsfolder
    ${mount_point} =    Set Variable    /mnt/nfs
    Add Shared Folder    name=${folder_name}    gateway_group=${vs_name}    pool=${default_pool}    nfs=true
    Disable Shared Folder    name_list=${folder_name}    gateway_group=${vs_name}
    Enable Shared Folder    name_list=${folder_name}    gateway_group=${vs_name}
    Switch Connection    @{PUBLICIP}[0]
    Wait Until Keyword Succeeds    2m    5s    Check If SSH Output Is Empty    exportfs -v    ${false}
    Switch Connection    127.0.0.1
    Execute Command Successfully    mkdir -p ${mount_point};umount ${mount_point};mount -t nfs @{PUBLICIP}[0]:/vol/${folder_name} ${mount_point}
    Execute Command Successfully    umount ${mount_point}
    [Teardown]    Run Keywords    Delete Shared Folder    ${vs_name}    ${folder_name}
    ...           AND             Switch Connection    @{PUBLICIP}[0]
    ...           AND             Wait Until Keyword Succeeds    1m    5s    Check If SSH Output Is Empty    exportfs -v    ${true}

Disable share folder
    [Documentation]    Testlink ID:
    ...    Sc-436:Disable share folder
    [Tags]    FAST
    ${folder_name} =    Set Variable    nfsfolder
    ${mount_point} =    Set Variable    /mnt/nfs
    Add Shared Folder    name=${folder_name}    gateway_group=${vs_name}    pool=${default_pool}    nfs=true
    Switch Connection    @{PUBLICIP}[0]
    Wait Until Keyword Succeeds    2m    5s    Check If SSH Output Is Empty    exportfs -v    ${false}
    Disable Shared Folder    name_list=${folder_name}    gateway_group=${vs_name}
    Wait Until Keyword Succeeds    1m    5s    Check If SSH Output Is Empty    exportfs -v    ${true}
    Switch Connection    127.0.0.1
    ${cmd}=    Set Variable    mkdir -p ${mount_point};umount ${mount_point};mount -t nfs @{PUBLICIP}[0]:/vol/${folder_name} ${mount_point}
    ${rc} =    Execute Command    ${cmd}    return_stdout=False    return_rc=True
    Should Not Be Equal As Integers    ${rc}    0
    [Teardown]    Run Keywords    Delete Shared Folder    ${vs_name}    ${folder_name}
    ...           AND             Switch Connection    @{PUBLICIP}[0]
    ...           AND             Wait Until Keyword Succeeds    1m    5s    Check If SSH Output Is Empty    exportfs -v    ${true}

Delete share folder
    [Documentation]    Testlink ID:
    ...    Sc-437:Delete share folder
    [Tags]    FAST
    ${folder_name} =    Set Variable    nfsfolder
    Add Shared Folder    name=${folder_name}    gateway_group=${vs_name}    pool=${default_pool}    nfs=true    smb=true
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
    Switch Connection    @{PUBLICIP}[0]
    Wait Until Keyword Succeeds    2m    5s    Check If SSH Output Is Empty    cat /etc/exports | grep ",sync,"    ${false}
    Modify Shared Folder    name=${folder_name}    gateway_group=${vs_name}    nfs=true    mode=async
    Wait Until Keyword Succeeds    2m    5s    Check If SSH Output Is Empty    cat /etc/exports | grep ",async,"    ${false}
    [Teardown]    Run Keywords    Delete Shared Folder    ${vs_name}    ${folder_name}
    ...           AND             Wait Until Keyword Succeeds    1m    5s    Check If SSH Output Is Empty    exportfs -v    ${true}

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
    Wait Until Keyword Succeeds    3x    3s    Read Until    copied
    Wait Until Keyword Succeeds    30s    5s    SSH Output Should Be Equal    ceph df|grep ${new_pool}|awk {'print \$3'}    1024
    [Teardown]    Run Keywords    Delete Shared Folder    ${vs_name}    ${folder_name}
    ...           AND             Wait Until Keyword Succeeds    1m    5s    Check If SSH Output Is Empty    exportfs -v    ${true}
    ...           AND             Delete Pool    ${new_pool}

Set file QoS under sharefolder
    [Documentation]    Testlink ID:
    ...    Sc-446:Setting file QoS under sharefolder
    [Tags]    FAST
    ${folder_name} =    Set Variable    nfsfolder
    ${mount_point} =    Set Variable    /mnt/nfs
    ${read_maxbw} =    Set Variable    5242880   # 5M
    ${write_maxbw} =    Set Variable    5242880   # 5M
    ${read_maxiops} =    Set Variable    50
    ${write_maxiops} =    Set Variable    50
    Add Shared Folder    name=${folder_name}    gateway_group=${vs_name}    pool=${default_pool}    nfs=true
    Switch Connection    @{PUBLICIP}[0]
    Wait Until Keyword Succeeds    2m    5s    Check If SSH Output Is Empty    exportfs -v|grep ${folder_name}    ${false}
    # Before set QoS
    Switch Connection    127.0.0.1
    Execute Command Successfully    mkdir -p ${mount_point};umount ${mount_point};mount -t nfs @{PUBLICIP}[0]:/vol/${folder_name} ${mount_point}
    Execute Command Successfully    fio --name=randwrite --rw=randwrite --bs=4k --size=100M --runtime=20 --ioengine=libaio --iodepth=16 --numjobs=1 --filename=${mount_point}/fio.tst --direct=1 --group_reporting --output=fio.result
    ${randwrite_iops} =    Execute Command    cat fio.result | sed -ne 's/.*iops=\\(.*\\),.*/\\1/p'
    Log    Before set QoS: ${randwrite_iops}
    Should Be True    ${randwrite_iops} > ${write_maxiops}
    Can Search Folder In QoS Setting Dialog    ${vs_name}    ${folder_name}
    Enable File QoS    gateway_group=${vs_name}    enable=true    path=${folder_name}    type=dir    read_maxbw=${read_maxbw}    read_maxiops=${read_maxiops}    write_maxbw=${write_maxbw}    write_maxiops=${write_maxiops}
    # After set QoS
    Switch Connection    @{PUBLICIP}[0]
    Wait Until Keyword Succeeds    4x    5s    Check If SSH Output Is Empty    getfattr -d -m - /var/share/ezfs/shareroot/${folder_name}/|grep ezqos    ${false}
    Sleep    10s
    Switch Connection    127.0.0.1
    Execute Command Successfully    fio --name=randwrite --rw=randwrite --bs=4k --size=100M --runtime=20 --ioengine=libaio --iodepth=16 --numjobs=1 --filename=${mount_point}/fio.tst --direct=1 --group_reporting --output=fio.result
    ${randwrite_iops} =    Execute Command    cat fio.result | sed -ne 's/.*iops=\\(.*\\),.*/\\1/p'
    Log    After set QoS: ${randwrite_iops}
    Should Be True    ${randwrite_iops} <= ${write_maxiops}
    Execute Command Successfully    umount ${mount_point}
    [Teardown]    Run Keywords    Delete Shared Folder    ${vs_name}    ${folder_name}
    ...           AND             Switch Connection    @{PUBLICIP}[0]
    ...           AND             Wait Until Keyword Succeeds    1m    5s    Check If SSH Output Is Empty    exportfs -v    ${true}
    ...           AND             Disable File QoS    ${vs_name}

*** Keywords ***
Can Search Folder In QoS Setting Dialog
    [Arguments]    ${vs_name}    ${filename}
    Return Code Should be 0    /cgi-bin/ezs3/json/search_file?gateway_group=${vs_name}&filename=${filename}&rw=true
    ${ret} =   Get Json Path Value    /cgi-bin/ezs3/json/search_file?gateway_group=${vs_name}&filename=${filename}&rw=true    /response/file/0/path
    Should Be Equal    ${ret}    "${filename}"

Enable File QoS
    [Arguments]    ${gateway_group}   ${enable}    ${path}    ${type}    ${read_maxbw}    ${read_maxiops}    ${write_maxbw}    ${write_maxiops}
    ${post_request} =    Set Variable    gateway_group=${gateway_group}&enable=${enable}&policies=%5B%7B%22path%22%3A%22${path}%22%2C%22type%22%3A%22${type}%22%2C%22read_maxbw%22%3A${read_maxbw}%2C%22read_maxiops%22%3A${read_maxiops}%2C%22write_maxbw%22%3A${write_maxbw}%2C%22write_maxiops%22%3A${write_maxiops}%7D%5D
    Post Return Code Should be 0    ${post_request}    /cgi-bin/ezs3/json/set_qos_policies

Disable File QoS
    [Arguments]    ${gateway_group}
    ${post_request} =    Set Variable    gateway_group=${gateway_group}&enable=false&policies=%5B%5D
    Post Return Code Should be 0    ${post_request}    /cgi-bin/ezs3/json/set_qos_policies
