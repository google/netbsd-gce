#!/usr/bin/env python
# Copyright 2016 The Go Authors. All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

import anita
import ftplib
import sys

def find_latest_release(branch, arch):
  """Find the latest NetBSD-current release for the given arch.

  Returns:
    the full path to the release.
  """
  conn = ftplib.FTP('nyftp.netbsd.org')
  conn.login()
  conn.cwd('/pub/NetBSD-daily/%s' % branch)
  releases = conn.nlst()
  releases.sort(reverse=True)
  for r in releases:
    archs = conn.nlst(r)
    if not archs:
      next
    has_arch = [a for a in archs if a.endswith(arch)]
    if has_arch:
      return "https://nycdn.netbsd.org/pub/NetBSD-daily/%s/%s/" % (branch, has_arch[0])


arch = sys.argv[1]
branch = sys.argv[2]

commands = [
    """cat > /etc/ifconfig.vioif0 << EOF
!dhcpcd vioif0
EOF""",
    "dhcpcd",
    """ed /etc/fstab << EOF
H
%s/wd0/sd0/
wq
EOF""",
    "sync; shutdown -hp now",
]


a = anita.Anita(
    anita.URL(find_latest_release(branch, arch)),
    workdir="work-%s-%s" % (branch, arch),
    disk_size="4G",
    memory_size = "1G",
    persist=True)
child = a.boot()
anita.login(child)

for cmd in commands:
  anita.shell_cmd(child, cmd, 1200)

# Sometimes, the halt command times out, even though it has completed
# successfully.
try:
    a.halt()
except:
    pass
