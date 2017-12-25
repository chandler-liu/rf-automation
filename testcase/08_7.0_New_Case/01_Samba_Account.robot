*** Settings ***
Documentation     This suite includes cases related to Samba Account
Suite Setup       Run Keywords    Open HTTP Connection And Log In    @{PUBLICIP}[0]    ${UIADMIN}    ${UIPASS}
...               AND    Open All SSH Connections    ${USERNAME}    ${PASSWORD}    @{PUBLICIP}
...               AND    Open Connection    127.0.0.1    alias=127.0.0.1
Suite Teardown    Close All Connections
Resource          ../00_commonconfig.txt
Resource          ../keyword/keyword_verify.txt
Resource          ../keyword/keyword_system.txt
Resource          ../keyword/keyword_cgi.txt


*** Variables ***
${account_name}    sambatest1
${account_password}    sambapasswd1
${folder_name}    sambatestfolder
${vs_name}    Default
${cifs_mount_point}    /mnt/cifs

*** Test Cases ***
Create new samba account 
	[Documentation]    TestLink ID: Sc-1155:Create new samba account
    [Tags]    RAT
    Add A Samba Account
	Add A CIFS Shared Folder
	Add The Samba Account To Allow List
	Client Mount Folder Successfully
    [Teardown]    Run Keywords    Client Umount Folder
	...    AND    Remove The Folder
	...    AND    Remove The Account

*** Keywords ***
Add A Samba Account
    Run Keyword    Add Samba Account    ${vs_name}    ${account_name}    ${account_password}    ${account_password}    ${account_name}
	Wait Until Keyword Succeeds    4 min    5 sec    Check Samba Account Exist UI    ${vs_name}    ${account_name}
	
Add A CIFS Shared Folder
    Run Keyword    Add Shared Folder    name=${folder_name}
	
Add The Samba Account To Allow List
    Run Keyword    Edit Shared Folder    name=${folder_name}    ${user_list}=${account_name}
	Wait Until Keyword Succeeds    4 min    5 sec    Check Samba Account Exist ACL UI    ${vs_name}    ${account_name}    ${folder_name}
	
Client Mount Folder Successfully
	Run Keyword    Client Mount CIFS Folder    ${cifs_mount_point}    ${user_id}    ${account_password}    ${folder_name}
	
Client Umount Folder
    Run Keyword    Client Umont CIFS Folder    ${cifs_mount_point}
	
Remove The Folder
    [Arguments]    ${folder_name}
	Run Keyword    Delete Shared Folder    ${vs_name}    ${folder_name}
	
Remove The Account
    [Arguments]    ${account_name}
	Run Keyword    Delete Samba Account    ${vs_name}    ${account_name}
	Wait Until Keyword Succeeds    4 min    5 sec    Check Samba Account Exist UI    ${vs_name}    ${account_name}
	
