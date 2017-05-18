#!/usr/bin/env perl
# Copyright 2017 Elasticsearch Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use strict;

my $command = "mk_audit_syscalls.pl ". join(' ', @ARGV);

sub fmt {
    my ($num, $name) = @_;
    print "\t\t$num: \"$name\",\n";
}

my $base_url = "https://raw.githubusercontent.com/linux-audit/audit-userspace/990aa27ccd02f9743c4f4049887ab89678ab362a/lib";
my @tables = (
    "aarch64",
    "arm",
    "i386",
    "ia64",
    "ppc",
    "s390",
    "s390x",
    "x86_64",
);

`curl -s -O https://raw.githubusercontent.com/linux-audit/audit-userspace/990aa27ccd02f9743c4f4049887ab89678ab362a/lib/x86_64_table.h`;
`curl -s -O https://raw.githubusercontent.com/linux-audit/audit-userspace/990aa27ccd02f9743c4f4049887ab89678ab362a/lib/x86_64_table.h`;

sub downloadTable {
    my ($arch) = @_;
    `curl -s -O https://raw.githubusercontent.com/linux-audit/audit-userspace/990aa27ccd02f9743c4f4049887ab89678ab362a/lib/${arch}_table.h`;
}

sub readTable {
    my ($file) = @_;

    # Read syscall number to name mapping.
    open(FILE, $file);
    my %num_to_name;
    while(<FILE>){
        # Example: _S(14, "rt_sigprocmask")
        if(/^_S\((\d+),\s+"(\w+)"/){
            $num_to_name{$1} = $2;
        }
    }
    close FILE;

    return %num_to_name;
}

print <<EOF;
// $command
// MACHINE GENERATED BY THE ABOVE COMMAND; DO NOT EDIT

// Copyright 2017 Elasticsearch Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package auparse

// auditSyscalls is a mapping of arch names to tables of syscall numbers to names.
// For example, x86_64 -> 165 = "mount".
var auditSyscalls = map[string]map[int]string{
EOF

foreach my $arch (sort @tables) {
    downloadTable $arch;
    my %num_to_name = readTable("${arch}_table.h");

    print "\t\"${arch}\": map[int]string{\n";

    foreach my $syscall (sort {$a <=> $b} keys %num_to_name) {
        my $name = $num_to_name{$syscall};
        fmt($syscall, $name);
    }

    print "\t},\n";
}

print <<EOF;
}

EOF
