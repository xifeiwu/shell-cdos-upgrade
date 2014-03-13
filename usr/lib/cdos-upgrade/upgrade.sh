#!/bin/bash
source /usr/lib/cdos-upgrade/upgrade-modules.sh

#parse parameter
while [ "$#" -gt "0" ]
do
    case $1 in
    "-h" | "--help")
        echo "Usage：cdos-upgrade [options] <parameters>"
        echo "    [-U|--upgrade]             upgrade package only"
        echo "    --list-steps             list all steps used by cdos-upgrade."
        echo "    --set-step             set a specific step of cdos-upgrade."
        echo "Any problem, contact us : cdos_support@iscas.ac.cn"
        exit 0
        ;;
    "-U" | "--upgrade")
        cdosupgrade_upgrade
        if [ $? -eq 0 ];then
            notice "Install(Upgrade) cdos-update success."
        else
            error "Install(Upgrade) cdos-update fail. error code: $?"
        fi
        exit 0
        ;;
    "--check")
        checkall
        exit 0
        ;;
    "--list-steps")
        notice "All steps of cdos-upgrade:"
        for((i=0;i<${allsteps};i++))
        do
            echo ${STEPSDESC[$i]}
        done
        exit 0
        ;;
    "--set-steps")
        shift
        step_selected=($@)
        for step in ${step_selected[@]}
        do
            custom_by_step ${step}
        done
        exit 0
        ;;
    *)
        warning "Wrong parameter. -h for help"
        shift
        exit 1
        ;;
    esac
done

#must be user root
if [ "$USER" != "root" ] ; then
    error "Please run as the root user."
fi

for((step=0;step<${allsteps};step++))
do
    upgrade_by_step ${step}
done

notice "Upgrade success, reboot system now"
while true
do
    notice_read "-System will reboot, yes?[y/N] " yn
    if [ -z ${yn} ]; then
        continue
    fi
    if [ "${yn}" == "y" ]; then
        reboot
        break
    elif [ "${yn}" == "n" ]; then
        break 
    fi
done
exit 0
#gedit:?
