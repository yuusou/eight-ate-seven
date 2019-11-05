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
OPTS=T:m:p:P:s:S:R
LONGOPTS=tempsize:mirror:precommand:postcommand:prescript:postscript:rbind

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
        -R|--rbind)
            R=true
            shift
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

source /etc/profile
source /root/.bash_profile
chown root:ssh_keys /etc/ssh/*key # for some reason ssh_keys guid changes.

# Eight eats seven! We write over / with the new filesystem in new_root.
rsync -aHAXSIxq --exclude={"/dev/*","/proc/*","/sys/*","/run/*","/slash/*","${new_root}/*"} / /slash/ --delete-after

cd /slash
mount --make-private /
mount --make-private .
pivot_root . "${new_root#?}"
exec chroot . bin/bash  /usr/local/bin/887_p2.sh "$@"