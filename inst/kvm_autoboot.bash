#!/bin/bash

# NOTE: Avoid problems with relative paths. By Questor
SCRIPTDIR_V="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPTDIR_V"

# NOTE: Load main library. By Questor
. $SCRIPTDIR_V/lib/ez_i.bash

# NOTE: Load configuration. By Questor
. $SCRIPTDIR_V/conf/conf.bash

# NOTE: Create a directory for the KVM_AutoBoot (kvm_autoboot.bash) logs if it does
# not exist. By Questor
f_chk_fd_fl "/var/log/kvm_autoboot" "d"
if [ ${CHK_FD_FL_R} -eq 0 ] ; then
    mkdir "/var/log/kvm_autoboot"
fi

f_log_manager "KVM_AutoBoot started." 0 "kvm_ab" "/var/log/kvm_autoboot"

# NOTE: The value in "$LOG_FL_PATH_N_NM" is returned by the f_log_manager function
# and contains the path and name for the current log that was automatically generated
# by the f_log_manager function. By Questor
LOG_FL_PATH_N_NM="$LOG_FILE_NAME"

# NOTE: Maintain the script's log schema. By Questor
f_log_fls_management() {

    # NOTE: Remove output file for stdout and stderr. By Questor
    rm -f "$SCRIPTDIR_V/tmp/f_p_tux_op_to_log"

    # NOTE: Delete all log files but the most recent "LOGS_KEEP_C" files. By Questor
    # [Ref.: https://stackoverflow.com/a/34862475/3223785 ]
    ls -tp /var/log/kvm_autoboot | grep -v '/$' | tail -n +$((LOGS_KEEP_C+1)) | xargs -d '\n' -r rm --

}

if [ -z $BOOT_ORDER ]; then
# NOTE: If there are no VMs defined in the list (BOOT_ORDER), the service stops
# immediately. By Questor

    f_log_manager "There are no VMs defined in the BOOT_ORDER list. The service will stops." "$LOG_FL_PATH_N_NM"
    exit 0
fi

# NOTE: Starts all VMs in the BOOT_ORDER list respecting the boot interval between
# them. By Quetor
ARR_LENGTH=${#BOOT_ORDER[*]}
for (( i=0; i < $ARR_LENGTH; i++ )) ; do
    if [ $((i%2)) -eq 0 ]; then
    # NOTE: "i" is even. By Quetor

        VM_NAME=${BOOT_ORDER[$i]}
        if [ ${i} -eq $(( $ARR_LENGTH -1 )) ] ; then
        # NOTE: Applies to the last VM in the list. By Questor

            virsh start $VM_NAME > $SCRIPTDIR_V/tmp/f_p_tux_op_to_log 2>&1
            F_P_TUX_OP_TO_LOG=$(cat $SCRIPTDIR_V/tmp/f_p_tux_op_to_log)
            f_log_manager "$F_P_TUX_OP_TO_LOG" "$LOG_FL_PATH_N_NM"
        fi
    else
    # NOTE: "i" is odd. By Quetor

        CUSTOM_INTERV=${BOOT_ORDER[$i]}
        if [ ${CUSTOM_INTERV} -lt 0 ] ; then
            CUSTOM_INTERV=$BOOT_DEF_INTERV
        fi
        virsh start $VM_NAME > $SCRIPTDIR_V/tmp/f_p_tux_op_to_log 2>&1
        F_P_TUX_OP_TO_LOG=$(cat $SCRIPTDIR_V/tmp/f_p_tux_op_to_log)
        f_log_manager "$F_P_TUX_OP_TO_LOG" "$LOG_FL_PATH_N_NM"

        # NOTE: Interval to boot the next VM in the BOOT_ORDER list. By Questor
        f_log_manager "Waiting $CUSTOM_INTERV second(s) to start the next VM in the BOOT_ORDER list." "$LOG_FL_PATH_N_NM"
        sleep $CUSTOM_INTERV

    fi
done

f_log_manager "There are no more VMs to start in the BOOT_ORDER list. The service will stops." "$LOG_FL_PATH_N_NM"

f_log_fls_management

exit 0
