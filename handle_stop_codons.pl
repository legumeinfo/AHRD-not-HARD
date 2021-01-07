#!/usr/bin/env perl
use strict;
use Getopt::Long;
my $filter_internal_stop_proteins=0;
#if you need to specify * on commandline do it as --srop_char '\*'
my $stop_char = "\\.";
my $replacement_stop_char = "X";
GetOptions(
    "filter_internal_stop_proteins" => \$filter_internal_stop_proteins,
    "stop_char=s" => \$stop_char,
    "replacement_stop_char=s" => \$replacement_stop_char,
);
$/="\n>";
while (<>) {
    chomp;
    s/^>//;
    my ($header, $seq) = /([^\n]+)\n(.*)/s;
    $seq =~ s/\n//g;
    $seq =~ s/${stop_char}$//;
    if ($seq =~ /${stop_char}/) {
        print STDERR $header,"\n";
        if (!$filter_internal_stop_proteins) {
            $seq =~ s/${stop_char}/${replacement_stop_char}/g;
            print ">$header\n$seq\n";
        }
    }
    else {
        print ">$header\n$seq\n";
    }

}
