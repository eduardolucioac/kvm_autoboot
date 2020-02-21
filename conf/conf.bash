#!/bin/bash

# > -----------------------------------------
# * KVM_AUTOBOOT SERVICE CONFIGURATION

# NOTE: List with the VMs's names in the desired boot start order and the interval
# to boot next (in seconds). The first VM in the list boots with the service and
# the others after the defined interval immediately before its name. If the interval
# is set to "-1", then the default interval BOOT_DEF_INTERV will be used. By Questor
BOOT_ORDER=("VM_NAME0" CUSTOM_INTERV1 "VM_NAME1" CUSTOM_INTERV2 "VM_NAME2")

# NOTE: Default interval between the start of a VM and another one in seconds.
# By Questor
BOOT_DEF_INTERV=30

# NOTE: Keep the last X logs. By Questor
LOGS_KEEP_C=45

# < -----------------------------------------
