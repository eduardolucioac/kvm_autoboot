#!/bin/bash

# NOTE: Avoid problems with relative paths. By Questor
SCRIPTDIR_V="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPTDIR_V"

# NOTE: Load main library. By Questor
. $SCRIPTDIR_V/lib/ez_i.bash

# NOTE: Load configuration. By Questor
. $SCRIPTDIR_V/conf/conf.bash

# NOTE: Other useful scripts. By Questor
. $SCRIPTDIR_V/resrc/other.bash

# > --------------------------------------------------------------------------
# BEGIN
# --------------------------------------

read -d '' TITLE_F <<"EOF"
KVM_AutoBoot Installer
EOF

# NOTE: For versioning use "MAJOR.MINOR.REVISION.BUILDNUMBER". By Questor
# [Ref.: http://programmers.stackexchange.com/questions/24987/what-exactly-is-the-build-number-in-major-minor-buildnumber-revision ]

read -d '' VERSION_F <<"EOF"
0.0.1.0
EOF

read -d '' ABOUT_F <<"EOF"
This script will install KVM_AutoBoot!
EOF

read -d '' WARNINGS_F <<"EOF"
- This installer is compatible with Centos 7.

- We RECOMMEND you...
    Install all the components (answer yes to everything) and use the default 
        values. Except contrary guidance!
    Check for previous installations! If there is previous 
        installations consider this variant in the process!

- We NOTICE you...
    This installer assumes that the target distribution has a "standard 
    setup".

- We WARNING you...
    THIS INSTALLER AND RESULTING PRODUCTS COMES WITH ABSOLUTELY NO WARRANTY! 
    USE AT YOUR OWN RISK! WE ARE NOT RESPONSIBLE FOR ANY DAMAGE TO YOURSELF, 
    HARDWARE, OR CO-WORKERS.
EOF

read -d '' COMPANY_F <<"EOF"
Eduardo Lúcio Amorim Costa
https://github.com/eduardolucioac/kvm_autoboot - Brasil-DF
Free software! Embrace that idea!
EOF

TUX=$(cat $SCRIPTDIR_V/tux.txt)
f_begin "$TITLE_F" "$VERSION_F" "$ABOUT_F$TUX" "$WARNINGS_F" "$COMPANY_F"
ABOUT_F=""
WARNINGS_F=""
if [ ${F_BEGIN_R} -eq 0 ] ; then
    f_enter_to_cont
fi

# < --------------------------------------------------------------------------

# NOTE: Check if the user is root. By Questor
f_is_root 1
if [ ${F_IS_ROOT_R} -eq 0 ] ; then
    f_log_manager "ERROR: You need to be root!" 0 "" 0
    f_error_exit "You need to be root!"
fi

# > --------------------------------------------------------------------------
# TERMS AND LICENSE
# --------------------------------------

TERMS_LICEN_F=$(cat $SCRIPTDIR_V/LICENSE.txt)
f_terms_licen "$TERMS_LICEN_F"
TERMS_LICEN_F=""

# NOTE: Remove old logs. By Questor
rm -f "$SCRIPTDIR_V/installation.log"

f_log_manager "You have accepted the KVM_AutoBoot's license." "$SCRIPTDIR_V/installation.log" 0 "" 1

# < --------------------------------------------------------------------------

# NOTE: Check distro name, version, etc... By Questor
f_chk_distro

# > --------------------------------------------------------------------------
# INSTRUCTIONS
# --------------------------------------

read -d '' INSTRUCT_F <<"EOF"

The KVM_AutoBoot is a service that starts your KVM's VMs (Virtual Machines) at the boot of your server.

The KVM_AutoBoot's service is started during server boot after the libvirt's service ("libvirtd.service") starts.

After starting all the VMs defined in the BOOT_ORDER list - configuration file "/usr/local/kvm_autoboot/conf/conf.bash" - respecting the start interval defined for each one, the KVM_AutoBoot's service ends. If there are no VMs defined in the BOOT_ORDER list, the KVM_AutoBoot's service stops immediately.

To cancel installation at any time use Ctrl+c.

EOF

f_instruct "$INSTRUCT_F"
INSTRUCT_F=""
if [ ${F_INSTRUCT_R} -eq 0 ] ; then
    f_enter_to_cont
fi

# < --------------------------------------------------------------------------

# > --------------------------------------------------------------------------
# INSTALL COMPONENTS
# > -----------------------------------------

# NOTE: Update your system and install some dependencies. By Questor
f_up_or_inst_kvm_a() {
    f_chk_by_path_hlp "/usr/local/kvm_autoboot" "d"
    if [ ${F_CHK_BY_PATH_HLP_R} -eq 1 ] ; then
        f_div_section
        f_yes_no "KVM_AutoBoot already installed in \"/usr/local/kvm_autoboot\". Reinstall it?
 * IMPORTANT: All KVM_AutoBoot's settings (conf.bash) will be lost."
        f_div_section
        if [ ${YES_NO_R} -eq 0 ] ; then
            f_div_section
            f_log_manager "KVM_AutoBoot's installation and configuration has been canceled." "$SCRIPTDIR_V/installation.log" 0 "" 1
            f_div_section
            exit 0
        else
            rm -rf "/usr/local/kvm_autoboot"
            case "$DISTRO_TYPE" in
                RH)

                    # NOTE: Disable KVM_AutoBoot's service and remove the ".service"
                    # file. By Questor
                    # systemctl daemon-reload # <- TODO: Necessário!?
                    f_div_section
                    f_log_manager "Remove and disable OLD KVM_AutoBoot's service (kvm_autoboot.service)." "$SCRIPTDIR_V/installation.log" 0 "" 1
                    f_div_section
                    systemctl disable kvm_autoboot.service
                    rm -rf "/usr/lib/systemd/system/kvm_autoboot.service"

                ;;
                *)
                    f_div_section
                    f_log_manager "ERROR: Not implemented to your OS." "$SCRIPTDIR_V/installation.log" 0 "" 0
                    f_div_section
                    f_error_exit "Not implemented to your OS."
                ;;
            esac
        fi
    fi
    f_div_section
    f_log_manager "KVM_AutoBoot's installation and configuration has been started." "$SCRIPTDIR_V/installation.log" 0 "" 1
    f_div_section

    # NOTE: Folder where KVM_AutoBoot will be installed. By Questor
    mkdir "/usr/local/kvm_autoboot"

    cp -v "$SCRIPTDIR_V/LICENSE.txt" "/usr/local/kvm_autoboot/"
    cp -v "$SCRIPTDIR_V/README.md" "/usr/local/kvm_autoboot/"
    cp -v "$SCRIPTDIR_V/inst/kvm_autoboot.bash" "/usr/local/kvm_autoboot/"

    f_div_section
    f_log_manager "The \"/usr/local/kvm_autoboot/kvm_autoboot.bash\" bash script will be defined as executable." "$SCRIPTDIR_V/installation.log" 0 "" 1
    f_div_section
    chmod u+x "/usr/local/kvm_autoboot/kvm_autoboot.bash"

    mkdir "/usr/local/kvm_autoboot/conf"
    cp -v "$SCRIPTDIR_V/conf/conf.bash" "/usr/local/kvm_autoboot/conf/"
    mkdir "/usr/local/kvm_autoboot/lib"
    cp -v "$SCRIPTDIR_V/lib/ez_i.bash" "/usr/local/kvm_autoboot/lib/"
    # mkdir "/usr/local/kvm_autoboot/resrc"
    # cp -v "$SCRIPTDIR_V/resrc/other.bash" "/usr/local/kvm_autoboot/resrc/"

    # NOTE: Folder for temporary KVM_AutoBoot files. By Questor
    mkdir "/usr/local/kvm_autoboot/tmp"

    case "$DISTRO_TYPE" in
        RH)

            # NOTE: Add and enable KVM_AutoBoot's service. By Questor
            f_div_section
            f_log_manager "Add and enable KVM_AutoBoot's service (kvm_autoboot.service)." "$SCRIPTDIR_V/installation.log" 0 "" 1
            f_div_section
            cp -v "$SCRIPTDIR_V/inst/kvm_autoboot.service" "/usr/lib/systemd/system/"
            systemctl enable kvm_autoboot.service

        ;;
        *)
            f_div_section
            f_log_manager "ERROR: Not implemented to your OS." "$SCRIPTDIR_V/installation.log" 0 "" 0
            f_div_section
            f_error_exit "Not implemented to your OS."
        ;;
    esac

    # NOTE: To improve aesthetics in the terminal output. By Questor
    # echo ""

    f_div_section
    f_log_manager "KVM_AutoBoot's components are installed in the \"/usr/local/kvm_autoboot\" folder." "$SCRIPTDIR_V/installation.log" 0 "" 1
    f_div_section
}

f_div_section
f_yes_no "Install KVM_AutoBoot?"
f_div_section
if [ ${YES_NO_R} -eq 1 ] ; then
    f_up_or_inst_kvm_a
else
    f_div_section
    f_log_manager "KVM_AutoBoot's installation canceled." "$SCRIPTDIR_V/installation.log" 0 "" 1
    f_div_section
    exit 0
fi

# < --------------------------------------------------------------------------

# > --------------------------------------------------------------------------
# FINAL
# --------------------------------------

read -d '' TITLE_F <<"EOF"
Installer finished! Thanks!
EOF

USEFUL_INFO_F="To configure KVM_AutoBoot...
    vi /usr/local/kvm_autoboot/conf/conf.bash

Installation Log...
    vi $SCRIPTDIR_V/installation.log

KVM_AutoBoot's executable bash script...
    /usr/local/kvm_autoboot/kvm_autoboot.bash

KVM_AutoBoot's service logs...
    /var/log/kvm_autoboot/*

To start KVM_AutoBoot's service...
    systemctl start kvm_autoboot.service"

f_end "$TITLE_F" "$USEFUL_INFO_F"
echo ""
TITLE_F=""
USEFUL_INFO_F=""

# < --------------------------------------------------------------------------

exit 0
