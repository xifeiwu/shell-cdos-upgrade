#!/bin/bash

COSREPOIP=124.16.141.172

function notice()
{
    echo -e "\033[2;32m-$@\033[0m"
}
function warning()
{
    echo -e "\033[2;33m-$@\033[0m"
}
function error()
{
    echo -e "\033[2;31m-$@\033[0m"
    echo -e "\033[2;31m-Upgrade-prepare Fail. contact us : cos_ibp@iscas.ac.cn\033[0m"
    exit 1
}
parameters=$@
skip_reinstall=false
upgrade=false
while [ "$#" -gt "0" ]
do
    case $1 in
    "-h" | "--help")
        echo "Usage：cos-upgrade [options] <parameters>"
        echo "    --skip-reinstall      skip reinstall cos-upgrade"
        echo "    --upgrade             only upgrade package cos-upgrade"
        echo "Any problem, contact us : cos_ibp@iscas.ac.cn"
        exit 0
        ;;
    "--skip-reinstall")
        skip_reinstall=true
        shift
        ;;
    "--upgrade")
        upgrade=true
        shift
        ;;
    *)
        warning "wrong parameter."
        shift
        exit 1
        ;;
    esac
done

function checknetwork()
{
    ping -c1 -W2 www.baidu.com &> /dev/null
    if [ "$?" == "0" ] ; then
        return 0
    else
        ping -c1 -W2 www.google.com.hk &> /dev/null
        if [ "$?" == "0" ] ; then
            return 0
        else
            return 1
        fi
    fi
}
function updatecosrepo()
{
    echo "deb http://${COSREPOIP}/cos iceblue main universe" > /etc/apt/sources.list.d/cos-repository.list
    wget -q -O - http://${COSREPOIP}/cos/project/keyring.gpg | apt-key add - >/dev/null 2>&1 || return 1
    wget -q -O - http://${COSREPOIP}/cos/project/coskeyring.gpg | apt-key add - >/dev/null 2>&1 || return 1
    origin=`sed -n '2p' /etc/apt/preferences | awk '{print $3}'`
    if [ "${origin}" == "o=cos" ] ; then
    sed -i '1,4d' /etc/apt/preferences
    fi
    codename=`sed -n '2p' /etc/apt/preferences | awk '{print $3}'`
    if [ "${codename}" != "n=iceblue" ] ; then
    sed -i '1i\Package: *\
Pin: release n=iceblue\
Pin-Priority: 750\

    ' /etc/apt/preferences
    fi
    rm -rf /var/lib/apt/lists/*
    apt-get update -o Dir::Etc::sourcelist="sources.list.d/cos-repository.list" -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0" >/dev/null 2>&1 || return 2
    return 0
}

#must be user root
if [ "$USER" != "root" ] ; then
    warning "Please run as the root user."
    exit 1
fi
#prepare: 1.checking network...
notice "prepare: 1. checking network..."
checknetwork
case $? in
    "1")
    error "Checking network: FAIL. Please check your internet connection."
    ;;
    "0")
    notice "Checking network: PASS."
    ;;
esac
#prepare: 2.update cos repositoy
notice "prepare: 2.update cos repositoy"
updatecosrepo
case $? in
    "1")
    error "Update cos repositoy: FAIL. Can't get gpg keyring."
    ;;
    "2")
    error "Update cos repositoy: FAIL. Upgrade fail."
    ;;
    "0")
    notice "Update cos repositoy: PASS."
    ;;
esac
#3. prepare: upgrade package cos-upgrade
notice "prepare: 3.upgrade package cos-upgrade"
if ${skip_reinstall} ; then    
    notice "prepare: 3.upgrade package cos-upgrade: SKIP."
else
    apt-get install -y --force-yes --reinstall cos-upgrade
    if [ $? == "0" ]; then
        notice "Upgrade package cos-upgrade: PASS."
    else
        error "Upgrade package cos-upgrade: FAIL."
    fi
    if ${upgrade} ; then
        exit 0
    fi
fi

notice "********switch to upgrade.sh********"
#4. prepare: cos-upgrade
bash /usr/lib/cos-upgrade/upgrade.sh ${parameters}
