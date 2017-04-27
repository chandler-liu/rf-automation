*** Settings ***
Documentation          This robot is to install vm in ESXi server and then deploy the ISO
Resource               ../00_commonconfig.txt
Resource               ../00_commonkeyword.txt
Library                ./EsxiServer.py    ${ESXHOSTIP}  ${ESXUSER}  ${ESXPASS}
Library                HttpLibrary.HTTP
Library                SSHLibrary

*** Variables ***
${disk_size_gb}        20
${disk_count}          5
${delete_start}        1
${disk_type}           thin
#${delete_vmdk_cmd}     cd /vmfs/volumes/539f2d1f-98e6569e-6d03-60eb69a5a98c; rm -f auto-1/*.vmdk; rm -f auto-2/*.vmdk; rm -f auto-3/*.vmdk;
${modify_ssh_config}   sed -i.bak 's/^#\ \ \ StrictHostKeyChecking ask/\ \ \ \ StrictHostKeyChecking no/' /etc/ssh/ssh_config
${start_web_cmd}       python -c "from ezs3.utils import start_web_ui,start_freenode_service;start_web_ui();start_freenode_service()"
${create_cfg_cmd}      python -c "from ezs3.config import Ezs3CephConfig; Ezs3CephConfig()"
${debug_cmd}           touch /root/chandler_debug

*** Test Cases ***
Install ISO on ESXi
    [Documentation]  Fresh install ISO in 3 VMs in the way of PXE
    [Tags]  install
    Destroy and Reinstall VM

Make Sure All Nodes are Installed and Ready
    [Documentation]  Check if http can work to determine if install is finished, then do some init
    [Tags]  install
    Wait HTTP Service Ready


*** Keywords ***
Destroy and Reinstall VM
    :FOR    ${vm}    IN    @{VMNAMES}
    \    Power VM    poweroff    ${vm}
    \    Delete Disk From VM    ${vm}    ${delete_start}
    \    Add Disk To VM    ${vm}    ${disk_size_gb}  ${disk_type}  ${disk_count}
    \    Power VM    poweron    ${vm}

Wait HTTP Service Ready
    :FOR    ${ip}   IN    @{PUBLICIP}
    \       Wait Until Keyword Succeeds  30m  30s  GET  http://${ip}
    \       Wait Until Keyword Succeeds  2m  5s  Open Connection    ${ip}
    \       Wait Until Keyword Succeeds  2m  5s  Login    ${USERNAME}    ${PASSWORD}
    \       Modify System Config

Modify System Config
    Execute Command Successfully  ${modify_ssh_config}
    Execute Command Successfully  ${start_web_cmd}
    Execute Command Successfully  ${create_cfg_cmd}
    Execute Command Successfully  ${debug_cmd}
