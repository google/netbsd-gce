#!/bin/bash
# Copyright 2016 The Go Authors. All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

# This script uses Anita (an automated NetBSD installer) for setting up
# the VM. It needs the following things on the build host:
#  - qemu
#  - cdrtools
#  - GNU tar (not BSD tar)
#  - Python 3
#  - python-pexpect
#  - coreutils (for sha1sum)

set -e -x

ANITA_VERSION=2.10
ARCH=${1:-amd64}
RELEASE=${2:-netbsd-9}
DISK_SIZE=${3:-4G}

# Must use GNU tar. On NetBSD, tar is BSD tar and gtar is GNU.
TAR=tar
if which gtar > /dev/null; then
  TAR=gtar
fi

SHA1SUM=sha1sum
if which gsha1sum > /dev/null; then
  SHA1SUM=gsha1sum
fi

PYTHON=
for cmd in python3 python; do
  if which ${cmd} > /dev/null; then
    PYTHON=${cmd}
    break
  fi
done

WORKDIR=work-${RELEASE}-${ARCH}

# Remove WORKDIR unless -k (keep) is given.
if [ "$1" != "-k" ]; then
  rm -rf ${WORKDIR}
fi

# Download and build anita (automated NetBSD installer).
if ! ${SHA1SUM} -c anita-${ANITA_VERSION}.tar.gz.sha1; then
  curl -vO http://www.gson.org/netbsd/anita/download/anita-${ANITA_VERSION}.tar.gz
  ${SHA1SUM} -c anita-${ANITA_VERSION}.tar.gz.sha1 || exit 1
fi

${TAR} xfz anita-${ANITA_VERSION}.tar.gz
cd anita-${ANITA_VERSION}
# Workaround for https://github.com/gson1703/anita/issues/14 on macOS
curl -o- https://github.com/gson1703/anita/commit/bfe9f04d94806c4830b6195f8c23f3bd085f568b.patch | patch -p1
# end workaround
${PYTHON} setup.py build
cd ..

env PYTHONPATH=${PWD}/anita-${ANITA_VERSION} ${PYTHON} mkvm.py ${ARCH} ${RELEASE} ${DISK_SIZE}

echo "Archiving wd0.img (this may take a while)"
${TAR} --format=oldgnu -Szcf netbsd-${ARCH}-gce.tar.gz --transform s,${WORKDIR}/wd0.img,disk.raw, ${WORKDIR}/wd0.img
echo "Done. GCE image is netbsd-${ARCH}-gce.tar.gz."
