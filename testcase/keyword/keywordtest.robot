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


*** Variables ***
${vs_name}                          Default
${default_pool}                     Default
${gateway_group}                    Default
${iscsi_target_name}                iqn.2016-01.bigtera.com:auto
${iscsi_target_name_urlencoding}    iqn.2016-01.bigtera.com%3Aauto
${iscsi_group01}                    iSCSI_Initiator_Group_01
${iscsi_group02}                    iSCSI_Initiator_Group_02
${iscsi_group03}                    iSCSI_Initiator_Group_03
${fc_group01}                       FC_Initiator_Group_01
${fc_group02}                       FC_Initiator_Group_02
${iscsi_initiator_name01}           iqn.2022-12.com.bigteratest1:01:1111111111ab
${iscsi_initiator_name02}           iqn.2022-12.com.bigteratest2:02:2222222222cd
${iscsi_initiator_name03}           iqn.2022-12.com.bigteratest3:03:3333333333ef
&{iscsi_initiator_name_dict}        name=${iscsi_initiator_name01}    alias=robot test
@{iscsi_initiator_name_list}        &{iscsi_initiator_name_dict}
${iscsi_volume_name}                lun1
${iscsi_volume_size}                5368709120
${read_maxbw_M}                     5
${read_maxbw_bytes}                 5242750
${read_maxiops}                     50
${write_maxbw_M}                    5
${write_maxbw_bytes}                5242750
${write_maxiops}                    50
${osd_name}                         Disk
@{osd_name_list}                    ${osd_name}
@{data_dev}                         /dev/sdb
@{data_devs}                        /dev/sdc    /dev/sdd

*** Test Cases ***
01_KeywordExample
    Create OSD Role    public_ip=@{PUBLICIP}[0]    storage_ip=@{STORAGEIP}[0]    osd_name=${osd_name}    data_dev=${data_dev}
    CGI Storage Volume Add    host=@{PUBLICIP}[0]    name=${osd_name}    data_devs=${data_devs}    sv_type=0
02_KeywordExample
    Disable OSD    storage_ip=@{STORAGEIP}[0]    osd_name=${osd_name}
    Enable OSD    public_ip=@{PUBLICIP}[0]    storage_ip=@{STORAGEIP}[0]    osd_name=${osd_name}    pool_to_join=${default_pool}    add_metadata_pool=false
03_KeywordExample
    Remove OSD    storage_ip=@{STORAGEIP}[0]    osd_name=${osd_name}
#    CGI Storage Volume Remove    storage_ip=@{STORAGEIP}[0]    osd_name=${osd_name_list}
*** Keywords ***

