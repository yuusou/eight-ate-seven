#!/bin/bash

# Set path so we can run all commands.
PATH=/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin


version="eight-ate-seven 0.1

Written by Andre Oliveira (me[at]andreoliveira[dot]io)."

usage="Usage: $0 [OPTIONS] [new_root]

Upgrade from CentOS 7 to CentOS 8 on a live system.
This simply installs a vanilla CentOS 8 alongside your current install,
then completely replaces your old install, OBLITERATING IT!

If there's any data or configuration files you wish to preserve, use the 
command and script flags.

Internet connectivity is required (unless you have your own CentOS 8 mirror).
At the next reboot, SELinux will relabel, going through reboot twice.
All custom commands will be executed under bash, first the commands then the 
scripts.

Positional:

    new_root     A mysql.conf file with login credentials.


Optional:

    -T      Size of in-memory temp filesystem in Gigabytes. default: 2.
    -R      Use a folder for Centos 8 instead of in-memory mount. -T ignored.
    -m      Use a different mirror for downloads.
            default: http://mirror.centos.org/centos/8/BaseOS/x86_64/os/
    -p      Run a single command before the switch.
    -P      Run a single command after the switch.
    -s      Run a script before the switch. It'll be preserved.
    -S      Run a script after the switch. It'll obviously be preserved.

Report bugs via github."

# Make sure we have the gnu getopt.
! getopt --test > /dev/null 
if [[ ${PIPESTATUS[0]} -ne 4 ]]; then
    echo "`getopt --test` failed in this environment."
    exit 2
fi

# Parse command options.
OPTS=T:R:m:p:P:s:S:
LONGOPTS=tempsize:rbind:mirror:precommand:postcommand:prescript:postscript:

! PARSED=$(getopt --options=$OPTS --longoptions=$LONGOPTS --name "$0" -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    #  getopt has complained about wrong arguments to stdout.
    exit 2
fi
# Read getopt output this way to handle quoting.
eval set -- "$PARSED"

T=2
R=false
m="http://mirror.centos.org/centos/8/BaseOS/x86_64/os/Packages/"
p=()
P=()
s=()
S=()

while true; do
    case "$1" in
        -T|--tempsize)
            T=$1
            shift
            ;;
        -R|--rbind)
            R=true
            shift
            ;;
        -m|--mirror)
            m="$2"
            shift 2
            ;;
        -p|--precommand)
            p+=("$2")
            shift 2
            ;;
        -P|--postcommand)
            P+=("$2")
            shift
            ;;
        -s|--prescript)
            s+=("$2")
            shift 2
            ;;
        -S|--postscript)
            S+=("$2")
            shift 2
            ;;
        -q|--quiet)
            q="> /dev/null 2>&1"
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Programming error."
            exit 3
            ;;
    esac
done

# Handle positional arguments.
if [ $# -ne 1 ]; then
    echo "$usage"
    exit 1
fi

new_root="${1%/}"

# Install necessary packages (only wget for now).
yum install -y wget

# Directory structure.
mkdir -p "${new_root}"
[[ "${R}" == true ]] && mount -n --rbind "${new_root}" "${new_root}" || mount -n -t tmpfs -o size=${T}G none "${new_root}"
mkdir -p "${new_root}"/{boot,proc,sys,dev,run,etc,slash,"${new_root#?}"}
mount -t proc /proc "${new_root}/proc"
mount --rbind /boot "${new_root}/boot"
mount --rbind /sys "${new_root}/sys"
mount --rbind /dev "${new_root}/dev"
mount --rbind /run "${new_root}/run"
mount --make-rslave "${new_root}"

# We need a bit of sanity in the location of our script.
if [[ -f /usr/local/bin/887.sh && -f /usr/local/bin/887_p1.sh && -f /usr/local/bin/887_p2.sh ]]; then
    cp -a --parents /usr/local/bin/887{,_p1,_p2}.sh "${new_root}/"
else
    echo "Please place the script in /usr/local/bin/"
    umount -Rl "${new_root}"
    rm -Rf "${new_root}"
    exit 1
fi

# Preserve Systemd and Users (backticks, no need subshell).
systemd-firstboot --machine-id=`cat /etc/machine-id` --hostname=`hostname` --copy --root="${new_root}"
cp -a --parents /etc/{passwd,group,gshadow,vconsole.conf} "${new_root}/"
cp -a /{home,root} "${new_root}/"

# CentOS release files and yum keys.
wget -qr -np -nH -nd  "${m}" -A 'centos-release-8.*.el8.x86_64.rpm' -P /tmp/
rpm --root "${new_root}" -i /tmp/centos-release-8.*.el8.x86_64.rpm
mkdir -p /etc/pki/rpm-gpg
cp "${new_root}"/etc/pki/rpm-gpg/* /etc/pki/rpm-gpg

# Full yum install, equivalent to CentOS 8 ISO "Minimal Install" + necessary packages (only rsync for now).
yum groupinstall --installroot="${new_root}" --releasever=8 -y "Core" "Minimal Install"
rpm --root "${new_root}" -e --nodeps libcurl-minimal
yum install --installroot="${new_root}" --releasever=8 -y brotli chrony cracklib-dicts device-mapper-event device-mapper-event-libs device-mapper-persistent-data freetype geolite2-city geolite2-country glibc-langpack-en gnupg2-smime grub2-pc grub2-pc-modules grub2-tools-extra hardlink kernel kernel-modules kpartx langpacks-en libaio libcurl libevent libmaxminddb libnfsidmap libpng libpsl libsecret libssh libsss_autofs libsss_sudo libxkbcommon lvm2 lvm2-libs openssl-pkcs11 pigz pinentry publicsuffix-list-dafsa python3-unbound rpm-plugin-systemd-inhibit shared-mime-info sssd-nfs-idmap timedatex trousers trousers-lib xkeyboard-config
yum install --installroot="${new_root}" --releasever=8 -y rsync

# Copy remaining files necessary for proper functionality.
cp -a --parents /etc/{crypttab,fstab,resolv.conf} "${new_root}/"
cp -a --parents /etc/default/grub "${new_root}/"
cp -a --parents /etc/ssh/*_key{,.pub} "${new_root}/"
cp -a --parents /etc/audit/audit.rules "${new_root}/"
cp -a --parents /etc/firewalld/zones/*.xml "${new_root}/"
cp -a --parents /etc/sysconfig/{kernel,network} "${new_root}/"
cp -a --parents /etc/sysconfig/network-scripts/{ifcfg,route,rule}-* "${new_root}/"
cp -a /etc/lvm/{archive,backup} "${new_root}/etc/lvm/"
sed -i '/DEFAULTKERNEL=kernel/ s/$/-core/' "${new_root}/etc/sysconfig/kernel"

# Your own pre commands and scripts.
(( ${#p[@]} )) && for c in "${p[@]}"; do `${c}`; done
(( ${#s[@]} )) && for c in "${s[@]}"; do cp -a --parents "${c}" "${new_root}/"; `${c}`; done
(( ${#S[@]} )) && for c in "${S[@]}"; do cp -a --parents "${c}" "${new_root}/"; done

# Here we switch over to the new CentOS 8 install. Still running in a temporary OS.
# If SSH is lost here, connection reset by peer. RIP.
cd "${new_root}"
mount --make-private /
mount --make-private .
pivot_root . slash
exec chroot . bin/bash /usr/local/bin/887_p1.sh "$@"