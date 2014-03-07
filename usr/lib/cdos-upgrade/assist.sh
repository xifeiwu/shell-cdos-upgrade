#!/bin/bash
CDOSREPOIP=124.16.141.172

LOGFILE="/var/log/cdos-upgrade.log"
if [ -f ${LOGFILE} ]; then
    echo "Log of cdos-upgrade:" > ${LOGFILE}
else
    touch ${LOGFILE}
fi

function notice()
{
    echo -e "\033[2;32m-$@\033[0m" | tee -a ${LOGFILE}
}
function warning()
{
    echo -e "\033[2;33m-$@\033[0m" | tee -a ${LOGFILE}
}
function error()
{
    echo -e "\033[2;31m-$@\033[0m" | tee -a ${LOGFILE}
    echo -e "\033[2;31m-Upgrade Fail. contact us : cdos_support@iscas.ac.cn\033[0m" | tee -a ${LOGFILE}
    exit 1
}
function echo_read()
{
    echo -ne "-${1}" | tee -a ${LOGFILE}
    read ${2}
}
function notice_read()
{
    echo -ne "\033[2;32m-${1}\033[0m" | tee -a ${LOGFILE}
    read ${2}
}
function warning_read()
{
    echo -ne "\033[2;33m-${1}\033[0m" | tee -a ${LOGFILE}
    read ${2}
}

function apt_get_install()
{
    local pkgname
    if [ "$#" -eq 0 ]; then
        warning "apt-get install error, no package specified."
        return 1
    fi
    for pkgname in $@ ; do
        dpkg -s ${pkgname} > /dev/null 2>&1
        if [ "$?" -eq 0 ]; then
            notice "${pkgname} has install."
        else
            echo "installing package ${pkgname}..."
            apt-get -t iceblue install -y --force-yes ${pkgname} > /dev/null 2>&1
            if [ "$?" -ne 0 ]; then
                return 2
            fi
        fi
    done
}

#log to ${LOGFILE} only, usually followed by commnad.
function log()
{
    $@ >> ${LOGFILE} 2>&1
}
#echo to terminal and log to ${LOGFILE}, usually followed by string.
function echo_log()
{
    echo -$@ | tee -a ${LOGFILE}
}
function upload
{
    IP=`LC_ALL=C ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}'`
    HOST=`hostname -s`
    DATE=`date +%Y%m%d%H%M`
    cd /var/log
    echo "${IP}(${HOST})-${DATE}" >> cdos-upgrade.log
    mv cdos-upgrade.log ${HOST}-${DATE}
    ftp -n ${CDOSREPOIP} <<EOF
user upgradelog upgradelog
prompt
passive
mput ${HOST}-${DATE}
quit
EOF
    mv ${HOST}-${DATE} cdos-upgrade.log
}
