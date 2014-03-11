#!/bin/bash
FILEPATH="/usr/lib/cdos-upgrade"
if [ -f "${FILEPATH}/assist.sh" ]; then
    source ${FILEPATH}/assist.sh
else
    echo "File ${FILEPATH}/assist.sh was not found."
    exit 1
fi

allsteps=9
steps=1
declare -a ALLSTEPS
ALLSTEPS[0]="($((steps++))/${allsteps}). Checking Network Connection."
ALLSTEPS[1]="($((steps++))/${allsteps}). Checking current version of CDOS."
ALLSTEPS[2]="($((steps++))/${allsteps}). Update repositoies(cdos) for Package installation."
ALLSTEPS[3]="($((steps++))/${allsteps}). Update repositoies(official) for Package installation."
ALLSTEPS[4]="($((steps++))/${allsteps}). Replace Packages in Component Main."
ALLSTEPS[5]="($((steps++))/${allsteps}). Upgrade Packages in Component Main."
ALLSTEPS[6]="($((steps++))/${allsteps}). Purge Packages in Component Universe."
ALLSTEPS[7]="($((steps++))/${allsteps}). Install Packages in Component Universe."
ALLSTEPS[8]="($((steps++))/${allsteps}). Other fix."
declare -a ALLFUNCS
ALLFUNCS=(
checknetwork
checkversion
updatecdosrepo
updateofficialrepo
replace_main_deb
upgrade_main_deb
purge_universe_pkg
install_universe_pkg
otherfix
)

#1
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
#2
function checkversion()
{
    VERLIST=(`wget -q -O - http://${CDOSREPOIP}/cos/project/verlist`)
    CURVER=`lsb_release -r 2>/dev/null | awk '{print $2}'`
    DSTVER=${VERLIST[$((${#VERLIST[*]}-1))]}
    read -p "-Current version of COS Desktop is ${CURVER}, right? [y/n] " yn
    while [ "${yn}" != "y" -a  "${yn}" != "Y" -a "${yn}" != "n" -a "${yn}" != "N" ]
    do
        read -p "Current version of COS Desktop is ${CURVER}, right?[y/n] " yn
    done
    if [ "${yn}" == "N" -o "${yn}" == "n" ] ; then
        while true
        do
            echo "Please enter version of current COS Desktop"
            notice_read "( ${VERLIST[*]} ) : " CURVER
            if [ -z ${CURVER} ] ; then
                continue
            fi
            for ver in ${VERLIST[@]}
            do
                if [ "${ver}" == "${CURVER}" ] ; then
                    break 2
                fi
            done
            echo "version ${CURVER} does not exist."
        done
    fi
    if [ "${CURVER}" == "${DSTVER}" ] ; then
        return 1
    else
        return 0
    fi
}
#3
function updatecdosrepo()
{
    echo "deb http://${CDOSREPOIP}/cos iceblue main universe" > /etc/apt/sources.list.d/cos-repository.list
    wget -q -O - http://${CDOSREPOIP}/cos/project/keyring.gpg | apt-key add - >/dev/null 2>&1 || return 1
    wget -q -O - http://${CDOSREPOIP}/cos/project/coskeyring.gpg | apt-key add - >/dev/null 2>&1 || return 1
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
#4
function updateofficialrepo()
{
    local MINTREPOIP OFFICIALREPODIR
    MINTREPOIP="124.16.141.149"
    OFFICIALREPODIR="/etc/apt/sources.list.d/official-package-repositories.list"
    cat > ${OFFICIALREPODIR} << EOF
deb http://${MINTREPOIP}/repos/cos cos main
deb http://${MINTREPOIP}/repos/mint olivia main upstream import
deb http://${MINTREPOIP}/repos/ubuntu raring main restricted universe multiverse
deb http://${MINTREPOIP}/repos/ubuntu raring-security main restricted universe multiverse
deb http://${MINTREPOIP}/repos/ubuntu raring-updates main restricted universe multiverse
deb http://${MINTREPOIP}/repos/ubuntu raring-proposed main restricted universe multiverse
deb http://${MINTREPOIP}/repos/ubuntu raring-backports main restricted universe multiverse
deb http://${MINTREPOIP}/repos/security-ubuntu/ubuntu raring-security main restricted universe multiverse
deb http://${MINTREPOIP}/repos/canonical/ubuntu raring partner
EOF
    wget -q -O - http://${MINTREPOIP}/repos/cos.gpg.key | apt-key add - || return 1
    apt-get update -o Dir::Etc::sourcelist="sources.list.d/official-package-repositories.list" -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0" || return 2
    return 0
}
#5
function replace_main_deb()
{
    local pkg deblist mintdeb cosdeb installdeb debcnt
    DEBLIST=`wget -q -O - http://${CDOSREPOIP}/cos/project/pkgs2replace` || return 1
    deblist=`echo "${DEBLIST}"| awk '{print $2}'`
    mintdeb=(${deblist})
    deblist=`echo "${DEBLIST}" | awk '{print $3}'`
    cosdeb=(${deblist})
    debcnt=${#mintdeb[@]}
    installdeb=`echo ${cosdeb[*]} | sed "s/null//g"`
    apt-get install -y --force-yes libreoffice-style-galaxy >/dev/null 2>&1 || return 2
    
    for ((i=0; i<${debcnt}; i++))
    do
        pkg=${mintdeb[$i]}
        if [ ${pkg} == "null" ] ; then
            continue
        fi
        dpkg -s ${pkg} >/dev/null 2>&1
        if [ "$?" -eq 0 ]; then
            notice "Removing package ${pkg}..."
            dpkg --purge ${pkg} || dpkg --force-all --purge ${pkg} >/dev/null 2>&1 || return 3
            if [ $? != "0" ] ; then
                warning "remove package ${pkg} fail"
                return 1
            fi
        fi
        pkg=${cosdeb[$i]}
        if [ ${pkg} == "null" ] ; then
            continue
        fi
        dpkg -s ${pkg} >/dev/null 2>&1 
        if [ "$?" -eq 0 ]; then
            notice "Removing package ${pkg}..."
            dpkg --purge ${pkg} || dpkg --force-all --purge ${pkg} >/dev/null 2>&1 || return 4
            if [ $? != "0" ] ; then
                warning "remove package ${pkg} fail"
                return 1
            fi
        fi
    done

#    apt-get -t iceblue install -y --force-yes --reinstall ${installdeb} || return 2

    for ((i=${debcnt}-1; i>=0; i--))
    do
        pkg=${cosdeb[$i]}
        if [ "${pkg}" == "null" ]; then
            continue
        fi
        echo "Installing package ${pkg}..."
        apt-get -t iceblue install -y --force-yes --reinstall ${pkg} >/dev/null 2>&1 
        if [ $? -ne 0 ] ; then
            warning "install package ${pkg} fail"
            return 2
        fi
    done
    return 0
}
#6
function upgrade_main_deb()
{
    local pkgs2upgrade pkg
    pkgs2upgrade=(`wget -q -O - http://${CDOSREPOIP}/cos/project/pkgs2upgrade-0.9`) || return 1
    for pkg in ${pkgs2upgrade[@]} ; do
        echo "Upgrade main package ${pkg}..."
        apt-get -t iceblue install -y --force-yes ${pkg} >/dev/null 2>&1 
        if [ "$?" -ne 0 ]; then
            return 2
        fi
    done
    return 0
}
#7
function purge_universe_pkg()
{
    local pkgs2purge pkg
    pkgs2purge=(`wget -q -O - http://${CDOSREPOIP}/cos/project/pkgs2purge-0.9`) || return 1
        
    echo "Purging universe package ${pkgs2purge[@]}..."
    dpkg --purge ${pkgs2purge[@]}  >/dev/null 2>&1 || return 2
    return 0
}
#8
function install_universe_pkg()
{
    local pkgs2install pkg goldendir
    pkgs2install=(`wget -q -O - http://${CDOSREPOIP}/cos/project/pkgs2install-0.9`) || return 2

    for pkg in ${pkgs2install[@]} ; do
        dpkg -s ${pkg} > /dev/null 2>&1
        if [ "$?" -eq 0 ]; then
            notice "${pkg} has installed."
        else
            notice "Installing universe package ${pkg}..."
            case ${pkg} in
            "kingsoft-office")
                apt-get -t iceblue install -y --force-yes ${pkg}
                if [ "$?" -eq 0 ]; then
                    notice "Finished"
                else
                    return 4
                fi
            ;;
            *)
                apt-get -t iceblue install -y --force-yes ${pkg} >/dev/null 2>&1 
                if [ "$?" -eq 0 ]; then
                    notice "Finished"
                else
                    return 4
                fi
            ;;
            esac
        fi
    done

    goldendir="/usr/share/apps/goldendict/"
    if [ ! -d ${goldendir} ]; then
        mkdir -p ${goldendir}
    fi
    wget -q -O - http://${CDOSREPOIP}/cos/upgrade/goldendict/dicts.tar.gz | tar -zxvf - -C /usr/share/apps/goldendict/ || return 5
    wget -q -O - http://${CDOSREPOIP}/cos/upgrade/goldendict/dictscache.tar.gz | tar -zxvf - -C /etc/skel/ || return 5
}
#9
function otherfix()
{
#    echo "Prohibit root ssh login"
#    sed -i 's/PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
    echo "Chinesization system settings"
    msgfmt $FILEPATH/zh_CN_po/cinnamon-control-center-1.0.po -o /usr/share/locale/zh_CN/LC_MESSAGES/cinnamon-control-center-1.0.mo
    msgfmt $FILEPATH/zh_CN_po/language-selector.po -o /usr/share/locale/zh_CN/LC_MESSAGES/language-selector.mo
    echo "Chinesization Menu"
    files2remove=(aptoncd
    cinnamon-universal-access-panel
    fcitx-config-gtk3
    fcitx-configtool
    file-roller
    gdebi
    gnome-font-viewer
    gnome-power-statistics
    gnome-user-share-properties
    gucharmap
    im-config
    itweb-settings
    mintNanny
    mintstick
    mintstick-kde
    mintWelcome
    ndisgtk
    openjdk-7-policytool
    seahorse
    simple-scan
    synaptic-kde
    upload-manager
    xchat
    mintWelcome.desktop
    )
    desktop_path="/usr/share/applications/"
    wget -q -O - http://${CDOSREPOIP}/cos/upgrade/desktop.tar.gz | tar -zxvf - -C ${desktop_path} >/dev/null 2>&1 || return 1
    cd ${desktop_path}
    for file in ${files2remove[@]}; do
    if [ -f ${file}.desktop ]; then
        rm ${file}.desktop
    fi
    done

#    echo "Customize default sh"
#    rm /bin/sh
#    ln -s /bin/bash /bin/sh

    echo "Upgrade Linux Kernel."
    apt-get -t iceblue install -y --force-yes linux-headers-3.8.13.13-cos-i686 >/dev/null 2>&1 || return 2
    apt-get -t iceblue install -y --force-yes linux-image-3.8.13.13-cos-i686 >/dev/null 2>&1 || return 2
    update-grub || return 1

    return 0
}

function cosupgrade_upgrade()
{
    notice "Checking Network Connection..."
    checknetwork || return 1
    notice "Updating repositoies for COS..."
    updatecosrepo || return 2
    apt-get install -y --force-yes --reinstall cos-upgrade >/dev/null 2>&1 || return 3
    return 0
}

function upgrade_by_step()
{
    local step
    step=${1}
    notice ${ALLSTEPS[${step}]}
    ${ALLFUNCS[${step}]}
    if [ $? -eq 0 ]; then
        notice "Finished."
    else
        warning_read "Function ${ALLFUNCS[${step}]} return an error code, Go on[N/y]" yn
        while [ "${yn}" != "y" -a "${yn}" != "Y" -a "${yn}" != "n" -a "${yn}" != "N" ]
        do
            warning_read "Function ${ALLFUNCS[${step}]} return an error code, Go on[N/y]" yn
        done
        if [ "${yn}" == "N" -o "${yn}" == "n" ]; then
            error "${ALLSTEPS[${step}]} fail. error code: $?"
        fi            
    fi
}
#    DSTVER=`wget -q -O - http://${CDOSREPOIP}/cos/project/curver`
    #rm -f /boot/config-3.8.0-cos-v0.5-i686  /boot/initrd.img-3.8.0-cos-v0.5-i686 /boot/System.map-3.8.0-cos-v0.5-i686 /boot/vmlinuz-3.8.0-cos-v0.5-i686 /boot/initrd.img-3.8.0-19-generic /boot/vmlinuz-3.8.0-19-generic
