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
        urlencode = urllib.quote(datalist)
        return urlencode

    def url_json_encode(self, datalist):
        urlencode = urllib.quote(json.dumps(datalist))
        return urlencode

def main(argv=None):
    if argv is None:
        argv = sys.argv

    sys.exit()


# Start program
if __name__ == "__main__":
    sys.exit(main())


