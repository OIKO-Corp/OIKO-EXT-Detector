#!/bin/bash
# +----------------+
# | npm preinstall |
# +----------------+

# get the installer directory
Installer_get_current_dir () {
  SOURCE="${BASH_SOURCE[0]}"
  while [ -h "$SOURCE" ]; do
    DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
  done
  echo "$( cd -P "$( dirname "$SOURCE" )" && pwd )"
}

Installer_dir="$(Installer_get_current_dir)"

# move to installler directory
cd "$Installer_dir"

source utils.sh
cd ..

# check version in package.json file
Installer_version="$(grep -Eo '\"version\"[^,]*' ./package.json | grep -Eo '[^:]*$' | awk  -F'\"' '{print $2}')"
Installer_module="$(grep -Eo '\"name\"[^,]*' ./package.json | grep -Eo '[^:]*$' | awk  -F'\"' '{print $2}')"

# Let's start !
Installer_info "Welcome to $Installer_module v$Installer_version"
echo

# delete package-lock.json (force)
rm -f ../package-lock.json

# Check not run as root
if [ "$EUID" -eq 0 ]; then
  Installer_error "npm install must not be used as root"
  exit 255
fi

# Check platform compatibility
Installer_info "Checking OS..."
Installer_checkOS
if  [ "$platform" == "osx" ]; then
  Installer_error "OS Detected: $OSTYPE ($os_name $os_version $arch)"
  Installer_error "You need to do Manual Install"
  exit 0
else
  Installer_success "OS Detected: $OSTYPE ($os_name $os_version $arch)"
fi

echo

# Required packages on Debian based systems
deb_dependencies=(libmagic-dev libatlas-base-dev sox libsox-fmt-all build-essential)
# Required packages on RPM based systems
rpm_dependencies=(blas-devel file-libs sox sox-devel wget autoconf automake binutils bison flex gcc gcc-c++ glibc-devel libtool make pkgconf strace byacc ccache cscope ctags elfutils indent ltrace perf valgrind)
# Check dependencies
if [ "${debian}" ]
then
  dependencies=( "${deb_dependencies[@]}" )
else
  if [ "${have_dnf}" ]
  then
    dependencies=( "${rpm_dependencies[@]}" )
  else
    if [ "${have_yum}" ]
    then
      dependencies=( "${rpm_dependencies[@]}" )
    else
      dependencies=( "${deb_dependencies[@]}" )
    fi
  fi
fi

[ "${__NO_DEP_CHECK__}" ] || {
  Installer_info "Checking all dependencies..."
  Installer_check_dependencies
  Installer_success "All Dependencies needed are installed !"
}

cd ..

echo
Installer_info "Installing all npm libraries..."
