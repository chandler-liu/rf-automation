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
from tools import tasks

import atexit
import getpass
import sys
import ssl


class EsxiServer:
    ROBOT_LIBRARY_SCOPE = 'GLOBAL'
    def __init__(self, host, user, password, port=443):
        if password:
            self.password = password
        else:
            self.password = getpass.getpass(prompt='Enter password for host %s and user %s: ' % (host, user))

        #try:
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

        #except vmodl.MethodFault as e:
        #    print("Caught vmodl fault : " + e.msg)

        #except Exception as e:
        #    print("Caught Exception : " + str(e))  # Start program

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

    def power_vm(self, op, *vmnames):
        if not len(vmnames):
            print("No virtual machine specified for power {}".format(op))
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
            if op == "on":
                tasks = [vm.PowerOn() for vm in vmList if vm.name in vmnames]
            elif op == "off":
                tasks = [vm.PowerOff() for vm in vmList if vm.name in vmnames]
            elif op == "reset":
                tasks = [vm.Reset() for vm in vmList if vm.name in vmnames]
            else:
                raise RuntimeError('The power operation \({}\) is invalid.'.format(op))
            # Wait for power on to complete
            self._wait_for_tasks(tasks)

            print("Virtual Machine(s) have been powered {} successfully".format(op))

        except vmodl.MethodFault as e:
            print("Caught vmodl fault : " + e.msg)

        # except Exception as e:
            # print("Caught Exception : " + str(e))  # Start program

    def _delete_virtual_disk(self, vm_obj, disk_number):
        """ Deletes virtual Disk based on disk number
        :param si: Service Instance
        :param vm_obj: Virtual Machine Object
        :param disk_number: Hard Disk Unit Number
        :return: True if success
        """
        hdd_prefix_label = 'Hard disk '
        hdd_label = hdd_prefix_label + str(disk_number)
        virtual_hdd_device = None
        for dev in vm_obj.config.hardware.device:
            if isinstance(dev, vim.vm.device.VirtualDisk) \
                    and dev.deviceInfo.label == hdd_label:
                virtual_hdd_device = dev
        if not virtual_hdd_device:
            print ('There is no hard disk to be removed!')
            return False
        virtual_hdd_spec = vim.vm.device.VirtualDeviceSpec()
        virtual_hdd_spec.operation = \
            vim.vm.device.VirtualDeviceSpec.Operation.remove
        virtual_hdd_spec.device = virtual_hdd_device
        spec = vim.vm.ConfigSpec()
        spec.deviceChange = [virtual_hdd_spec]
        task = vm_obj.ReconfigVM_Task(spec=spec)
        tasks.wait_for_tasks(self.si, [task])
        return True

    def delete_disk_from_vm(self, vm_name, disk_count):
        content = self.si.content
        objView = content.viewManager.CreateContainerView(content.rootFolder,
                                                          [vim.VirtualMachine],
                                                          True)
        vmList = objView.view
        objView.Destroy()
        print('Searching for VM {}'.format(vm_name))
        vm_obj = None
        for vm in vmList:
            if vm.name == vm_name:
                vm_obj = vm
                break
        if vm_obj:
            for disk_number in range(int(disk_count)):
                self._delete_virtual_disk(vm_obj, 1) # After delete, disk is renumbered, so is always 1
                print ('VM HDD "{}" successfully deleted.'.format(disk_number+1))
        else:
            print ('VM not found')

    def _add_disk(self, vm, disk_size, disk_type):
        spec = vim.vm.ConfigSpec()
        # get all disks on a VM, set unit_number to the next available
        unit_number = 1 # If there is no disk in the VM
        for dev in vm.config.hardware.device:
            if hasattr(dev.backing, 'fileName'):
                unit_number = int(dev.unitNumber) + 1
                # unit_number 7 reserved for scsi controller
                if unit_number == 7:
                    unit_number += 1
                # if unit_number >= 16:
                    # print ("we don't support so many disks:{}".format(unit_number))
                    return
            if isinstance(dev, vim.vm.device.VirtualSCSIController):
                controller = dev
        # add disk here
        dev_changes = []
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
        dev_changes.append(disk_spec)
        spec.deviceChange = dev_changes
        task = vm.ReconfigVM_Task(spec=spec)
        tasks.wait_for_tasks(self.si, [task])
        print('{}GB disk added to {}'.format(disk_size, vm.config.name))

    def add_disk_to_vm(self, vm_name, disk_size, disk_type, disk_count):
        content = self.si.content
        objView = content.viewManager.CreateContainerView(content.rootFolder,
                                                          [vim.VirtualMachine],
                                                          True)
        vmList = objView.view
        objView.Destroy()
        print('Searching for VM {}'.format(vm_name))
        vm_obj = None
        for vm in vmList:
            if vm.name == vm_name:
                vm_obj = vm
                break
        if vm_obj:
            for i in range(int(disk_count)):
                self._add_disk(vm_obj, disk_size, disk_type)
        else:
            print ('VM not found')

if __name__ == "__main__":
    es = EsxiServer("10.16.17.210", "root", "trend#11")
    es.power_vm("off", "auto-1","auto-2")
#    es.delete_disk_from_vm("target", 3)
    #es.add_disk_to_vm("target", disk_size=10, disk_type="thin", disk_count=2)
