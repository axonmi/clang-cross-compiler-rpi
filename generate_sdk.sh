#!/bin/bash

set -e

SYSROOT_DOWNLOAD_PATH="https://storage.googleapis.com/axon-artifacts/sysroot-stretch-9.1-20180104-2.tar.gz"
BINUTILS_DOWNLOAD_PATH="https://ftp.gnu.org/gnu/binutils/binutils-2.28.tar.bz2"
usage="$(basename "$0") [-h] -s <directory_of_sdk> -- This script generates the SDK directory for Raspberry Pi that can be used to compile C/C++ programs using clang.

where:
    -h  show this help text
    -s  The directory where the SDK should be generated"

sdk_output_dir=""
while getopts ':hs:' option; do
  case "$option" in
    h) echo "$usage"
       exit
       ;;
    s) sdk_output_dir=$OPTARG
       ;;
    :) printf "missing argument for -%d\n" "$OPTARG" >&2
       echo "$usage" >&2
       exit 1
       ;;
   \?) printf "illegal option: -%s\n" "$OPTARG" >&2
       echo "$usage" >&2
       exit 1
       ;;
  esac
done
shift $((OPTIND - 1))

if [ "${sdk_output_dir}" == "" ]
then
    echo "Missing argument for -s" >&2
    echo "$usage" >&2
    exit 1
fi

mkdir -p ${sdk_output_dir}
sdk_output_dir=$(cd ${sdk_output_dir}; pwd)
sdk_host_output_dir="${sdk_output_dir}/host"
sdk_sysroot_output_dir="${sdk_output_dir}/sysroot"

printf "SDK Gen Dir %s\n" "${sdk_output_dir}"

# The directory structure is as follows:
# SDK_OUTPUT_DIR
#     sysroot: System root folder (from raspberry pi)
#     host: Host binaries. Clang/ld on OSX, scripts/binaries for the
#           cross compiler.
mkdir -p "${sdk_output_dir}"
mkdir -p "${sdk_host_output_dir}"
mkdir -p "${sdk_sysroot_output_dir}"

system_name=$(uname -s)

# Build LD that can target ARM on Linux.
tmpdir=$(mktemp -d)
pushd ${tmpdir}
curl ${BINUTILS_DOWNLOAD_PATH} | tar -jx
pushd binutils-2.28

host_arch=$("./config.guess")
./configure --prefix="${sdk_host_output_dir}" \
    --build=${host_arch} \
    --host=${host_arch} \
    --target=arm-linux-gnueabihf \
    --enable-gold=yes \
    --enable-ld=yes \
    --enable-targets=arm-linux-gnueabihf \
    --enable-multilib \
    --enable-interwork \
    --disable-werror \
    --quiet

make -j5 && make install
popd
popd
rm -rf ${tmpdir}


# Sysroot from RPI
pushd ${sdk_sysroot_output_dir}
curl ${SYSROOT_DOWNLOAD_PATH} | tar -xz
popd

#TODO(zasgar): Figure out why this is needed? Probably something to do with LD compile options.
cp -R ${sdk_sysroot_output_dir}/* ${sdk_host_output_dir}/arm-linux-gnueabihf

cp arm-linux-gnueabihf-clang ${sdk_host_output_dir}/bin
chmod +x ${sdk_host_output_dir}/bin/arm-linux-gnueabihf-clang

cp arm-linux-gnueabihf-clang++ ${sdk_host_output_dir}/bin
chmod +x ${sdk_host_output_dir}/bin/arm-linux-gnueabihf-clang++


echo "=============================="
echo " SDK generation complete"
echo " Add the following to bashrc/zshrc files:"
echo "   export PATH=${sdk_host_output_dir}/bin:\$PATH"
echo "=============================="

