*** Settings ***
Documentation          This robot is to install vm in ESXi server and then deploy the ISO
Resource               ../00_commonconfig.txt
Resource               ../keyword/keyword_system.txt
Library                HttpLibrary.HTTP
Library                SSHLibrary
Library                ../pylibrary/EsxiServer.py    ${ESXHOSTIP}  ${ESXUSER}  ${ESXPASS}

*** Variables ***
${boot_size_gb}        64
${disk_size_gb}        40
${disk_count}          4
${delete_start}        1
#delete_start
#0 : Clean OS disk
#1 : Remove all disks
#2 : Remove all disks except OS disk
${disk_type}           thin
${debug_cmd}           touch /root/ready_flag

*** Test Cases ***
Install ISO on ESXi
    [Documentation]  Fresh install ISO in 3 VMs in the way of PXE
    [Tags]  install
    Destroy and Reinstall VM
    Make Sure All Nodes are Installed and Ready

*** Keywords ***
Destroy and Reinstall VM
    :FOR    ${vm}    IN    @{VMNAMES}
    \    Power VM    poweroff    ${vm}
    \    Delete Disk From VM    ${vm}    ${delete_start}
    \    Add Disk To VM    ${vm}    ${boot_size_gb}  ${disk_type}
    \    Add Disk To VM    ${vm}    ${disk_size_gb}  ${disk_type}  ${disk_count}
    \    Power VM    poweron    ${vm}

Make Sure All Nodes are Installed and Ready
    [Documentation]  Check if http can work to determine if install is finished
    :FOR    ${ip}   IN    @{PUBLICIP}
    \       Wait Until Keyword Succeeds  30m  30s  GET  https://${ip}:8080
    \       Wait Until Keyword Succeeds  2m  5s  Open Connection    ${ip}
    \       Wait Until Keyword Succeeds  2m  5s  Login    ${USERNAME}    ${PASSWORD}
    \       Execute Command Successfully  ${debug_cmd}

