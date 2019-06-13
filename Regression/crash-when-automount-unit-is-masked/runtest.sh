#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/systemd/Regression/crash-when-automount-unit-is-masked
#   Description: automount: if an automount unit is masked, don't react to activation anymore
#   Author: Frantisek Sumsal <fsumsal@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2017 Red Hat, Inc.
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

    rlPhaseStartTest
        rlRun "systemctl status proc-sys-fs-binfmt_misc.automount" 0-255
        rlRun "systemctl stop proc-sys-fs-binfmt_misc.automount"
        rlRun "systemctl start proc-sys-fs-binfmt_misc.automount"
        rlRun "systemctl status proc-sys-fs-binfmt_misc.automount"
        rlRun "systemctl mask proc-sys-fs-binfmt_misc.automount"
        rlRun "systemctl status proc-sys-fs-binfmt_misc.automount"

        rlLogInfo "systemd should not crash after this ls [BZ#1498318]"
        rlRun "ls -l /proc/sys/fs/binfmt_misc" 2
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "systemctl unmask proc-sys-fs-binfmt_misc.automount"
        rlRun "systemctl stop proc-sys-fs-binfmt_misc.automount"
        rlRun "systemctl start proc-sys-fs-binfmt_misc.automount"
        rlRun "systemctl status proc-sys-fs-binfmt_misc.automount"
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
