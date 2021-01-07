#!/usr/bin/env perl
use strict;
use Getopt::Long;
my $gene_from_query_regexp;
my $evalue_threshold="1e-10";
GetOptions(
    "gene_from_query_regexp=s", \$gene_from_query_regexp,
    "evalue_threshold=f", \$evalue_threshold,
);
print "ScoreMeaning\te-value\n";
print "#gene\tfamily\tprotein\tscore\n";
my %pep2family;
my $family;
while (<>) {
    if (/^Query:\s+(\S+)/) {
        $family = $1;
    }
    elsif (/^>>\s*(\S+)(.*)/) {
        my $pep = $1;
        next unless defined $pep2family{$pep}->{family};
        my $desc = $2;
        #the gffread phytozome ensembl conventions for fasta headers
        my (undef, $gene) = ($desc =~ /(gene|locus)[=:](\S+)/);
        if (defined $gene) {
            $pep2family{$pep}->{gene} = $gene;
        }
        next;
    }
    elsif (/^\s+E-value/) {
        <>;
        while (<>) {
            last if /^$/;
            next if /^\s*-*\s*inclusion threshold/;
            s/^\s+//;
            my @data = split /\s+/;
            my $evalue = $data[0];
            #worked fine, until we hit descriptions that had more than just the gene id
            #my $gene = $data[$#data];
            my $pep = $data[8];
            my $gene;
            if (defined $gene_from_query_regexp) {
                ($gene) = ($pep =~ /$gene_from_query_regexp/);
            }
            if ($evalue <= $evalue_threshold) {
                if (! defined $pep2family{$pep} || ! defined $pep2family{$pep}->{evalue} || $evalue < $pep2family{$pep}->{evalue}) {
                    $pep2family{$pep}->{evalue} = $evalue;
                    $pep2family{$pep}->{family} = $family;
                    if (defined $gene) {
                        $pep2family{$pep}->{gene} = $gene;
                    }
                }
            }
        }
    }

}

foreach my $pep (keys %pep2family) {
    if (defined $pep2family{$pep}->{family}) {
        print $pep2family{$pep}->{gene},"\t",$pep2family{$pep}->{family},"\t", $pep,"\t", $pep2family{$pep}->{evalue}, "\n";
    }
}
