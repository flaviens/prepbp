# Copyright Flavien Solt, ETH Zurich.
# Licensed under the General Public License, Version 3.0, see LICENSE for details.
# SPDX-License-Identifier: GPL-3.0-only

set -e

source env_low.sh
mkdir -p traces
fusesoc run run_low
