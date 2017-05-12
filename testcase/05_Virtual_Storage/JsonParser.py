#!/usr/bin/env python

from __future__ import print_function

import json
import urllib
import sys

class Usage(Exception):
    def __init__(self, msg):
        self.msg = msg

class JsonParser:
    ROBOT_LIBRARY_SCOPE = 'GLOBAL'

    def search_key_value(self, searchKey, searchValue, srcJson):
        #Search dict Key match special Value in Json, return match dict
        encodeJson = json.dumps(srcJson)
        decodeJson = json.loads(encodeJson)
#        print("A:{}".format(decodeJson.items()))
#        print("B:{}".format(decodeJson.keys()))
#        print("C:{}".format(decodeJson.values()))

        searchResult={}

        for item in decodeJson:
            if decodeJson[item][searchKey] in searchValue:
                searchResult.update({item:decodeJson[item]})
        print("result:{}".format(searchResult))

        return searchResult

    def query_key(self, srcJson):
        #Return dict Key for input Json
        encodeJson = json.dumps(srcJson)
        decodeJson = json.loads(encodeJson)

        return decodeJson.keys()

    def query_keyword_value(self, searchKey, srcJson):
        #Return the value for match keyword
        encodeJson = json.dumps(srcJson)
        decodeJson = json.loads(encodeJson)

        searchResult=[]

        for item in decodeJson:
            searchResult.append(decodeJson[item][searchKey])

        return searchResult

    def url_encode(self, datalist):
        urlencode = urllib.quote(json.dumps(datalist))
        return urlencode


def main(argv=None):
    if argv is None:
        argv = sys.argv

    print(argv)
#    searchKey = argv[1]
    searchKey = "group_name"
#    searchValue = argv[2]
    searchValue = "GroupA"
    srcJson = {"2c8d4aeb-52c6-44e2-8969-50c64f8ed5b1": {"initiator_list": [{"name":"iqn.2022-12.com.bigtera:01:1234567890ab","alias":"robot test"}], "protocol": "iscsi", "group_name": "GroupA"}, "507d35ee-ec4a-4f8f-b794-2ebaf50befba": {"protocol": "iscsi", "initiator_list": [], "group_name": "GroupB"}}
#    srcJson = {u'76f03dc1-319e-4351-872c-31fa98a11d76': {u'protocol': u'iscsi', u'initiator_list': [], u'group_name': u'GroupB'}, u'2e439cdc-42e5-4c75-9c21-00768d605af6': {u'initiator_list': [], u'protocol': u'iscsi', u'group_name': u'GroupA'}}

    jp = JsonParser()
    value = jp.search_key_value(searchKey,searchValue,srcJson)
    print("Return Value:{}".format(value))
    key = jp.query_key(value)
    print("Return Key:{}".format(key))
    data = jp.query_keyword_value('initiator_list',value)
    print("Protocol:{}".format(data))
    webencode = jp.url_encode(data[0])
    print("Webencode:{}".format(webencode))



# Start program
if __name__ == "__main__":
    sys.exit(main())


