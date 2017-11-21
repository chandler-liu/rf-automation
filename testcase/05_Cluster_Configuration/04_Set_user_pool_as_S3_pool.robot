*** Settings ***
Documentation     This suite includes cases related to general cases about Set user pool as S3 pool
Suite Setup       Config S3Config    s3_account
Suite Teardown    Run Keywords    Delete Bucket    s3://bucketAutomation
...               AND    Delete User and Clean s3cfg    s3_account
Resource          ../00_commonconfig.txt
Resource          ../00_commonkeyword.txt
Resource          00_clusterconfigurationkeywords.txt

*** Test Cases ***
Check default S3 pool
    [Documentation]    TestLink ID: Sc-262:Check default S3 pool
    [Tags]    RAT
    ${bucket_name}=    Set Variable    s3://bucketAutomation
    Create Bucket    ${bucket_name}
    log    Get objects in pool
    ${objects_before}=    Get Objects By Pool    .rgw.buckets.data
    log    Start to put data to bucket
    Input Data To Bucket
    log    Get objects in pool again
    ${objects_after}=    Get Objects By Pool    .rgw.buckets.data
    log    Check default S3 pool
    Should be True    ${objects_after}>${objects_before}

Set user pool as S3 pool against default pool
    [Documentation]    TestLink ID: Sc-263:Set user pool as S3 pool against default pool
    [Tags]    RAT
    ${bucket_name}=    Set Variable    s3://bucketAutomation
    ${pool_name}=    Set Variable    S3-pool
    log    Create a S3 pool
    Create Pool    1    ${pool_name}
    Add OSD To Pool    ${pool_name}    0+1+2
    Wait Until Keyword Succeeds    6 min    5 sec    Get Cluster Health Status
    log    Set user pool as S3 pool
    Return Code Should Be 0    /cgi-bin/ezs3/json/pool_enable_s3?pool_name=${pool_name}
    Wait Until Keyword Succeeds    6 min    5 sec    Get S3 Pool State    ${pool_name}
	Sleep    10 sec
    Create Bucket    ${bucket_name}
    log    Get objects in pool
    ${objects_before}=    Get Objects By Pool    ${pool_name}
    log    Start to put data to bucket
    Input Data To Bucket
    log    Get objects in pool again
    ${objects_after}=    Get Objects By Pool    ${pool_name}
    log    Check default S3 pool
    Should be True    ${objects_after}>${objects_before}
    [Teardown]    Set Default To S3 Pool And Delete User Pool

*** Keywords ***
Set Default To S3 Pool And Delete User Pool
    log    To delete pool, need to Set other pool as S3 pool
    Return Code Should Be 0    /cgi-bin/ezs3/json/pool_enable_s3?pool_name=Default
	Run Keyword    Delete Pool    S3-pool