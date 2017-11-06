#!/usr/bin/env python
import argparse
import json
import subprocess
import os

'''
Register a new node in PXE environment, below is a sample of INFILE which is mandatory:
[
    {
        "hostname":        "auto-161",
        "version":         "6.3",
        "pxe_mac":         "01:02:03:04:05:06",
        "pxe_filename":    "pxelinux.7",
        "pxelinux.cfg":    {
            "vesamenu":    "bigtera60/vesamenu.c32",
            "vmlinuz":     "bigtera60/vmlinuz",
            "initrd":      "bigtera60/initrd.aoecdrom.gz",
            "pxeint":      "eth2",
            "httpurl":     "192.168.200.1",
            "aoecdrom":    "e1.0"
        },
        "netconf": {
            "pub_ip":      "17.16.146.161",
            "pub_mask":    "255.255.255.0",
            "pub_dev":     "eth0",
            "pub_gw":      "17.16.146.1",
            "dns_ip":      "114.114.114.114",
            "stor_ip":     "10.10.10.161",
            "stor_mask":   "255.255.255.0",
            "stor_dev":    "eth1"
        }
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
    subprocess.call(["/etc/init.d/isc-dhcp-server","restart"])
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
            tcontent = scontent.replace("VESAMENU_TOKEN", vm["pxelinux.cfg"]["vesamenu"]) \
                               .replace("VMLINUZ_TOKEN", vm["pxelinux.cfg"]["vmlinuz"]) \
                               .replace("INITRD_TOKEN", vm["pxelinux.cfg"]["initrd"]) \
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
    template_path = "tftpboot/netconf/template"
    target_path = "/var/lib/tftpboot/netconf/{}/interfaces_{}".format(vm["version"], vm["hostname"])
    if not os.path.exists(os.path.dirname(target_path)):
        os.makedirs(os.path.dirname(target_path))
    try:
        with open(template_path, 'r') as source, open(target_path, 'w') as target:
            scontent = source.read()
            tcontent = scontent.replace("PUBDEV", vm["netconf"]["pub_dev"]) \
                               .replace("STORDEV", vm["netconf"]["stor_dev"]) \
                               .replace("PUBIP", vm["netconf"]["pub_ip"]) \
                               .replace("PUBMASK", vm["netconf"]["pub_mask"]) \
                               .replace("PUBGW", vm["netconf"]["pub_gw"]) \
                               .replace("DNSIP", vm["netconf"]["dns_ip"]) \
                               .replace("STORIP", vm["netconf"]["stor_ip"]) \
                               .replace("STORMASK", vm["netconf"]["stor_mask"])
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
            tcontent = scontent.replace("HOSTNAME_TOKEN", vm["hostname"])
            tcontent = scontent.replace("HTTPSERVER_TOKEN", vm["pxelinux.cfg"]["httpurl"])
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
    
if __name__ == "__main__":
    main()
