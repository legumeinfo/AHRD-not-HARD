#!/usr/bin/env perl
use strict;
use Getopt::Long;
use IO::Handle;
my($chunksize, $numchunks);
my $chunk_prefix;
my $compress = 0;
my $split_on_gaps = 0;
GetOptions(
    "chunksize=i" => \$chunksize,
    "numchunks=i" => \$numchunks,
    "chunk_prefix=s" => \$chunk_prefix,
    "compress" => \$compress,
    "split_on_gaps=i" => \$split_on_gaps,
);
if (!defined $chunksize && !defined $numchunks) {
    die "please specify either --chunksize or --numchunks\n";
}
if (defined $chunksize && defined $numchunks) {
    die "please specify only one of --chunksize or --numchunks\n";
}
if (!defined $chunk_prefix) {
    $chunk_prefix = join("+", @ARGV);
}
$/="\n>";
my @chunkfiles;
my $i = 0;
my $current_chunksize = 0;
my $current_chunk = 0;
my $ioref;
if (defined $numchunks) {
    for (my $i=0; $i< $numchunks; $i++) {
        open my $io, ">$chunk_prefix-$i.fa" || die $!;
        push @chunkfiles, $io;
    }
}
else {
    open OUT, ">$chunk_prefix-$current_chunk.fa" || die $!;
    $ioref = *OUT{IO};
}
while (<>) {
    chomp;
    my($header, $seq) = /^>?([^\n]*)\n(.*)/sm;
    #my $length = length($seq) - scalar(split("\n", $seq)) + 1;
    if (defined $numchunks) {
        $ioref = $chunkfiles[$i % $numchunks];
    } else {
        if ($current_chunksize >= $chunksize) {
            close $ioref;
            system("gzip $chunk_prefix-$current_chunk.fa") if $compress;
            $current_chunk++;
            $current_chunksize=0;
            open OUT, ">$chunk_prefix-$current_chunk.fa" || die $!;
            $ioref = *OUT{IO};
        }
    }
    if ($split_on_gaps) {
	$seq =~ s/\n//sg;
        my (@seq_and_gaps) = split("([Nn]{$split_on_gaps,})", $seq);
        my $offset = 0;
        for (my $j=0; 2*$j < @seq_and_gaps; $j++) {
            if ($current_chunksize >= $chunksize) {
                close $ioref;
                system("gzip $chunk_prefix-$current_chunk.fa") if $compress;
                $current_chunk++;
                $current_chunksize=0;
                open OUT, ">$chunk_prefix-$current_chunk.fa" || die $!;
                $ioref = *OUT{IO};
            }
            $ioref->print(">$header:$offset-".($offset+length($seq_and_gaps[2*$j])-1)."\n$seq_and_gaps[2*$j]\n");
            $offset += length($seq_and_gaps[2*$j]);
            if (2*$j+1 < @seq_and_gaps) {
                $offset += length($seq_and_gaps[2*$j+1]);
            }
            $current_chunksize++;
        }
    }
    else {
        $ioref->print(">$header\n$seq\n");
        $current_chunksize++;
    }
    $i++;
}
system("gzip $chunk_prefix-$current_chunk.fa") if $compress;

