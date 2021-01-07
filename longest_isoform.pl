#!/usr/bin/env perl
use strict;
use Getopt::Long;
my $lookup;
my $exclude_lookup_misses=0;
my $gene_in_header=0;
GetOptions(
	"lookup=s" => \$lookup,
	"exclude_lookup_misses" => \$exclude_lookup_misses,
	"gene_in_header" => \$gene_in_header,
);
my %lookup;
if (defined $lookup) {
	open(L, $lookup) || die $!;
	while (<L>) {
		chomp;
		my ($gene, $prot) = split /,/;
		$lookup{$prot} = $gene;
	}
	close L;
}
my %longest;
$/="\n>";
while (<>) {
    chomp;
    s/^>//;
    my ($header, $seq) = /^([^\n]+)\n(.*)/ms;
    my ($id,$rest_of_header) = ($header =~ /^(\S+)(.*)/);
    my $gene;
    if (defined $lookup) {
        $gene = $lookup{$id};
        if (! defined $gene && $exclude_lookup_misses) {
            next;
        }
    }
    if (! defined $gene) {
        ($gene) = ($header =~ /gene[=:](\S+)/);
    }
    if (! defined $gene) {
        ($gene) = ($id =~ /^(.+)\.\d+$/);
    }
    #maker-style
    if (! defined $gene) {
        ($gene) = ($id =~ /^(.*)-mRNA-\d+/);
    }
    if (! defined $gene) {
        ($gene) = ($id =~ /^(\S+)\.m\d+/);
    }
    if (! defined $gene) {
        ($gene) = ($id =~ /^(.+)\.\d+\.p$/);
    }
    if (! defined $gene) {
        ($gene) = ($id =~ /^(.+)\.\d+\|/);
    }
    if (! defined $gene) {
        ($gene) = ($id =~ /^(.+)T\d+$/);
    }
    $seq =~ s/\n//g;
    if (!defined $longest{$gene}) {
        $longest{$gene}->{id} = $id;
        $longest{$gene}->{rest_of_header} = $rest_of_header;
        $longest{$gene}->{seq} = $seq;
        $longest{$gene}->{len} = length($seq);
    }
    elsif (length($seq) > $longest{$gene}->{len}) {
        $longest{$gene}->{id} = $id;
        $longest{$gene}->{rest_of_header} = $rest_of_header;
        $longest{$gene}->{seq} = $seq;
        $longest{$gene}->{len} = length($seq);
    }
    #just so the output isn't dependent on order of sequences in input
    elsif (length($seq) == $longest{$gene}->{len} && ($longest{$gene}->{header} cmp $header > 0)) {
        $longest{$gene}->{id} = $id;
        $longest{$gene}->{rest_of_header} = $rest_of_header;
        $longest{$gene}->{seq} = $seq;
        $longest{$gene}->{len} = length($seq);
    }
}

foreach my $gene (sort keys %longest) {
    print ">",$longest{$gene}->{id}, ($gene_in_header ? " gene=$gene" : ""),$longest{$gene}->{rest_of_header},"\n";
    print $longest{$gene}->{seq},"\n";
}
