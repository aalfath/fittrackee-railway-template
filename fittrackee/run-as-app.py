"""Run a command as the image's "fittrackee" user (uid/gid 1000).

Used by railway-start.sh after it has made the Railway volume writable.
Replaces su-exec, so the image build needs no package download.
"""
import os
import sys

os.setgroups([])
os.setgid(1000)
os.setuid(1000)
os.environ["HOME"] = "/usr/src/app"
os.execvp(sys.argv[1], sys.argv[1:])
