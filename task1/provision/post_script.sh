#!/usr/bin/env bash
#
# Build and populate the VM: install and/or compile the necessary
# tools needed to run the templateproject Flask application with Apache and mod_uwsgi.
#
# This script is automatically run the *first time* you issue the command:
#
#    vagrant up
#

# Some convenience variables
LOG_BASE=/var/log
WWW_ROOT=/var/www
PROJECT_ROOT="$WWW_ROOT/templateproject"
PROJECT_TARGET="$PROJECT_ROOT/templateproject"
SOURCE_ROOT="/vagrant"
PROJECT_SOURCE="$SOURCE_ROOT/templateproject"

#--- FUNCTION ----------------------------------------------------------------
# NAME: __function_defined
# DESCRIPTION: Checks if a function is defined within this scripts scope
# PARAMETERS: function name
# RETURNS: 0 or 1 as in defined or not defined
#-------------------------------------------------------------------------------
__function_defined() {
    FUNC_NAME=$1
    if [ "$(command -v $FUNC_NAME)x" != "x" ]; then
        echoinfo "Found function $FUNC_NAME"
        return 0
    fi

    echodebug "$FUNC_NAME not found...."
    return 1
}

#--- FUNCTION ----------------------------------------------------------------
# NAME: __strip_duplicates
# DESCRIPTION: Strip duplicate strings
#-------------------------------------------------------------------------------
__strip_duplicates() {
    echo "$@" | tr -s '[:space:]' '\n' | awk '!x[$0]++'
}

#--- FUNCTION ----------------------------------------------------------------
# NAME: echoerr
# DESCRIPTION: Echo errors to stderr.
#-------------------------------------------------------------------------------
echoerror() {
    printf "%s * ERROR%s: %s\n" "${RC}" "${EC}" "$@" 1>&2;
}

#--- FUNCTION ----------------------------------------------------------------
# NAME: echoinfo
# DESCRIPTION: Echo information to stdout.
#-------------------------------------------------------------------------------
echoinfo() {
    printf "%s * STATUS%s: %s\n" "${GC}" "${EC}" "$@";
}

#--- FUNCTION ----------------------------------------------------------------
# NAME: echowarn
# DESCRIPTION: Echo warning informations to stdout.
#-------------------------------------------------------------------------------
echowarn() {
    printf "%s * WARN%s: %s\n" "${YC}" "${EC}" "$@";
}

#--- FUNCTION ----------------------------------------------------------------
# NAME: echodebug
# DESCRIPTION: Echo debug information to stdout.
#-------------------------------------------------------------------------------
echodebug() {
    if [ $_ECHO_DEBUG -eq $BS_TRUE ]; then
        printf "${BC} * DEBUG${EC}: %s\n" "$@";
    fi
}
#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  __apt_get_install_noinput
#   DESCRIPTION:  (DRY) apt-get install with noinput options
#-------------------------------------------------------------------------------
__apt_get_install_noinput() {
    apt-get install -y -o DPkg::Options::=--force-confold "$@"; return $?
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  __apt_get_upgrade_noinput
#   DESCRIPTION:  (DRY) apt-get upgrade with noinput options
#-------------------------------------------------------------------------------
__apt_get_upgrade_noinput() {
    apt-get upgrade -y -o DPkg::Options::=--force-confold; return $?
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  __pip_install_noinput
#   DESCRIPTION:  (DRY)
#-------------------------------------------------------------------------------
__pip_install_noinput() {
    pip install --upgrade "$@"; return $?
    # Uncomment for Python 3
    #pip3 install --upgrade $@; return $?
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  __pip_install_noinput
#   DESCRIPTION:  (DRY)
#-------------------------------------------------------------------------------
__pip_pre_install_noinput() {
    pip install --pre --upgrade "$@"; return $?
    # Uncomment for Python 3
    # pip3 install --pre --upgrade $@; return $?
}


#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  __check_apt_lock
#   DESCRIPTION:  (DRY)
#-------------------------------------------------------------------------------
__check_apt_lock() {
    lsof /var/lib/dpkg/lock > /dev/null 2>&1
    RES=`echo $?`
    return $RES
}

__enable_universe_repository() {
    if [ "x$(grep -R universe /etc/apt/sources.list /etc/apt/sources.list.d/ | grep -v '#')" != "x" ]; then
        # The universe repository is already enabled
        return 0
    fi

    echodebug "Enabling the universe repository"
    # Ubuntu versions higher than 12.04 do not live in the old repositories
    add-apt-repository -y "deb http://archive.ubuntu.com/ubuntu $(lsb_release -sc) universe" || return 1

    add-apt-repository -y "deb http://old-releases.ubuntu.com/ubuntu $(lsb_release -sc) universe" || return 1

    return 0
}

install_ubuntu_pip_packages() {

    pip_packages="flask
        python-magic"

    ERROR=0

    for PACKAGE in $pip_packages; do
        CURRENT_ERROR=0
        echoinfo "Installed Python Package: $PACKAGE"
        __pip_install_noinput $PACKAGE >> $LOG_BASE/templateproject-install.log 2>&1 || (let ERROR=ERROR+1 && let CURRENT_ERROR=1)
        if [ $CURRENT_ERROR -eq 1 ]; then
            echoerror "Python Package Install Failure: $PACKAGE"
        fi
    done

    if [ $ERROR -ne 0 ]; then
        echoerror
        return 1
    fi
    return 0
}

create_directories() {
  echoinfo "Creating the required directories..."
  if [ -d "$WWW_ROOT" ]; then
  	rm -rf "$WWW_ROOT"
  fi
   mkdir "$WWW_ROOT"
   mkdir "$PROJECT_ROOT"
   chmod -R 777 "$PROJECT_ROOT"
   chown -R www-data:www-data "$PROJECT_ROOT"
}

configure_webstack() {
  echoinfo "Configuring web stack..."

   # Temporary: Create and perm-fix log file
  echoinfo "Preparing log file"
  sudo touch /var/log/templateproject.log
  sudo chmod 666 /var/log/templateproject.log

  if [ -d "$WWW_ROOT/templateproject" ]; then
    rm -rf "$WWW_ROOT/templateproject"
  fi

   mkdir -p "$WWW_ROOT/templateproject/dynamic"
   mkdir -p "$WWW_ROOT/templateproject/static"
   chown www-data:www-data "$WWW_ROOT/templateproject/dynamic"
   chown www-data:www-data "$WWW_ROOT/templateproject/static"
   chmod 777 "$WWW_ROOT/templateproject/dynamic"
   chmod 777 "$WWW_ROOT/templateproject/static"

   # Put the templateproject python script in the right place
   cp -f "$SOURCE_ROOT/templateproject/dynamic/"*.py "$WWW_ROOT/templateproject/dynamic"
   chown www-data:www-data "$SOURCE_ROOT/templateproject/dynamic/"*.py
   cp -f "$SOURCE_ROOT/templateproject/static/"*.py "$WWW_ROOT/templateproject/static"
   chown www-data:www-data "$SOURCE_ROOT/templateproject/static/"*.py

   # Copy over the wsgi file
   cp -f "$SOURCE_ROOT/templateproject/dynamic/"*.wsgi "$WWW_ROOT/templateproject/dynamic"
   chown www-data:www-data "$SOURCE_ROOT/templateproject/dynamic/"*.wsgi
   cp -f "$SOURCE_ROOT/templateproject/static/"*.wsgi "$WWW_ROOT/templateproject/static"
   chown www-data:www-data "$SOURCE_ROOT/templateproject/static/"*.wsgi

   # Perms (fix)
   chmod -R 777 "$WWW_ROOT/templateproject/dynamic/"
   chmod -R 777 "$WWW_ROOT/templateproject/static/"

   # Append host record to hosts file
   cat "$SOURCE_ROOT/etc/hosts" >> "/etc/hosts"

   # Copy over the configuration file
   cp -f "$SOURCE_ROOT/etc/apache2/sites-available/"*.conf "/etc/apache2/sites-available"

   # Enable the new virtual host and restart apache
   echoinfo "Enabling vhost ..."
   a2dissite 000-default.conf
   a2ensite my.templateproject.conf

   echoinfo "Restarting apache2 ..."
   systemctl restart apache2

   # Give vagrant user access to www-data
   usermod -a -G www-data vagrant

}

complete_message() {
    echo
    echo "Installation Complete!"
    echo
}

OS=$(lsb_release -si)
ARCH=$(uname -m | sed 's/x86_//;s/i[3-6]86/32/')
VER=$(lsb_release -sr)

if [ $OS != "Ubuntu" ]; then
    echo "Only installable on the Ubuntu operating system at this time."
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

# Configure and install everything else
create_directories
install_ubuntu_pip_packages $ITYPE
configure_webstack
complete_message
