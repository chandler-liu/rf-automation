#!/usr/bin/env python

from __future__ import print_function

from time import sleep

import glob
import subprocess
import os
import sys

def main(argv=None):
    if argv is None:
        argv = sys.argv

    path_source = {
        "path_scaler_6_2" : "/root/mount/nfsserver/precise/virtualstor_scaler_6.2/builds/",
        "path_scaler_6_3" : "/root/mount/nfsserver/precise/virtualstor_scaler_6.3/builds/",
        "path_scaler_7_0" : "/root/mount/nfsserver/trusty/virtualstor_scaler_master/builds/",
        "path_ctrl_6_1" : "/root/mount/nfsserver/precise/virtualstor_sds_controller_6.1/builds/",
        "path_ctrl_6_2" : "/root/mount/nfsserver/precise/virtualstor_sds_controller_6.2/builds/",
        "path_ctrl_6_3" : "/root/mount/nfsserver/precise/virtualstor_sds_controller_6.3/builds/",
        "path_ctrl_7_0" : "/root/mount/nfsserver/trusty/virtualstor_sds_controller_master/builds/"
    }

    path_image = "/root/image/"
    error = ""
    shelf = 11
    slot = 1

    for version,path in path_source.items():
        src_filename = max(glob.glob(path+"/*/*.iso"))
        dst_filename = path_image+src_filename.split(" ")[-1].split("~")[0]+".iso"

        print (src_filename)

        subprocess.call(["rsync","-avzP",src_filename,dst_filename])

        if "scaler" in version:
            shelf = "11"
        elif "ctrl" in version:
            shelf = "12"

        if "6_2" in version:
            slot = "1"
        elif "6_3" in version:
            slot = "2"
        elif "7_0" in version:
            slot = "3"
        elif "6_1" in version:
            slot = "4"

        while "is not a vblade-persist-managed export" not in error:
            process = subprocess.Popen(["vblade-persist","destroy",shelf,slot], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            process.wait()
            outout,error = process.communicate()

        subprocess.call(["vblade-persist","setup",shelf,slot,"ens192",dst_filename])
        while not os.path.isfile("/var/lib/vblade-persist/vblades/e"+shelf+"."+slot+"/supervise/status"):
            sleep(1)
        subprocess.call(["vblade-persist","start",shelf,slot])
        error = ""

# Start program
if __name__ == "__main__":
    sys.exit(main())

