#!/usr/bin/env bash
set -Eeuo pipefail

lemmy-help -c -f -t lua/dap-python.lua >doc/dap-python.txt
