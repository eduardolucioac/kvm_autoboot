#!/bin/bash

# NOTE: The reason for the existence of these variables is to "abstract" the functioning
# of "f_about_distro" that obtain information from data from the distro itself and
# therefore subject to variations. By Questor
DISTRO_TYPE=""
DISTRO_NAME=""

# > -----------------------------------------
# CHECK IF DISTRO IS COMPATIBLE

f_chk_distro() {
    f_open_section
    f_about_distro
    f_div_section
    echo "DISTRO INFORMATION:"
    f_div_section
    echo "NAME: .... ${F_ABOUT_DISTRO_R[0]}"
    echo "VERSION: . ${F_ABOUT_DISTRO_R[1]}"
    echo "BASED: ... ${F_ABOUT_DISTRO_R[2]}"
    echo "ARCH: .... ${F_ABOUT_DISTRO_R[3]}"
    f_div_section

    if [[ "${F_ABOUT_DISTRO_R[2]}" == "Debian" ]] || [[ "${F_ABOUT_DISTRO_R[2]}" == "RedHat" ]] || 
        [[ "${F_ABOUT_DISTRO_R[2]}" == "Suse" ]] ; then
        if [[ "${F_ABOUT_DISTRO_R[2]}" == "Debian" ]] ; then
            DISTRO_TYPE="DEB"
            if [[ "${F_ABOUT_DISTRO_R[0]}" == "Ubuntu" ]] ; then
                DISTRO_NAME="Ubuntu"
                if [[ "${F_ABOUT_DISTRO_R[1]}" != "14.04" ]] ; then
                    f_div_section
                    f_yes_no "Linux version may be incompatible with this installer (expected: 14.04/obtained: ${F_ABOUT_DISTRO_R[1]})! Continue?"
                    if [ ${YES_NO_R} -eq 0 ] ; then
                        exit 0
                    fi
                fi
            elif [[ "${F_ABOUT_DISTRO_R[0]}" == "Debian GNU/Linux" ]] ; then
                DISTRO_NAME="Debian"
                if [[ "${F_ABOUT_DISTRO_R[1]}" != "8" ]] ; then
                    f_div_section
                    f_yes_no "Linux version may be incompatible with this installer (expected: 8/obtained: ${F_ABOUT_DISTRO_R[1]})! Continue?"
                    if [ ${YES_NO_R} -eq 0 ] ; then
                        exit 0
                    fi
                fi
            else
                f_div_section
                f_yes_no "Linux distro may be incompatible with this installer (expected: Ubuntu or Debian/obtained: ${F_ABOUT_DISTRO_R[0]})! Continue?"
                if [ ${YES_NO_R} -eq 0 ] ; then
                    exit 0
                fi
            fi
        elif [[ "${F_ABOUT_DISTRO_R[2]}" == "RedHat" ]] ; then
            DISTRO_TYPE="RH"
            if [[ "${F_ABOUT_DISTRO_R[0]}" == "Red Hat Enterprise Linux Server" ]] ; then
                DISTRO_NAME="RedHat"
                if [[ "${F_ABOUT_DISTRO_R[1]}" != "7"* ]] ; then
                    f_div_section
                    f_yes_no "Linux version may be incompatible with this installer (expected: 7.X/obtained: ${F_ABOUT_DISTRO_R[1]})! Continue?"
                    if [ ${YES_NO_R} -eq 0 ] ; then
                        exit 0
                    fi
                fi
            elif [[ "${F_ABOUT_DISTRO_R[0]}" == "CentOS Linux" ]] ; then
                DISTRO_NAME="CentOS"
                if [[ "${F_ABOUT_DISTRO_R[1]}" != "7"* ]] ; then
                    f_div_section
                    f_yes_no "Linux version may be incompatible with this installer (expected: 7.X/obtained: ${F_ABOUT_DISTRO_R[1]})! Continue?"
                    if [ ${YES_NO_R} -eq 0 ] ; then
                        exit 0
                    fi
                fi
            else
                f_div_section
                f_yes_no "Linux distro may be incompatible with this installer (expected: CentOS or Red Hat Enterprise Linux Server/obtained: ${F_ABOUT_DISTRO_R[0]})! Continue?"
                if [ ${YES_NO_R} -eq 0 ] ; then
                    exit 0
                fi
            fi
        elif [[ "${F_ABOUT_DISTRO_R[2]}" == "Suse" ]] ; then
            DISTRO_TYPE="SUSE"
            if [[ "${F_ABOUT_DISTRO_R[0]}" == "openSUSE" ]] ; then
                DISTRO_NAME="openSUSE"
                if [[ "${F_ABOUT_DISTRO_R[1]}" != "13."* ]] ; then
                    f_div_section
                    f_yes_no "Linux version may be incompatible with this installer (expected: 13.X/obtained: ${F_ABOUT_DISTRO_R[1]})! Continue?"
                    if [ ${YES_NO_R} -eq 0 ] ; then
                        exit 0
                    fi
                fi
            elif [[ "${F_ABOUT_DISTRO_R[0]}" == "SLES" ]] ; then
                DISTRO_NAME="SLES"
                if [[ "${F_ABOUT_DISTRO_R[1]}" != "12."* ]] ; then
                    f_div_section
                    f_yes_no "Linux version may be incompatible with this installer (expected: 12.X/obtained: ${F_ABOUT_DISTRO_R[1]})! Continue?"
                    if [ ${YES_NO_R} -eq 0 ] ; then
                        exit 0
                    fi
                fi
            else
                f_div_section
                f_yes_no "Linux distro may be incompatible with this installer (expected: openSUSE or SUSE Linux Enterprise Server/obtained: ${F_ABOUT_DISTRO_R[0]})! Continue?"
                if [ ${YES_NO_R} -eq 0 ] ; then
                    exit 0
                fi
            fi
        fi

        if [[ "${F_ABOUT_DISTRO_R[3]}" != "x86_64" ]] ; then
            f_enter_to_cont "Linux architecture completely incompatible with this installer (expected: x86_64/obtained: ${F_ABOUT_DISTRO_R[3]})."
            exit 0
        fi
    else
        f_enter_to_cont "Linux distro completely incompatible with this installer (expected: Debian (or based) or RedHat (or based) or SUSE (or based)/obtained: ${F_ABOUT_DISTRO_R[2]})."
        exit 0
    fi
    f_close_section
}

# < -----------------------------------------
