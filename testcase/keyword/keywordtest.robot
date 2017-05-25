*** Settings ***
Suite Setup         Network Setup
Suite Teardown      Network Teardown
Library             OperatingSystem
Library             HttpLibrary.HTTP
Library             SSHLibrary
Resource            ./defaultconfig.txt
Resource            ./keyword_cgi.txt
Resource            ./keyword_system.txt
Resource            ./keyword_verify.txt
Resource            ../00_commonconfig.txt
*** Test Cases ***
01_SetupTeardown
    ${rbd}=    Get RBD Image Name    target_id=iqn.2016-01.bigtera.com:auto    volume_name=vol1
*** Keywords ***

