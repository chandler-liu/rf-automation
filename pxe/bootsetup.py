#!/usr/bin/env python

from __future__ import print_function

import argparse
import glob
import subprocess
from subprocess import Popen, PIPE

def GetArgs():
    parser = argparse.ArgumentParser(description='Setup PXE version for Virtual Machine')
    parser.add_argument('-n', '--name', required=True, nargs='*', action='store', help='Names of Virtual Machines want to PXE')
    parser.add_argument('-v', '--version', required=True, action='store', help='VirtualStor Version: 6.1, 6.2, 6.3, 7.0')
    parser.add_argument('-p', '--product', required=True, action='store', help='VirtualStor Product: scaler, controller')
    parser.add_argument('-l', '--license', default=False, required=False, action='store', help='Auto install license: True, False')
    args = parser.parse_args()
    return args

def main():
    args = GetArgs()
    for vmname in args.name:
        output = glob.glob("/var/lib/tftpboot/pxelinux.cfg/"+args.product+"_"+args.version+"/*")
        for filename in output:
            p = Popen(["grep","-l",vmname,filename], stdout=PIPE, stderr=PIPE)
            stdout, stderr = p.communicate()
            if stdout != "":
                match = stdout.split("/")[-1].strip()
                mac = match[3:].replace("-", ":")
                subprocess.call(["cp","/var/lib/tftpboot/pxelinux.cfg/"+args.product+"_"+args.version+"/"+match,"/var/lib/tftpboot/pxelinux.cfg/"])
                if args.license in ( "True" , "true" ):
                    subprocess.call(["sed","-i","s/-wolicense.seed/-wtlicense.seed/g","/var/lib/tftpboot/pxelinux.cfg/"+match])
                else:
                    subprocess.call(["sed","-i","s/-wtlicense.seed/-wolicense.seed/g","/var/lib/tftpboot/pxelinux.cfg/"+match])

                if args.version in ( "6.1", "6.2", "6.3" ):
                    subprocess.call(["sed","-i","/host "+vmname+"/,+3d","/etc/dhcp/dhcpd.conf"])
                    subprocess.call(["sed","-i","/option broadcast-address/a\    host "+vmname+" {\\n        hardware ethernet "+mac+";\\n        filename \"pxelinux.6\";}","/etc/dhcp/dhcpd.conf"])
                elif args.version in ( "7.0" ):
                    subprocess.call(["sed","-i","/host "+vmname+"/,+3d","/etc/dhcp/dhcpd.conf"])
                    subprocess.call(["sed","-i","/option broadcast-address/a\    host "+vmname+" {\\n        hardware ethernet "+mac+";\\n        filename \"pxelinux.7\";}","/etc/dhcp/dhcpd.conf"])

# Start program
if __name__ == "__main__":
    main()
