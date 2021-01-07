#!/usr/bin/env perl
use strict;
use warnings;
my $ahrd_f = shift;
my %gene_notes;

open(AHRD_FILE, $ahrd_f) or die $!;
while(<AHRD_FILE>) {
    chomp;
    my @split = split /\t/;
    my ($key, $value) = ($split[0], $split[1]);
    $value =~ s/%/%25/g;
    $value =~ s/;/%3B/g;
    $value =~ s/=/%3D/g;
    $value =~ s/&/%26/g;
    $value =~ s/,/%2C/g;
    $gene_notes{$key} = $value;
}
close AHRD_FILE;

#Input file is the corrected GFF that needs addition of Note attr values (ahrd)
while( my $line = <>) {
    if ($line =~ /^#/) {
        print $line;
        next;
    }
    chomp($line);
    $line =~ s/;$//;
    my @split = split("\t", $line);
    if($split[2] eq 'gene') {
        my ($gene_name) = ($split[8] =~ /ID=([^;]+)/);
        if (exists $gene_notes{$gene_name}) {
            if ($split[8] =~ /Note=/) {
                $split[8] =~ s/Note=[^;]*/Note=$gene_notes{$gene_name}/;
                $line = join("\t", @split);
            }
            else {
                $line .= ";Note=$gene_notes{$gene_name}";
            }
        }
    }
    print "$line\n";
}

