#!/usr/bin/env python

import subprocess
import sys

args = sys.argv
output_args = []
for arg in args[1:]:
	# Qt forces rpath-link on us but it is not supported by LLD
	if not arg.startswith("-Wl,-rpath-link"):
		output_args.append(arg)
try:
	subprocess.run(["zig", "c++"] + output_args, check=True)
except subprocess.CalledProcessError as e:
	sys.exit(e.returncode)


