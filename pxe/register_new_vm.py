#!/usr/bin/env python
import argparse
import json
import subprocess
import os

'''
Register a new node in PXE environment, below is a sample of INFILE which is mandatory:
[
    {
        "hostname":        "auto-70-1",
        "version":         "7.0",
        "pxe_mac":         "00:50:56:a7:0f:e4",
        "pxe_filename":    "pxelinux.7",
        "os_disk":         "/dev/sda",
        "pxelinux.cfg":    {
            "bootpath":    "bigtera70",
            "pxeint":      "eth2",
            "httpurl":     "192.168.200.1",
            "aoecdrom":    "e2.0"
        },
        "netconf": [
            {
                "iface":       "ens160",
                "address":     "172.17.59.105",
                "netmask":     "255.255.254.0",
                "gateway":     "172.17.59.254",
                "dns-nameservers": "114.114.114.114"
            },
            {
                "iface":       "ens192",
                "address":     "192.168.100.105",
                "netmask":     "255.255.255.0"
            }
        ]
    }
]
'''

def GetArgs():
    parser = argparse.ArgumentParser(description='Register new node in PXE environment')
    parser.add_argument('-i', '--infile', type=argparse.FileType('r'), 
                        required=True)
    args = parser.parse_args()
    data = json.load(args.infile)
    args.infile.close()
    return data

def ModifyDHCPConf(vm):
    dhcp_conf = "/etc/dhcp/dhcpd.conf"
    subprocess.call(["sed","-i","/host " + vm["hostname"] + "/,+3d", dhcp_conf])
    subprocess.call(["sed","-i","/option broadcast-address/a\    host " + vm["hostname"] + " {\\n        hardware ethernet " + vm["pxe_mac"] + ";\\n        filename \"" + vm["pxe_filename"] + "\";\\n    }", dhcp_conf])
    return

def GeneratePXEConf(vm):
    template_path = "tftpboot/pxelinux.cfg/template"
    target_file_name = "01-" + vm["pxe_mac"].replace(":", "-")
    target_path = "/var/lib/tftpboot/pxelinux.cfg/" + target_file_name
    if not os.path.exists(os.path.dirname(target_path)):
        os.makedirs(os.path.dirname(target_path))
    try:
        with open(template_path, 'r') as source, open(target_path, 'w') as target:
            scontent = source.read()
            tcontent = scontent.replace("BOOTPATH_TOKEN", vm["pxelinux.cfg"]["bootpath"]) \
                               .replace("HOSTNAME_TOKEN", vm["hostname"]) \
                               .replace("INT_TOKEN", vm["pxelinux.cfg"]["pxeint"]) \
                               .replace("URL_TOKEN", vm["pxelinux.cfg"]["httpurl"]) \
                               .replace("VERSION_TOKEN", vm["version"]) \
                               .replace("AOE_TOKEN", vm["pxelinux.cfg"]["aoecdrom"])
            target.write(tcontent)
            print 'Generate pxelinux.cfg for {}: {}'.format(vm["hostname"], target_path)
    except IOError as e:
            print 'Generate pxelinux.cfg for {} failed: {}!'.format(vm["hostname"], e.strerror)
    return

def GenerateNetConf(vm):
    target_path = "/var/lib/tftpboot/netconf/{}/interfaces_{}".format(vm["version"], vm["hostname"])
    if not os.path.exists(os.path.dirname(target_path)):
        os.makedirs(os.path.dirname(target_path))
    try:
        with open(target_path, 'w') as target:
            int_list = []
            tcontent = 'iface lo inet loopback\n'
            for net in vm["netconf"]:
                int_list.append(net["iface"])
                tcontent += "iface {} inet static\n".format(net["iface"])
                for key, value in net.iteritems():
                    if key == "iface":
                        continue
                    tcontent += "    {} {}\n".format(key, value)
            tcontent = "auto lo {}\n".format(' '.join(int_list)) + tcontent
            target.write(tcontent)
            print 'Generate netconf for {}: {}'.format(vm["hostname"], target_path)
    except IOError as e:
            print 'Generate netconf for {} failed: {}!'.format(vm["hostname"], e.strerror)
    return

def GeneratePreseed(vm):
    template_path = "tftpboot/preseed/{}/template.seed".format(vm["version"])
    target_path = "/var/lib/tftpboot/preseed/{}/ubuntu-ezs3-{}.seed".format(vm["version"], vm["hostname"])
    if not os.path.exists(os.path.dirname(target_path)):
        os.makedirs(os.path.dirname(target_path))
    try:
        with open(template_path, 'r') as source, open(target_path, 'w') as target:
            scontent = source.read()
            tcontent = scontent.replace("OS_DISK_TOKEN", vm["os_disk"]) \
                               .replace("HOSTNAME_TOKEN", vm["hostname"]) \
                               .replace("HTTPSERVER_TOKEN", vm["pxelinux.cfg"]["httpurl"])
            target.write(tcontent)
            print 'Generate preseed for {}: {}'.format(vm["hostname"], target_path)
    except IOError as e:
            print 'Generate preseed for {} failed: {}!'.format(vm["hostname"], e.strerror)
    return

def main():
    vms = GetArgs()
    for vm in vms:
        ModifyDHCPConf(vm)
        GeneratePXEConf(vm)
        GenerateNetConf(vm)
        GeneratePreseed(vm)
    subprocess.call(["/etc/init.d/isc-dhcp-server","restart"])
    
if __name__ == "__main__":
    main()
