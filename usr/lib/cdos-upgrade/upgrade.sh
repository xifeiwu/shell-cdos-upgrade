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
        ;;
    "--check")
        checkall
        if [ $? -eq 0 ];then
            notice "Check all necessary customization."
        else
            error "Install(Upgrade) cdos-update fail. error code: $?"
        fi
        exit 0
        ;;
    "--list-steps")
        notice "All steps of cdos-upgrade:"
        for((i=0;i<${allsteps};i++))
        do
            echo ${ALLSTEPS[$i]}
        done
        exit 0
        ;;
    "--set-step")
        for((i=0;i<${allsteps};i++))
        do
            echo ${ALLSTEPS[$i]}
        done
        notice_read "Choose the step[1-${allsteps}]:" ch
        ch=`echo ${ch} | sed "s/[^1-9]//g"`
        if [ ${ch} -ge 1 -a ${ch} -le ${allsteps} ]; then
            echo_read "Your choice is: ${ALLSTEPS[$((ch-1))]} [Y/n]: " yn
            while [ "${yn}" != "y" -a "${yn}" != "Y" -a "${yn}" != "n" -a "${yn}" != "N" ]
            do
                echo_read "Your choice is: ${ALLSTEPS[$((ch-1))]} [Y/n]: " yn
            done
            if [ "${yn}" == "Y" -o "${yn}" == "y" ]; then
                upgrade_by_step $((ch-1))
            else
                error "no choose is selected."
            fi
        else
            error "Your choose is not recognized. Select a number from 1 to ${allsteps}"
        fi
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
