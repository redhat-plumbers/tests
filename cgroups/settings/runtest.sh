#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/systemd/Sanity/cgroups
#   Description: Check functionality of various cgroup-related settings/utils
#   Author: Frantisek Sumsal <fsumsal@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2018 Red Hat, Inc.
#
#   This program is free software: you can redistribute it and/or
#   modify it under the terms of the GNU General Public License as
#   published by the Free Software Foundation, either version 2 of
#   the License, or (at your option) any later version.
#
#   This program is distributed in the hope that it will be
#   useful, but WITHOUT ANY WARRANTY; without even the implied
#   warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE.  See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program. If not, see http://www.gnu.org/licenses/.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Include Beaker environment
. /usr/bin/rhts-environment.sh || exit 1
. /usr/share/beakerlib/beakerlib.sh || exit 1

PACKAGE="systemd"

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm $PACKAGE
        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"
    rlPhaseEnd

    rlPhaseStartTest "Ensure we use the legacy cgroup hierarchy"
        # If this returns "cgroups2fs" we're in full cgroupsv2 mode,
        # otherwise it should return tmpfs (for hybrid and legacy modes)
        rlRun "[[ $(stat -fc %T /sys/fs/cgroup/) == 'tmpfs' ]]"
        # If /sys/fs/cgroup/unified exists, we're in hybrid mode, otherwise
        # we're in legacy mode
        rlRun "[[ ! -e /sys/fs/cgroup/unified ]]"
    rlPhaseEnd

    rlPhaseStartTest "_CGROUP_CONTROLLER_MASK_ALL does not cover CGROUP_PIDS [BZ#1532586]"
        UNIT_PATH="$(mktemp /etc/systemd/system/cgroupsXXX.service)"
        UNIT_NAME="${UNIT_PATH##*/}"

        # Setup
        cat > "$UNIT_PATH" << EOF
[Service]
ExecStart=/bin/sleep 99h
Delegate=yes
EOF
        rlRun "systemctl daemon-reload"
        rlRun "systemctl cat $UNIT_NAME"
        rlRun "systemctl start $UNIT_NAME"

        # Test
        rlRun "eval $(systemctl show -p MainPID $UNIT_NAME)"
        rlRun "[[ ! -z $MainPID ]]"
        rlRun "grep -E 'pids:.*$UNIT_NAME' /proc/$MainPID/cgroup"

        # Cleanup
        rlRun "systemctl stop $UNIT_NAME"
        rlRun "rm -fv $UNIT_PATH"
        rlRun "systemctl daemon-reload"
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
