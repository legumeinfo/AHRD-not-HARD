#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;
my $forks=10;
GetOptions(
    "forks=i" => \$forks,
);

my %libs = (
    glyma => "/erdos/adf/e01/lis/AHRD/blast/Glyma.refseq_protein.fasta",
    arath => "/erdos/adf/e01/lis/AHRD/blast/TAIR10_pep_20101209",
    medtr => "/erdos/adf/e01/lis/AHRD/blast/Mt4.0v1_GenesProteinSeq_20130731_1800.fasta",
    uniref90 => "/erdos/adf/e01/lis/AHRD/blast/uniref90.fasta",
);

my $input_dir = shift;
my $output_dir = shift;
mkdir $output_dir;
my @fasta_files=sort glob("$input_dir/*");
foreach my $lib (keys %libs) {
    mkdir "$output_dir/$lib";
}
my @forked_children;
my $parent_pid = $$;
foreach my $i (1..$forks) {
    if ($$ eq $parent_pid) {
        $forked_children[$i-1] = fork();
    }
}
#every forked process will know which # child it is by the size of the forked_children array at the time it was forked? 
#ie child 1 will see 0, child 2 will see 1, etc.; 
#and only parent will see $forks;
if ($$ eq $parent_pid) {
    while ($forks) {
        wait();
        $forks--;
    }
}
else {
my $child_num = scalar(@forked_children)-1;
print STDERR "i am $child_num\n";
    for (my $i = $child_num; $i < @fasta_files; $i += $forks) {
      my $file=$fasta_files[$i];  
      chomp $file;
      $file =~ s/^$input_dir//;
      #TODO: test newer version of BLAST usable?
      foreach my $lib (keys %libs) {
          my $outfile = "$output_dir/$lib/$file.blastp";
          print STDERR "child $child_num is handling $file against $lib\n";
          if ((! -e $outfile) || (-z $outfile)) {
              system("/erdos/adf/e00/adf/blast-2.2.23/bin/blastall -p blastp -i $input_dir/$file -o $output_dir/$lib/$file.blastp -d $libs{$lib} -e 0.0001 -v 200 -b 200 -m 0 -a 4");
              if ($?) {
                  print STDERR "child $child_num failed to $file against $lib\n";
              }
              else {
                  print STDERR "child $child_num handled $file against $lib\n";
              }
          }
          else {
              print STDERR "$outfile already exists, skipping\n";
          }
      }
    }
}
