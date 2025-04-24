#!/bin/bash
# Script to download squashfs-tools v4.3, apply the patches, perform a clean build, and install.

# If not root, perform 'make install' with sudo
if [ $UID -eq 0 ]
then
    SUDO=""
else
    SUDO="sudo"
fi

# Install prerequisites
if hash apt-get &>/dev/null
then
    $SUDO apt-get install build-essential liblzma-dev liblzo2-dev zlib1g-dev
fi

# Make sure we're working in the same directory as the build.sh script
cd $(dirname `readlink  -f $0`)

# Download squashfs4.3.tar.gz if it does not already exist
if [ ! -e squashfs4.3.tar.gz ]
then
    wget https://downloads.sourceforge.net/project/squashfs/squashfs/squashfs4.3/squashfs4.3.tar.gz
fi

# Remove any previous squashfs4.3 directory to ensure a clean patch/build
rm -rf squashfs4.3

# Extract squashfs4.3.tar.gz
tar -zxvf squashfs4.3.tar.gz

# Patch, build, and install the source

cd squashfs4.3/squashfs-tools/

sed -i.orig 's/FNM_EXTMATCH/0/; s/sysinfo.h/sysctl.h/; s/^inline/static inline/' mksquashfs.c unsquashfs.c

cat <<END >> xattr.h
#define llistxattr(path, list, size) \
  (listxattr(path, list, size, XATTR_NOFOLLOW))
#define lgetxattr(path, name, value, size) \
  (getxattr(path, name, value, size, 0, XATTR_NOFOLLOW))
#define lsetxattr(path, name, value, size, flags) \
  (setxattr(path, name, value, size, 0, flags | XATTR_NOFOLLOW))
END

cd ..

patch -p1 < ../mac.patch
patch -p0 < ../patches/patch0.txt

cd squashfs-tools
sed -i.orig 's/\-Werror/\-Werror \-Wno\-self\-assign/' Makefile
sed -i.orig 's/#LZO_DIR \= .*/LZO_DIR \= \/opt\/homebrew\/opt\/lzo/' Makefile
sed -i.orig 's/#LZMA_XZ_SUPPORT \= 1/EXTRA_CFLAGS \= \-I\/opt\/homebrew\/opt\/xz\/include/' Makefile

make
