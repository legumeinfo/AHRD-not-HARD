# Blast/AHRD annotator
# Runs blastp against specified databases; runs AHRD to collect results; 
#	reports final table including AHRD and best-blast-hit outputs
# W. Nelson 3/18/2017

use strict;
use warnings;
$| = 1;
use YAML::XS;

##############################################################################
#	Configuration:
#	1) Set parameter and path values below
#	2) Set up Blast sections in the AHRD configuration file text at end of script
#		(Blast database paths are read from there)

## Set parameter/path values here:
my $threads 	= 5;
my $eval_thresh	=  1E-3;
my $blastdir  	= "/opt/blast/default/bin";
my $java_path 	= "/usr/local/bin/java";
my $ahrd_jar 	= "ahrd/ahrd.jar";
##############################################################################

check_args();
my $input_file = shift;

check_file("AHRD jar", $ahrd_jar);
check_file("Java executable", $java_path);
check_file("blastp", "$blastdir/blastp");

my %blast_dbs;
my $yml_text = yml_text();
my $ymlh = Load($yml_text); 

check_yml($ymlh,\%blast_dbs); 

# Output files will be named using the input file minus extension and path
my $nameroot = $input_file;
$nameroot =~ s/\.[^\.]*$//; # chop extension 
$nameroot =~ s/.*\///; # chop path

mkdir("working");
system("rm -f working/$nameroot.*");
my $cleaned_path = "working/$nameroot.cleaned";
my $nqueries = check_clean_input_file($input_file,$cleaned_path);

my %blast_best_hits;
my %blast_best_evals;
foreach my $key (keys %blast_dbs)
{
	my $dbpath = $blast_dbs{$key};
	my $outfile = "working/$nameroot.$key.blast";	
	unlink $outfile;
	my $cmd = "$blastdir/blastp -db $dbpath -query $cleaned_path -out $outfile -outfmt 6 -num_threads $threads -evalue $eval_thresh ";
	msgout("Run blast ($key) : $threads threads, evalue $eval_thresh");
	system($cmd);
	if (not -f $outfile)
	{
		die ("Blast $key failed\nCommand was:\n$cmd");
	}
	$ymlh->{blast_dbs}->{$key}->{file} = $outfile;
	my $nhits = parse_blast($outfile,\%blast_best_hits,\%blast_best_evals);
	print "$nhits hits found\n";
}

my $ahrd_outpath = "working/$nameroot.ahrd";
unlink $ahrd_outpath;

$ymlh->{proteins_fasta} = $cleaned_path;
$ymlh->{output} = $ahrd_outpath;

$yml_text = Dump($ymlh);
open F, ">working/ahrd.yml" or die "Can't create working/ahrd.yml";
print F $yml_text;
close F;

msgout("Running AHRD");
my $ahrd_cmd = "$java_path -Xmx2g -jar $ahrd_jar working/ahrd.yml";
system("$ahrd_cmd > working/ahrd.tmp 2>&1");

if (not -f $ahrd_outpath)
{
	die ("AHRD failed (no output file)!");	
}
my $final_outpath = "working/$nameroot.results.tbl";
my $nhits = create_final_output($final_outpath,$ahrd_outpath,\%blast_best_hits,\%blast_best_evals);

msgout("Result: $final_outpath\n$nhits of $nqueries queries had hits");


##############################################################################

sub check_clean_input_file
{
	my $path = shift;
	my $cleanpath = shift;
	if (not -f $path)
	{
		die ("Can't find input file $path");
	}
	# Verify the file is fasta, looks like protein, and has reasonable names

	# First load in all the sequences 
	my %seqs;
	my @names; # to preserve the order
	my $name = "";
	open F, $path or die "Can't open input file $path";
	while (my $line = <F>)
	{
		if ($line =~ />(\S+)/)
		{
			$name = $1;
			push @names, $name;
		}
		else
		{
			$line =~ s/\s+//g;
			$line =~ tr/a-z/A-Z/;
			$seqs{$name} .= $line;
		}
	}
	close F;
	my $nseqs = scalar keys %seqs;
	if ($nseqs == 0)
	{
		die ("No sequences found in input.fa! Please verify fasta format.");
	}
	my @bad_seqs;
	my $totallen = 0;
	my $total_changed_chars = 0;
	foreach my $name (@names)
	{
		my $seq = $seqs{$name};
		my $totalchars = length($seq);
		$totallen += $totalchars;
		my $test = $seq;
		$test =~ s/[AGCTN]//g;
		my $testchars = length($test);
		if ($testchars <= $totalchars/3)
		{
			# looks like nucleotides
			push @bad_seqs, $name;
		}
		$seq =~ s/[^ABCDEFGHIKLMNPQRSTUVWXYZ]/X/g;
		$seqs{$name} = $seq;
		$seq =~ s/[ABCDEFGHIKLMNPQRSTUVWXYZ]//g;
		my $changed_chars = length($seq);
		$total_changed_chars += $changed_chars;
	}
	my $num_bad = scalar(@bad_seqs);
	if ($num_bad > 0)
	{
		print join("\n", @bad_seqs);
		print "\nThe $num_bad sequences above do not look like protein sequences.\n";
		yesno("Continue?");
	}
	print "$nseqs sequences found, total length $totallen\n";
	if ($total_changed_chars > 0)
	{
		print "$total_changed_chars characters were changed to X\n";
	}
	yesno("Continue?");
	msgout("Begin annotation");

	print "Write cleaned sequences ($cleanpath)\n";
	open F, ">$cleanpath" or die "Can't create $cleanpath";
	foreach my $name (@names)
	{
		print F ">$name\n";
		for (my $i = 0; $i < length($seqs{$name}); $i += 50)
		{
			print F substr($seqs{$name},$i,50)."\n";
		}
	}
	close F;

	return $nseqs;
}

##############################################################################

sub yesno
{
	my $prompt = shift;
	print "$prompt (y/n)\n";
	my $choice = <STDIN>;
	chomp($choice);
	if ($choice ne "y")
	{
		print "Goodbye\n";
		exit(0);
	}
}

##############################################################################

sub check_file
{
	my $key = shift;
	my $path = shift;
	if (not -f $path)
	{
		die ("Can't find $key file $path");
	}
}

##############################################################################

sub check_blast_db
{
	my $path = shift;
	
	if (-f $path)
	{
		foreach my $ext ("phr","pin","psq")
		{
			my $check = "$path.$ext";
			if (not -f $check)
			{
				die ("Can't find blast db file:$check");
			}
		}
	}
	else
	{
		die("Can't find blast db file: $path");
	}	
}

##############################################################################

sub usage
{
	print <<END;

Usage: 
perl annot.pl <input fasta protein file>

Output: annotation table with extension .tbl

END
exit(0);
}

##############################################################################

sub check_args
{
	if (scalar(@ARGV) != 1)
	{
		usage();
	}
}

##############################################################################

sub check_yml
{
	my $ymlh = shift;
	my $pblast_dbs = shift;

	foreach my $key (keys %{$ymlh->{blast_dbs}})
	{
		my $pblast_section = $ymlh->{blast_dbs}->{$key};
		my $dbpath = $pblast_section->{database};
		check_blast_db($dbpath);
		$pblast_dbs->{$key} = $dbpath;
		foreach my $type ("blacklist","filter","token_blacklist")
		{
			if (defined $pblast_section->{$type})
			{
				my $fpath = $pblast_section->{$type};
				$fpath =~ s/\s*//g;
				if ($fpath ne "~" and $fpath ne "")
				{
					if (not -f $fpath)
					{
						die("Can't find AHRD $type file for blast $key");
					}
				}
			}
		}
	}
	
}

##############################################################################

sub msgout
{
	my $msg = shift;
	print "*************************\n";
	print "$msg\n";
}

##############################################################################

sub parse_blast
{
	my $path = shift;
	my $pbest = shift;
	my $pbestval = shift; 
	my $nhits = 0;
	open F, $path or die "Can't open blast output $path";
	while (my $line = <F>)
	{
		my @f = split /\s+/, $line;
		if (scalar(@f) == 12)
		{
			my $query = $f[0];
			my $targ = $f[1];
			my $eval = $f[10];
			$nhits++;
			if (not defined $pbest->{$query} or $eval < $pbestval->{$query})
			{
				$pbest->{$query} = $targ;
				$pbestval->{$query} = $eval;
			}
		}
		else
		{
			print "Bad line in blast output $path:\n$line";
		}
	}
	close F;

	return $nhits;
}

##############################################################################

sub create_final_output
{
	my $outpath = shift;
	my $ahrdpath = shift;
	my $pbest = shift;
	my $peval = shift;

	my %queries_hit;
	open G, ">$outpath" or die "Can't open final output file $outpath";
	open F, $ahrdpath or die "Can't open AHRD output: $ahrdpath";
	<F>; <F>;
	my $line = <F>;
	chomp($line); # b/c the next sub doesn't remove final newline for some reason
	$line =~ s/Interpro.*//;
	print G $line."Best-Blast\tBest-Eval\n";
	while ($line = <F>)
	{
		my @f = split /\t/, $line;
		my $query = $f[0];
		$queries_hit{$query} = 1;
		if (defined $pbest->{$query})
		{
			$f[4] = $pbest->{$query};
			$f[5] = $peval->{$query};
		}
		$line = join("\t",@f);
		print G "$line\n";
	}
	close F;
	close G;
	return scalar keys %queries_hit;
}

##############################################################################
#	AHRD Configuration file (Yaml format)
##############################################################################
#	Add/remove Blast database targets by editing the sections under "blast_dbs"
#	(Leave the "file:" fields blank as they are filled in with the blast output file)
##############################################################################

sub yml_text
{
	my $text = <<'END_TEXT';
proteins_fasta: 
output: 
token_score_bit_score_weight: 0.468
token_score_database_score_weight: 0.2098
token_score_overlap_score_weight: 0.3221
blast_dbs:
  refseq_soy:
    weight: 653
    description_score_bit_score_weight: 2.717061
    file: 
    fasta_header_regex: ^>(?<accession>\S+)\s+(?<description>[^\[]+)\[.*?$
    database: dbs/soy/Glyma.refseq_protein.fasta
    blacklist: dbs/soy_descline_blacklist.txt
    filter: dbs/empty.txt
    token_blacklist: dbs/blacklist_token.txt

  TAIR10:
    weight: 653
    description_score_bit_score_weight: 2.717061
    file: 
    fasta_header_regex: '^>(?<accession>\S+)\s*\|[^\|]+\|\s*(?<description>[^\|]+)\s*\|.*$'
    database: dbs/arab/TAIR10_pep_20101209
    blacklist: dbs/empty.txt
    filter: dbs/empty.txt
    token_blacklist: dbs/blacklist_token.txt

  Mt40v1:
    weight: 854
    description_score_bit_score_weight: 2.917405
    file:
    database: dbs/medicago/Mt4.0v1_GenesProteinSeq_20130731_1800.fasta
    fasta_header_regex: '^>(?<accession>\S+)\s*\|\s*(?<description>[^\|]+)\s*\|.*$'
    blacklist: dbs/med_descline_blacklist.txt
    filter: dbs/empty.txt
    token_blacklist: dbs/blacklist_token.txt
END_TEXT
	return $text;
}


