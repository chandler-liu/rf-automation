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
${nfs_folder_name}    nfs_dest
${cifs_folder_name}    cifs_dest
${nfs_mount_point}    /mnt/nfs
${cifs_mount_point}    /mnt/cifs
${big_file_num}    200    # Each file is 10M size
${small_file_num}    10   # Plain file, set at least 7
${total_file_num}    210

*** Test Cases ***
Select "copy on open" in NAS migration(NFS)
    [Documentation]    Testlink ID:
    ...    Sc-474:Select "copy on open" in NAS migration
    [Tags]    FAST
    Add Shared Folder    name=${nfs_folder_name}    gateway_group=${vs_name}    pool=${default_pool}    smb=false
    ...    migrate_folder=true    migrate_gw_ip=@{STORAGEIP}[0]    migrate_server=@{PUBLICIP}[2]    migrate_fs_type=nfs
    ...    migrate_windows_host=false    migrate_path=%2Fvol%2F${external_nas_name}    migrate_copyup=open
    Switch Connection    @{PUBLICIP}[0]
    Wait Until Keyword Succeeds    1m    5s    Check If SSH Output Is Empty    mount|grep aufs.*${nfs_folder_name}=ro+coo_all,    ${false}
    Wait Until Keyword Succeeds    1m    5s    Check If SSH Output Is Empty    exportfs -v|grep ${nfs_folder_name}    ${false}

Read/write/create/delete/list Files Before Migration(NFS)
    [Documentation]    Testlink ID:
    ...    Sc-464:Read/write/create/delete/list files before migration
    [Tags]    FAST
    Switch Connection    127.0.0.1
    Execute Command Successfully    mkdir -p ${nfs_mount_point}; mount -t nfs @{PUBLICIP}[0]:/vol/${nfs_folder_name} ${nfs_mount_point}
    # Check Read
    SSH Output Should Be Equal    cat ${nfs_mount_point}/1.txt    origin_1   
    # Check Modify
    Execute Command Successfully    echo "Modify_2" > ${nfs_mount_point}/2.txt
    SSH Output Should Be Equal    cat ${nfs_mount_point}/2.txt    Modify_2
    # Check Write
    Execute Command Successfully    echo "Write new file before migration" > ${nfs_mount_point}/new_before_migration.txt
    SSH Output Should Be Equal    cat ${nfs_mount_point}/new_before_migration.txt    Write new file before migration
    # Check Delete
    Execute Command Successfully    rm -f ${nfs_mount_point}/3.txt
    Check If SSH Output Is Empty    ls ${nfs_mount_point}/|grep 3.txt    ${true}
    # Check List
    SSH Output Should Be Equal    ls ${nfs_mount_point}/| wc -l    ${total_file_num}

Read/write/create/delete/list Files During Migration(NFS)
    [Documentation]    Testlink ID:
    ...    Sc-465:Read/write/create/delete/list files during migration
    [Tags]    FAST
    Start NAS Migration    ${vs_name}    ${nfs_folder_name}
    # Check Read
    SSH Output Should Be Equal    cat ${nfs_mount_point}/1.txt    origin_1   
    # Check Modify
    Execute Command Successfully    echo "Modify_4" > ${nfs_mount_point}/4.txt
    SSH Output Should Be Equal    cat ${nfs_mount_point}/4.txt    Modify_4
    # Check Write
    Execute Command Successfully    echo "Write new file during migration" > ${nfs_mount_point}/new_during_migration.txt
    SSH Output Should Be Equal    cat ${nfs_mount_point}/new_during_migration.txt    Write new file during migration
    # Check Delete
    #Wait Until Keyword Succeeds    3x    1s    Execute Command Successfully    rm -f ${nfs_mount_point}/5.txt # Retry due to bug 1209
    Execute Command Successfully    rm -f ${nfs_mount_point}/5.txt
    Check If SSH Output Is Empty    ls ${nfs_mount_point}/|grep 5.txt    ${true}
    # Check List
    SSH Output Should Be Equal    ls ${nfs_mount_point}/| wc -l    ${total_file_num}

Read/write/create/delete/list Files After Migration(NFS)
    [Documentation]    Testlink ID:
    ...    Sc-466:Read/write/create/delete/list files after migration
    [Tags]    FAST
    Wait Until Keyword Succeeds    2m    10s    NAS Migration is Finished    ${vs_name}    ${nfs_folder_name}
    # Check Read
    SSH Output Should Be Equal    cat ${nfs_mount_point}/1.txt    origin_1   
    # Check Modify
    Execute Command Successfully    echo "Modify_6" > ${nfs_mount_point}/6.txt
    SSH Output Should Be Equal    cat ${nfs_mount_point}/6.txt    Modify_6
    # Check Write
    Execute Command Successfully    echo "Write new file after migration" > ${nfs_mount_point}/new_after_migration.txt
    SSH Output Should Be Equal    cat ${nfs_mount_point}/new_after_migration.txt    Write new file after migration
    # Check Delete
    Execute Command Successfully    rm -f ${nfs_mount_point}/7.txt
    Check If SSH Output Is Empty    ls ${nfs_mount_point}/|grep 7.txt    ${true}
    # Check List
    SSH Output Should Be Equal    ls ${nfs_mount_point}/| wc -l    ${total_file_num}

Start backend migration in case of "copy on open"(NFS)
    [Documentation]    Testlink ID:
    ...     Sc-477:Start backend migration in case of "copy on open"
    [Tags]    FAST
    # Check files modified/removed before migration or after migration
    SSH Output Should Be Equal    cat ${nfs_mount_point}/2.txt    Modify_2
    SSH Output Should Be Equal    cat ${nfs_mount_point}/4.txt    Modify_4
    SSH Output Should Be Equal    cat ${nfs_mount_point}/6.txt    Modify_6
    Check If SSH Output Is Empty    ls ${nfs_mount_point}/|grep 3.txt    ${true}
    Check If SSH Output Is Empty    ls ${nfs_mount_point}/|grep 5.txt    ${true}
    Check If SSH Output Is Empty    ls ${nfs_mount_point}/|grep 7.txt    ${true}
    SSH Output Should Be Equal    cat ${nfs_mount_point}/new_before_migration.txt    Write new file before migration
    SSH Output Should Be Equal    cat ${nfs_mount_point}/new_during_migration.txt    Write new file during migration
    SSH Output Should Be Equal    cat ${nfs_mount_point}/new_after_migration.txt    Write new file after migration
    [Teardown]    Run Keywords    Execute Command     umount ${nfs_mount_point}
    ...           AND             Delete Shared Folder    ${vs_name}    ${nfs_folder_name}
    ...           AND             Sleep    5s   # If not sleep, fs_id of nfs and cifs below may confuse

Select "copy on open" in NAS migration(CIFS)
    [Documentation]    Testlink ID:
    ...    Sc-474:Select "copy on open" in NAS migration
    [Tags]    FAST
    Add Shared Folder    name=${cifs_folder_name}    gateway_group=${vs_name}    pool=${default_pool}    smb=true    migrate_folder=true
    ...    migrate_gw_ip=@{STORAGEIP}[0]    migrate_server=@{PUBLICIP}[2]    migrate_fs_type=cifs    migrate_windows_host=false
    ...    migrate_path=${external_nas_name}    migrate_copyup=open    migrate_account=nobody    migrate_passwd=nopass    
    Switch Connection    @{PUBLICIP}[0]
    Wait Until Keyword Succeeds    1m    5s    Check If SSH Output Is Empty    mount|grep aufs.*${cifs_folder_name}=ro+coo_all,    ${false}
    Wait Until Keyword Succeeds    1m    5s    Check If SSH Output Is Empty    cat /etc/samba/smb.conf|grep ${cifs_folder_name}    ${false}

Read/write/create/delete/list Files Before Migration(CIFS)
    [Documentation]    Testlink ID:
    ...    Sc-464:Read/write/create/delete/list files before migration
    [Tags]    FAST
    Switch Connection    127.0.0.1
    Execute Command Successfully    mkdir -p ${cifs_mount_point}; mount -t cifs -o guest //@{PUBLICIP}[0]/${cifs_folder_name} ${cifs_mount_point}
    # Check Read
    SSH Output Should Be Equal    cat ${cifs_mount_point}/1.txt    origin_1
    # Check Modify
    Execute Command Successfully    echo "Modify_2" > ${cifs_mount_point}/2.txt
    SSH Output Should Be Equal    cat ${cifs_mount_point}/2.txt    Modify_2
    # Check Write
    Execute Command Successfully    echo "Write new file before migration" > ${cifs_mount_point}/new_before_migration.txt
    SSH Output Should Be Equal    cat ${cifs_mount_point}/new_before_migration.txt    Write new file before migration
    # Check Delete
    Execute Command Successfully    rm -f ${cifs_mount_point}/3.txt
    Check If SSH Output Is Empty    ls ${cifs_mount_point}/|grep 3.txt    ${true}
    # Check List
    SSH Output Should Be Equal    ls ${cifs_mount_point}/| wc -l    ${total_file_num}

Read/write/create/delete/list Files During Migration(CIFS)
    [Documentation]    Testlink ID:
    ...    Sc-465:Read/write/create/delete/list files during migration
    [Tags]    FAST
    Wait Until Keyword Succeeds    3x    5s    Start NAS Migration    ${vs_name}    ${cifs_folder_name}
    # Check Read
    SSH Output Should Be Equal    cat ${cifs_mount_point}/1.txt    origin_1   
    # Check Modify
    Execute Command Successfully    echo "Modify_4" > ${cifs_mount_point}/4.txt
    SSH Output Should Be Equal    cat ${cifs_mount_point}/4.txt    Modify_4
    # Check Write
    Execute Command Successfully    echo "Write new file during migration" > ${cifs_mount_point}/new_during_migration.txt
    SSH Output Should Be Equal    cat ${cifs_mount_point}/new_during_migration.txt    Write new file during migration
    # Check Delete
    Execute Command Successfully    rm -f ${cifs_mount_point}/5.txt
    Check If SSH Output Is Empty    ls ${cifs_mount_point}/|grep 5.txt    ${true}
    # Check List
    SSH Output Should Be Equal    ls ${cifs_mount_point}/| wc -l    ${total_file_num}

Read/write/create/delete/list Files After Migration(CIFS)
    [Documentation]    Testlink ID:
    ...    Sc-466:Read/write/create/delete/list files after migration
    [Tags]    FAST
    Wait Until Keyword Succeeds    2m    10s    NAS Migration is Finished    ${vs_name}    ${cifs_folder_name}
    # Check Read
    SSH Output Should Be Equal    cat ${cifs_mount_point}/1.txt    origin_1   
    # Check Modify
    Execute Command Successfully    echo "Modify_6" > ${cifs_mount_point}/6.txt
    SSH Output Should Be Equal    cat ${cifs_mount_point}/6.txt    Modify_6
    # Check Write
    Execute Command Successfully    echo "Write new file after migration" > ${cifs_mount_point}/new_after_migration.txt
    SSH Output Should Be Equal    cat ${cifs_mount_point}/new_after_migration.txt    Write new file after migration
    # Check Delete
    Execute Command Successfully    rm -f ${cifs_mount_point}/7.txt
    Check If SSH Output Is Empty    ls ${cifs_mount_point}/|grep 7.txt    ${true}
    # Check List
    SSH Output Should Be Equal    ls ${cifs_mount_point}/| wc -l    ${total_file_num}

Start backend migration in case of "copy on open"(CIFS)
    [Documentation]    Testlink ID:
    ...     Sc-477:Start backend migration in case of "copy on open"
    [Tags]    FAST
    # Check files modified/removed before migration or after migration
    SSH Output Should Be Equal    cat ${cifs_mount_point}/2.txt    Modify_2
    SSH Output Should Be Equal    cat ${cifs_mount_point}/4.txt    Modify_4
    SSH Output Should Be Equal    cat ${cifs_mount_point}/6.txt    Modify_6
    Check If SSH Output Is Empty    ls ${cifs_mount_point}/|grep 3.txt    ${true}
    Check If SSH Output Is Empty    ls ${cifs_mount_point}/|grep 5.txt    ${true}
    Check If SSH Output Is Empty    ls ${cifs_mount_point}/|grep 7.txt    ${true}
    SSH Output Should Be Equal    cat ${cifs_mount_point}/new_before_migration.txt    Write new file before migration
    SSH Output Should Be Equal    cat ${cifs_mount_point}/new_during_migration.txt    Write new file during migration
    SSH Output Should Be Equal    cat ${cifs_mount_point}/new_after_migration.txt    Write new file after migration
    [Teardown]    Run Keywords    Execute Command     umount ${cifs_mount_point}
    ...           AND             Delete Shared Folder    ${vs_name}    ${cifs_folder_name}
    ...           AND             Sleep    5s

Click Suspend/Resume Before Migration Finish
    [Documentation]    Testlink ID:
    ...     Sc-489:Click Suspend/Resume
    [Tags]    FAST
    ${suspend_start_num} =    Set Variable    50
    Add Shared Folder    name=${nfs_folder_name}    gateway_group=${vs_name}    pool=${default_pool}    smb=false
    ...    migrate_folder=true    migrate_gw_ip=@{STORAGEIP}[0]    migrate_server=@{PUBLICIP}[2]    migrate_fs_type=nfs
    ...    migrate_windows_host=false    migrate_path=%2Fvol%2F${external_nas_name}    migrate_copyup=open
    Switch Connection    @{PUBLICIP}[0]
    Wait Until Keyword Succeeds    1m    5s    Check If SSH Output Is Empty    mount|grep aufs.*${nfs_folder_name}=ro+coo_all,    ${false}
    Wait Until Keyword Succeeds    1m    5s    Check If SSH Output Is Empty    exportfs -v|grep ${nfs_folder_name}    ${false}
    Wait Until Keyword Succeeds    3x    5s    Start NAS Migration    ${vs_name}    ${nfs_folder_name}
    Wait Until Keyword Succeeds    30s    2s    Check If SSH Output Is Empty    ps aux |grep nas-migrate|grep -v grep    ${false}
    Wait Until Keyword Succeeds    1m    5s    Migrated Files Are More Than    ${nfs_folder_name}    ${suspend_start_num}
    Suspend NAS Migration    ${vs_name}    ${nfs_folder_name}
    Wait Until Keyword Succeeds    30s    2s    Check If SSH Output Is Empty    ps aux |grep nas-migrate|grep -v grep    ${true}
    ${first_num} =    Get Migrated Files Number    ${nfs_folder_name}
    Should Be True    ${first_num} < ${total_file_num}
    Sleep    10s
    ${second_num} =    Get Migrated Files Number    ${nfs_folder_name}
    Should Be Equal     ${first_num}    ${second_num}
    Start NAS Migration    ${vs_name}    ${nfs_folder_name}
    Wait Until Keyword Succeeds    2m    5s    Migrated Files Number Is    ${nfs_folder_name}    ${total_file_num}

Click Terminate after migration finishes
    [Documentation]    Testlink ID:
    ...     Sc-491:Click Terminate after migration finishes
    [Tags]    FAST
    # Before terminate, other gateway should not export this folder
    Switch Connection    @{PUBLICIP}[1]
    Check If SSH Output Is Empty    mount|grep /vol/${nfs_folder_name}     ${true}
    Switch Connection    @{PUBLICIP}[0]
    Check If SSH Output Is Empty    mount|grep aufs.*${nfs_folder_name}=ro+coo_all,    ${false}
    Terminate NAS Migration    ${vs_name}    ${nfs_folder_name}
    Wait Until Keyword Succeeds    1m    5s    Check If SSH Output Is Empty    mount|grep aufs.*${nfs_folder_name}=ro+coo_all,    ${true}
    # After terminate, other gateway should export this folder
    Switch Connection    @{PUBLICIP}[1]
    Wait Until Keyword Succeeds    1m    5s    Check If SSH Output Is Empty    mount|grep /vol/${nfs_folder_name}     ${false}
    [Teardown]    Delete Shared Folder    ${vs_name}    ${nfs_folder_name}

Select "copy on write" in NAS migration
    [Documentation]    Testlink ID:
    ...    Sc-468:Select "copy on write" in NAS migration
    [Tags]    FAST
    Add Shared Folder    name=${nfs_folder_name}    gateway_group=${vs_name}    pool=${default_pool}    smb=false
    ...    migrate_folder=true    migrate_gw_ip=@{STORAGEIP}[0]    migrate_server=@{PUBLICIP}[2]    migrate_fs_type=nfs
    ...    migrate_windows_host=false    migrate_path=%2Fvol%2F${external_nas_name}    migrate_copyup=write
    Switch Connection    @{PUBLICIP}[0]
    Wait Until Keyword Succeeds    1m    5s    Check If SSH Output Is Empty    mount|grep aufs.*${nfs_folder_name}=ro,    ${false}
    Wait Until Keyword Succeeds    1m    5s    Check If SSH Output Is Empty    exportfs -v|grep ${nfs_folder_name}    ${false}
    Switch Connection    127.0.0.1
    Execute Command Successfully    mkdir -p ${nfs_mount_point}; mount -t nfs @{PUBLICIP}[0]:/vol/${nfs_folder_name} ${nfs_mount_point}

Reading file should not trigger "copy on write"
    [Documentation]    Testlink ID:
    ...    Sc-472:Reading file should not trigger "copy on write"
    [Tags]    FAST
    # Read file should not be promoted
    Switch Connection    127.0.0.1
    SSH Output Should Be Equal    cat ${nfs_mount_point}/1.txt    origin_1
    Switch Connection    @{PUBLICIP}[0]
    Check If SSH Output Is Empty    ls /var/share/ezfs/shareroot/${nfs_folder_name}|grep origin_1    ${true}

Write old file to trigger "copy on write"
    [Documentation]    Testlink ID:
    ...    Sc-470:Write old file to trigger "copy on write"
    [Tags]    FAST 
    # Modified file should be promoted
    Switch Connection    127.0.0.1
    Execute Command Successfully    echo "Modify_2" >> ${nfs_mount_point}/2.txt
    Switch Connection    @{PUBLICIP}[0]
    SSH Output Should Contain    cat /var/share/ezfs/shareroot/${nfs_folder_name}/2.txt    Modify_2

Write new file to trigger "copy on write"
    [Documentation]    Testlink ID:
    ...     Sc-469:Write new file to trigger "copy on write"
    [Tags]    TOFT
    # New write file should also be saved in cluster
    Switch Connection    127.0.0.1
    Execute Command Successfully    echo "Write new file when copy on write" > ${nfs_mount_point}/new_copy_on_write.txt
    Switch Connection    @{PUBLICIP}[0]
    SSH Output Should Be Equal    cat /var/share/ezfs/shareroot/${nfs_folder_name}/new_copy_on_write.txt    Write new file when copy on write
    
Rename file to trigger "copy on write"
    [Documentation]    Testlink ID:
    ...     Sc-471:Rename file to trigger "copy on write"
    [Tags]    TOFT
    # Renamed file should be promoted
    Switch Connection    127.0.0.1
    Execute Command Successfully    mv ${nfs_mount_point}/3.txt ${nfs_mount_point}/3_rename.txt
    Switch Connection    @{PUBLICIP}[0]
    SSH Output Should Be Equal    cat /var/share/ezfs/shareroot/${nfs_folder_name}/3_rename.txt    origin_3

Remove files after the file is migrated
    [Documentation]    Testlink ID:
    ...    Sc-478:Remove files after the file is migrated
    [Tags]    TOFT
    Switch Connection    127.0.0.1
    Execute Command Successfully    rm -f ${nfs_mount_point}/2.txt
    Switch Connection    @{PUBLICIP}[0]
    Check If SSH Output Is Empty    ls /var/share/ezfs/shareroot/${nfs_folder_name}/2.txt    ${true}

Start backend migration in case of "copy on write"
    [Documentation]    Testlink ID:
    ...    Sc-473:Start backend migration in case of "copy on write"
    [Tags]    FAST
    Start NAS Migration    ${vs_name}    ${nfs_folder_name}
    Wait Until Keyword Succeeds    3m    5s    Migrated Files Number Is    ${nfs_folder_name}    ${total_file_num}
    Terminate NAS Migration    ${vs_name}    ${nfs_folder_name}
    [Teardown]    Run Keywords    Switch Connection    127.0.0.1
    ...           AND             Execute Command     umount ${nfs_mount_point}
    ...           AND             Delete Shared Folder    ${vs_name}    ${nfs_folder_name}
    
*** Keywords ***
Prepare External NAS
    Add Shared Folder    name=${external_nas_name}    gateway_group=${vs_name}    pool=${default_pool}
    Switch Connection    @{PUBLICIP}[0]
    Wait Until Keyword Succeeds    1m    5s    Check If SSH Output Is Empty    exportfs -v|grep ${external_nas_name}   ${false}
    Wait Until Keyword Succeeds    1m    5s    Check If SSH Output Is Empty    cat /etc/samba/smb.conf|grep ${external_nas_name}    ${false}
    Execute Command Successfully    cd /vol/${external_nas_name}; for i in `seq ${small_file_num}`;do echo "origin_"$i > $i.txt;chmod 777 $i.txt;done;for i in `seq ${big_file_num}`;do dd if=/dev/zero of="10M_$i.dat" bs=1M count=10 oflag=direct;done

Delete External NAS
    Delete Shared Folder    ${vs_name}    ${external_nas_name}

Start NAS Migration
    [Arguments]    ${vs_name}    ${folder_name}    ${max_bw}=0
    Return Code Should be 0    /cgi-bin/ezs3/json/folder_migration_start?vs_id=${vs_name}&name=${folder_name}&max_bw=${max_bw}

Get NAS Migration Status
    [Arguments]    ${vs_name}    ${folder_name}
    ${ret} =   Get Json Path Value    /cgi-bin/ezs3/json/folder_migration_get_status?vs_id=${vs_name}&name=${folder_name}    /response/status
    [Return]    ${ret}

Suspend NAS Migration
    [Arguments]    ${vs_name}    ${folder_name}
    Return Code Should be 0    /cgi-bin/ezs3/json/folder_migration_suspend?vs_id=${vs_name}&name=${folder_name}

Terminate NAS Migration
    [Arguments]    ${vs_name}    ${folder_name}
    Return Code Should be 0    /cgi-bin/ezs3/json/folder_migration_terminate?vs_id=${vs_name}&name=${folder_name}

NAS Migration is Finished
    [Arguments]    ${vs_name}    ${nfs_folder_name}
    ${status} =    Get NAS Migration Status    ${vs_name}    ${nfs_folder_name}
    Should Be Equal    ${status}    "done"

Get Migrated Files Number
    [Arguments]    ${migrate_dest}
    Switch Connection    @{PUBLICIP}[0]
    ${ret} =    Execute Command    ls /var/share/ezfs/shareroot/${migrate_dest} 2>/dev/null|wc -l
    [Return]    ${ret}

Migrated Files Are More Than
    [Arguments]    ${migrate_dest}    ${expected_num}
    ${output} =    Get Migrated Files Number    ${migrate_dest}
    Should Be True    ${output} > ${expected_num}

Migrated Files Number Is
    [Arguments]    ${migrate_dest}    ${expected_num}
    ${output} =    Get Migrated Files Number    ${migrate_dest}
    Should Be Equal    ${output}    ${expected_num}
