#!/usr/bin/env python
#
# VMware vSphere Python SDK
# Copyright (c) 2008-2015 VMware, Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""
Python program for powering on vms on a host on which hostd is running
"""

from __future__ import print_function

from pyVim.connect import SmartConnect, Disconnect
from pyVmomi import vim, vmodl

import argparse
import atexit
import getpass
import sys
import ssl
import subprocess


def GetArgs():
    """
    Supports the command-line arguments listed below.
    """

    parser = argparse.ArgumentParser(description='Process args for control a Virtual Machine')
    parser.add_argument('-s', '--host', required=True, action='store', help='Remote host to connect to')
    parser.add_argument('-o', '--port', type=int, default=443, action='store', help='Port to connect on')
    parser.add_argument('-u', '--user', required=True, action='store', help='User name to use when connecting to host')
    parser.add_argument('-p', '--password', required=False, action='store', help='Password to use when connecting to host')
#Me define
    parser.add_argument('-a', '--action', required=True, nargs='*', action='store', help='Esxi virtual machine action')
    parser.add_argument('--size', type=int, required=False, action='store', help='virtual disk size')
    parser.add_argument('--num', type=int, default=1, required=False, action='store', help='virtual disk numbers')
    parser.add_argument('--type', default="thin", required=False, action='store', help='virtual disk type:thin/thick')
#Me define
#    parser.add_argument('-v', '--vmname', required=False, action='append', help='Names of the Virtual Machines to power on')
    parser.add_argument('-v', '--vmname', required=False, nargs='*', action='store', help='Names of the Virtual Machines to power on')
    args = parser.parse_args()
    return args

def action_parser(action):
    print(action) #Debug
    if len(action) > 0 and action[0] in ["poweron","poweroff","restart","lsvm","delete","adddisk"]:
        return action
    else:
        print("-a/--action to control esxi virtual machine\n\n"
              "  poweron            : to power on virtual machine\n"
              "  poweroff           : to power off virtual machine\n"
              "  restart            : to reset powered on virtual machine\n"
              "  lsvm               : to list virtual machine information\n"
              "  delete <all/reset> : to delete virtual machine data disk\n"
              "                     : all to delete all of disk include boot disk\n"
              "                     : reset to clean up OS boot disk\n"
              "  adddisk            : to add virtual disk to virtual machine\n"
              "    --size           : virtual disk size (GB)\n"
              "    --num            : number of disk to create\n"
              "    --type           : virtual type thin/thick\n")
        sys.exit()

class EsxiServer:
    ROBOT_LIBRARY_SCOPE = 'GLOBAL'
    def __init__(self, host, user, password, port=443):
        self.host = host
        self.user = user

        if password:
            self.password = password
        else:
            self.password = getpass.getpass(prompt='Enter password for host %s and user %s: ' % (host, user))

        self.si = None
        context = ssl.SSLContext(ssl.PROTOCOL_TLSv1)
        context.verify_mode = ssl.CERT_NONE
        try:
            self.si = SmartConnect(host=host,
                                   user=user,
                                   pwd=password,
                                   port=port,
                                   sslContext=context)
        except IOError:
            pass
        if not self.si:
            print("Cannot connect to specified host using specified username and password")
            sys.exit()

        atexit.register(Disconnect, self.si)

    def parser_vmname(self, vmnames):

        findvmnames=[]
        content = self.si.content
        objView = content.viewManager.CreateContainerView(content.rootFolder,
                                                          [vim.VirtualMachine],
                                                          True)
        vmList = objView.view
        objView.Destroy()
        for vm in vmList:
            if vm.name in vmnames:
                findvmnames.append(vm.name)
                vmnames.remove(vm.name)
        if not vmnames == []:
            print("Virtual machine {} is not exist".format(vmnames))
        return findvmnames

    def _wait_for_tasks(self, tasks):
        """
        Given the service instance si and tasks, it returns after all the
        tasks are complete
        """

        pc = self.si.content.propertyCollector

        tasklist = [str(task) for task in tasks]

        # Create filter
        objSpecs = [vmodl.query.PropertyCollector.ObjectSpec(obj=task)
                    for task in tasks]
        propSpec = vmodl.query.PropertyCollector.PropertySpec(type=vim.Task,
                                                              pathSet=[], all=True)
        filterSpec = vmodl.query.PropertyCollector.FilterSpec()
        filterSpec.objectSet = objSpecs
        filterSpec.propSet = [propSpec]
        filter = pc.CreateFilter(filterSpec, True)

        try:
            version, state = None, None

            # Loop looking for updates till the state moves to a completed state.
            while len(tasklist):
                update = pc.WaitForUpdates(version)
                for filterSet in update.filterSet:
                    for objSet in filterSet.objectSet:
                        task = objSet.obj
                        for change in objSet.changeSet:
                            if change.name == 'info':
                                state = change.val.state
                            elif change.name == 'info.state':
                                state = change.val
                            else:
                                continue

                            if not str(task) in tasklist:
                                continue

                            if state == vim.TaskInfo.State.success:
                                # Remove task from tasklist
                                tasklist.remove(str(task))
                            elif state == vim.TaskInfo.State.error:
                                raise task.info.error
                # Move to next version
                version = update.version
        finally:
            if filter:
                filter.Destroy()

    def power_vm(self, powerop, vmnames = None):

        if vmnames is None or vmnames == []:
            print("No virtual machine specified for power {}".format(powerop))
            return

        try:
            # Retreive the list of Virtual Machines from the inventory objects
            # under the rootFolder
            content = self.si.content
            objView = content.viewManager.CreateContainerView(content.rootFolder,
                                                              [vim.VirtualMachine],
                                                              True)
            vmList = objView.view
            objView.Destroy()

            # Find the vm and power it on/off/reset
            if powerop == "poweron":
                for vm in vmList:
                    if vm.name in vmnames and vm.summary.runtime.powerState == "poweredOn":
                        print("Virtual Machine {} already power on".format(vm.name))
                        vmnames.remove(vm.name)
                if vmnames == []:
                    print("No virtual machine need operation")
                    return
                else:
                    tasks = [vm.PowerOn() for vm in vmList if vm.name in vmnames]
            elif powerop == "poweroff":
                for vm in vmList:
                    if vm.name in vmnames and vm.summary.runtime.powerState == "poweredOff":
                        print("Virtual Machine {} already power off".format(vm.name))
                        vmnames.remove(vm.name)
                if vmnames == []:
                    print("No virtual machine need operation")
                    return
                else:
                    tasks = [vm.PowerOff() for vm in vmList if vm.name in vmnames]
            elif powerop == "restart":
                for vm in vmList:
                    if vm.name in vmnames and not vm.summary.runtime.powerState == "poweredOn":
                        print("Virtual Machine {} is not power on status".format(vm.name))
                        vmnames.remove(vm.name)
                if vmnames == []:
                    print("No virtual machine need operation")
                    return
                else:
                    tasks = [vm.Reset() for vm in vmList if vm.name in vmnames]

            # Wait for power on to complete
            self._wait_for_tasks(tasks)

            print("Virtual Machine {} have been {} successfully".format(vmnames,powerop))

        except vmodl.MethodFault as e:
            print("Caught vmodl fault : " + e.msg)

        except Exception as e:
            print("Caught Exception : " + str(e))

    def _delete_virtual_disk(self, vm_obj, disk_number):
        """ Deletes virtual Disk based on disk number
        :param si: Service Instance
        :param vm_obj: Virtual Machine Object
        :param disk_number: Hard Disk Unit Number
        :return: True if success
        """

        #Reset boot disk only, doesn't customize for Robot Framework
        if disk_number == 0:
            for dev in vm_obj.config.hardware.device:
                if isinstance(dev, vim.vm.device.VirtualDisk) \
                        and dev.deviceInfo.label == 'Hard disk 1':
                    vmdk_path = dev.backing.fileName.split()
                    vmdkPath = "/vmfs/volumes/"+vmdk_path[0][1:][:-1]+"/"+vmdk_path[1]

                    subprocess.call(["ssh",self.user+"@"+self.host,"vmkfstools","--deletevirtualdisk",vmdkPath])
                    if dev.backing.thinProvisioned == True:
                        subprocess.call(["ssh",self.user+"@"+self.host,"vmkfstools","--createvirtualdisk",str(int(dev.capacityInKB)*1024),"--diskformat","thin",vmdkPath])
                    elif dev.backing.eagerlyScrub == True:
                        subprocess.call(["ssh",self.user+"@"+self.host,"vmkfstools","--createvirtualdisk",str(int(dev.capacityInKB)*1024),"--diskformat","eagerzeroedthick",vmdkPath])
                    else:
                        subprocess.call(["ssh",self.user+"@"+self.host,"vmkfstools","--createvirtualdisk",str(int(dev.capacityInKB)*1024),"--diskformat","zeroedthick",vmdkPath])
            print('Reset the boot disk on {}\n'.format(vm_obj.name))
            return False

        hdd_prefix_label = 'Hard disk '
        hdd_label = hdd_prefix_label + str(disk_number)
        virtual_hdd_device = None
        for dev in vm_obj.config.hardware.device:
            if isinstance(dev, vim.vm.device.VirtualDisk) \
                    and dev.deviceInfo.label == hdd_label:
                virtual_hdd_device = dev
        if not virtual_hdd_device:
            print('All of the hard disk on {} is removed!\n'.format(vm_obj.name))
            return False
        virtual_hdd_spec = vim.vm.device.VirtualDeviceSpec()
        virtual_hdd_spec.operation = \
            vim.vm.device.VirtualDeviceSpec.Operation.remove
        virtual_hdd_spec.fileOperation = "destroy"
        virtual_hdd_spec.device = virtual_hdd_device
        spec = vim.vm.ConfigSpec()
        spec.deviceChange = [virtual_hdd_spec]
        task = vm_obj.ReconfigVM_Task(spec=spec)
        self._wait_for_tasks([task])
        return True

    def delete_disk_from_vm(self, vmnames, delete_start):

        if vmnames is None or vmnames == []:
            print("No virtual machine can be operation")
            return False

        content = self.si.content
        objView = content.viewManager.CreateContainerView(content.rootFolder,
                                                          [vim.VirtualMachine],
                                                          True)
        vmList = objView.view
        objView.Destroy()
        print('Check VM {} power status'.format(vmnames))
        for vm in vmList:
            if vm.name in vmnames:
                if vm.summary.runtime.powerState == "poweredOff":
                    print('Delete VM {} virtual disk'.format(vm.name))
                    disk_number=int(delete_start)
                    while self._delete_virtual_disk(vm, delete_start): # After delete, disk is renumbered, so is always start from 1
                        print ('VM HDD "{}" successfully deleted.'.format(disk_number))
                        disk_number += 1
                else:
                    print('VM {} is not powered off'.format(vm.name))
        return True

    def _add_controller(self, vm, bus_number = -1):
        scsi_ctr_spec = vim.vm.device.VirtualDeviceSpec()
        scsi_ctr_spec.operation = vim.vm.device.VirtualDeviceSpec.Operation.add
        scsi_ctr_spec.device = vim.vm.device.VirtualLsiLogicSASController()
        scsi_ctr_spec.device.deviceInfo = vim.Description()
        scsi_ctr_spec.device.busNumber = bus_number + 1
        scsi_ctr_spec.device.hotAddRemove = True
        scsi_ctr_spec.device.sharedBus = 'noSharing'
        scsi_ctr_spec.device.scsiCtlrUnitNumber = 7
        spec = vim.vm.ConfigSpec()
        spec.deviceChange = [scsi_ctr_spec]
        task = vm.ReconfigVM_Task(spec=spec)

        self._wait_for_tasks([task])

        for dev in vm.config.hardware.device:
            if isinstance(dev, vim.vm.device.VirtualSCSIController):
                controller = dev
                if len(controller.device)+1 < 16:
                    break

        return controller.key

    def _add_virtual_disk(self, vm, disk_size, disk_type):
        controller = []
        # get all disks on a VM, set unit_number to the next available
        unit_number = 0 # If there is no disk in the VM
        for dev in vm.config.hardware.device:
            if isinstance(dev, vim.vm.device.VirtualSCSIController):
                controller = dev
                if len(dev.device) < 7:
                    unit_number = len(dev.device)
                else:
                    unit_number = len(dev.device) + 1
                if unit_number < 16:
                    break
        if controller == []:
            controller = vim.vm.device.VirtualSCSIController()
            controller.key = self._add_controller(vm)
        elif unit_number == 16:
            controller.key = self._add_controller(vm, controller.busNumber)
            unit_number = 0

        # add disk here
        new_disk_kb = int(disk_size) * 1024 * 1024
        disk_spec = vim.vm.device.VirtualDeviceSpec()
        disk_spec.fileOperation = "create"
        disk_spec.operation = vim.vm.device.VirtualDeviceSpec.Operation.add
        disk_spec.device = vim.vm.device.VirtualDisk()
        disk_spec.device.backing = \
            vim.vm.device.VirtualDisk.FlatVer2BackingInfo()
        if disk_type == 'thin':
            disk_spec.device.backing.thinProvisioned = True
        disk_spec.device.backing.diskMode = 'persistent'
        disk_spec.device.unitNumber = unit_number
        disk_spec.device.capacityInKB = new_disk_kb
        disk_spec.device.controllerKey = controller.key
        spec = vim.vm.ConfigSpec()
        spec.deviceChange = [disk_spec]
        task = vm.ReconfigVM_Task(spec=spec)

        self._wait_for_tasks([task])
        print('{}GB disk added to {}'.format(disk_size, vm.config.name))
        return True

    def add_disk_to_vm(self, vmnames, disk_size, disk_type="thin", disk_count=1):

        content = self.si.content
        objView = content.viewManager.CreateContainerView(content.rootFolder,
                                                          [vim.VirtualMachine],
                                                          True)
        vmList = objView.view
        objView.Destroy()
        print('Searching for VM {}'.format(vmnames))
        for vm in vmList:
            if vm.name in vmnames:
                print('Add virtual disk to VM {}'.format(vm.name))
                for disk_number in range(int(disk_count)):
                    self._add_virtual_disk(vm, disk_size, disk_type)
                print('Add {} virtual disk to VM {} successly'.format(disk_count,vm.name))
                print('Virthal Machine {} total have {} virtual disk(s)\n'.format(vm.name,vm.summary.config.numVirtualDisks))
        return True

    def PrintVmInfo(self, vm, depth=1):
        """
        Print information for a particular virtual machine or recurse into a folder
        or vApp with depth protection
        """
        maxdepth = 10

        # if this is a group it will have children. if it does, recurse into them
        # and then return
        if hasattr(vm, 'childEntity'):
            if depth > maxdepth:
                return
            vmList = vm.childEntity
            for c in vmList:
                self.PrintVmInfo(c, depth+1)
            return

        # if this is a vApp, it likely contains child VMs
        # (vApps can nest vApps, but it is hardly a common usecase, so ignore that)
        if isinstance(vm, vim.VirtualApp):
            vmList = vm.vm
            for c in vmList:
                self.PrintVmInfo(c, depth + 1)
            return

        summary = vm.summary
        print("Name       : ", summary.config.name)
        print("Path       : ", summary.config.vmPathName)
        print("Guest      : ", summary.config.guestFullName)
        annotation = summary.config.annotation
        if annotation != None and annotation != "":
            print("Annotation : ", annotation)
        print("State      : ", summary.runtime.powerState)
        if summary.guest != None:
            ip = summary.guest.ipAddress
            if ip != None and ip != "":
                print("IP         : ", ip)
        if summary.runtime.question != None:
            print("Question  : ", summary.runtime.question.text)
        print("")
        return True

    def lsvm(self, vmnames = None):

        content = self.si.RetrieveContent()
        for child in content.rootFolder.childEntity:
            if hasattr(child, 'vmFolder'):
                datacenter = child
                vmFolder = datacenter.vmFolder
                vmList = vmFolder.childEntity
                for vm in vmList:
                    if (vmnames == None) or (vm.name in vmnames):
                        self.PrintVmInfo(vm)
        return True

def main():
    """
    Simple command-line program for powering on virtual machines on a system.
    """

    args = GetArgs()
    action = action_parser(args.action)

    es = EsxiServer(args.host, args.user, args.password)
    if args.vmname == None:
        vmnames = None
    else:
        vmnames = es.parser_vmname(args.vmname)

    if action[0] in ["poweron","poweroff","restart"]:
        es.power_vm(action[0],vmnames)
    elif action[0] == "lsvm":
        es.lsvm(vmnames)
    elif action[0] == "delete":
        if "reset" in action:
            es.delete_disk_from_vm(vmnames, delete_start=0)
        elif "all" in action:
            es.delete_disk_from_vm(vmnames, delete_start=1)
        else:
            es.delete_disk_from_vm(vmnames, delete_start=2)
    elif action[0] == "adddisk":
        if args.size == None or args.num == None or args.type not in ["thin","thick","eaglethick"]:
            print("Adjustment error, please provide provision disk size and type(thin/thick)")
            sys.exit()
        es.add_disk_to_vm(vmnames, disk_size=args.size, disk_type=args.type, disk_count=args.num)


# Start program
if __name__ == "__main__":
    main()
