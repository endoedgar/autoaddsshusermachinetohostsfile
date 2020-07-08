#!/bin/bash

INSTALL_DIRECTORY="/opt/autoaddusertohostsfile2"
AUTORUN_SCRIPTNAME="addentrytohostsfile.sh"

MANAGE_ETC_HOSTS_SH_FILE="H4sIAGpGBl8AA5WSQU/jMBCF7/4VDxMJKpFEy94WtaKCRK3UpRUNB8QiZGKnsQg2ihOgWvHf1w0Qt6RdCV8SyzPvzXwzZH8vvJcqNDnZx2yYjJBMcT29usRoOk/miMeTiETJ2V1z7YeiSsNcm8rY8PMoHl5NEoxniKfvCRfD3xEZz/reT/s+snGKPQpUGozzsBSP+lkE5DOw7x2TrFZpJbXC++NK+rCHvwT2yAw38BWod7goxRO8z0S4MnoUt01wlQvV/KyOSHNt09r4WNeKQyosdV3Ca/s5wuXKVqoFlH4JgoCetBqm5hpGcPiSBvfsgYKGrWLI6ZpMkyMKI3YW8MKMdaiQ7SjkwzeT5M0hscw2eDhuP9r7/G4yvoj61LNDaE/rS7/PscNyWzusKAXjS4hXaXPxCx1l11qPOirriJzukPPVBFyy3ZftfDZm4/swOfwUvgBtlA48h+QAg8Faf18Evo1kJ5r/TdwO0O6PqdNUmKwuiiX+qC6qdceTjnaH2aZhzGRhPSwxS9GJHiEpl2ALJtXeF1G7Yx+fN+Kdkn8NFHvzAQQAAA=="
MANAGE_ETC_HOSTS_SH_FILENAME="manage-etc-hosts.sh"

ADD_ENTRY_TO_HOSTS_FILE="H4sIAA9HBl8AA42OsQrCMBiE5/5P8Rsz6FDrC2QoUmjBamijICIhtanJ0ESa4vNrh4JubnfcfcctF0ljXdKoYADyYy0OaZkxMit5TvenjEDBGeVpKaspAKh3VcGF5KnIGV21dnCq10jolqwBbIfXj57q4sIzgowh8U/tZNAhWO8I3hCi0WgHEf2aSnrl1EPHerzHxocxbILBQff+pSeLdH71B6ba9pdBWnDoLLwB/zKJsfEAAAA="
ADD_ENTRY_TO_HOSTS_FILENAME="addentrytohostsfile.sh"

SSH_D_SCRIPT="/etc/pam.d/sshd.tmp"

if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root"
        exit 1
fi

function help_func() {
        echo "Usage: $0 install|uninstall [hostname_entry]
where:
        hostname_entry is required if you are installing"
        exit 1
}

if [[ $# -eq 0 ]]; then
        help_func
fi

function install() {
        if [[ $# -ne 1 ]]; then
                help_func
        fi

        [ -d $INSTALL_DIRECTORY ] || mkdir $INSTALL_DIRECTORY

        echo $MANAGE_ETC_HOSTS_SH_FILE | base64 -d | gunzip > $INSTALL_DIRECTORY/$MANAGE_ETC_HOSTS_SH_FILENAME
        chmod 744 $INSTALL_DIRECTORY/$MANAGE_ETC_HOSTS_SH_FILENAME

        echo $ADD_ENTRY_TO_HOSTS_FILE | base64 -d | gunzip | sed "s/HOSTNAME_VALUE/$1/" > $INSTALL_DIRECTORY/$ADD_ENTRY_TO_HOSTS_FILENAME
        chmod 744 $INSTALL_DIRECTORY/$ADD_ENTRY_TO_HOSTS_FILENAME

        LINE_TO_ADD="session    optional     pam_exec.so $INSTALL_DIRECTORY/$AUTORUN_SCRIPTNAME"

        if grep -q "$INSTALL_DIRECTORY" $SSH_D_SCRIPT; then
                echo Line to auto execute script is already on $SSH_D_SCRIPT
        else
                echo Adding line to auto execute script on $SSH_D_SCRIPT
                echo $LINE_TO_ADD >> $SSH_D_SCRIPT
        fi
}

function uninstall() {
        rm -r -f $INSTALL_DIRECTORY
        ESCAPED_INSTALL_DIRECTORY=$(printf '%s\n' "$INSTALL_DIRECTORY" | sed 's/[\/&]/\\&/g')
        sed -i "/$ESCAPED_INSTALL_DIRECTORY/d" $SSH_D_SCRIPT
}
$@
