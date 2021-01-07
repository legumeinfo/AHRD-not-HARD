#! /usr/bin/env perl
use strict;
use warnings;

use XML::Simple;
use Data::Dumper;
use Getopt::Std;

=head1 NAME

clean_iprscanXMLtoGff.pl

=head1 DESCRIPTION

parameters

=item -i

input interproscan GFF

=item -x

input interproscan XML

=item -o

outfile GFF


=head1 SYNOPSIS

Useful Resuources
To parse XML - http://interoperating.info/courses/perl4data/node/26
This script takes iprscan result XML and GFF files as input and parses and cleans it to give final GFF output ready to load in chado

Date: 06-02-2015
Author: Pooja Umale, Andrew Farmer
Contact: peu@ncgr.org, adf@ncgr.org

=cut

our ($opt_i, $opt_x);
getopts('i:x:s');
my $input_gff = $opt_i;
my $input_xml = $opt_x;

if (!$input_gff){ die "Need -i input_gff argument.\n"; }    
if (!$input_xml){ die "Need -x input_xml argument.\n"; }

    
my @protein_ids = ();
my %xml_hash;
 
my $proteinlist = XMLin($input_xml, KeyAttr => { xref => 'id'}, ForceArray => ['xref']);


foreach my $ele(@{$proteinlist->{protein}}) 
{
      
    foreach my $match_type (keys %{ $ele->{matches}}) 
	{
             my @matches;
             if (ref($ele->{matches}->{$match_type}) eq 'ARRAY') 
              {
              @matches = @{ $ele->{matches}->{$match_type}};
              }
              else {
               @matches = ($ele->{matches}->{$match_type});
              }
           foreach my $match (@matches) 
	     {
                 my @location_types = keys %{$match->{locations}};
                 push (my @signatures, $match->{signature});	   		
                 
		my @locations; 
		 foreach my $location_type (@location_types) 
		   {
                    if (ref($match->{locations}->{$location_type}) eq 'ARRAY') {
                        @locations = @{$match->{locations}->{$location_type}};
                    }
                    else {
                        @locations = ($match->{locations}->{$location_type});
                    }
                   
		   }   
            foreach my $sign (@signatures)
		{
 	              
			foreach my $location (@locations) 
                    {
				my $lib_value = ${$sign}{'signature-library-release'};  #dereferencing hash-ref of key 'signature-library-release'
				my $lin = $lib_value->{"library"};
		      
			    if (defined $location->{"hmm-start"}) 
		            {
        my @ids = ($ele->{xref});
	my @keys;
	foreach my $i (@ids)
	{
          @keys = keys % { $i };
	}

	foreach my $id(@keys)
	{
       	my $l_start = $location->{"start"};
	my $l_end = $location->{"end"};
	my $l_name = $sign->{"ac"};
        my $key_id = "$id.$lin.$l_start.$l_end.$l_name";
        my $hmm_s = $location->{"hmm-start"};
	my $hmm_e = $location->{"hmm-end"};
	my $value_id = "$hmm_s	$hmm_e";
	 $xml_hash{$key_id} = $value_id;
	}


	
}		    
			}
                
		}

	  }
          
     } 
  }


open FILE, "<$input_gff" or die $!;

while( my $line = <FILE>)
 {
        chomp($line);
        if ($line =~ m/^>/g) { last; } 
	if ($line =~ m/##feature-ontology/g) { next; }
	if ($line =~ m/^\s*#/) { print "$line\n"; next; }
	my @split = split("\t", $line);
        next if $split[2] eq "polypeptide";
        my @newarr  = split(";", $split[8]);

	my $n_name = $newarr[0];
        $n_name =~ s/Name=//g;

        my $source = $split[1]; 
        my $src = uc($source);
        my $key_line = "$split[0].$src.$split[3].$split[4].$n_name";
        my $value_line = $line;

	if (exists $xml_hash{$key_line})
	{
		my @hmm_cords = ();
		my $h = $xml_hash{$key_line};
		@hmm_cords = split("\t", $h);
		my $hmm_start = $hmm_cords[0];
		my $hmm_end = $hmm_cords[1];
		my $tar;
		my $new;
		my $hmm_type = "protein_hmm_match";
	
		
		foreach my $n(@newarr){
		  if ($n =~ m/Target=.*/g)
            	{
                my $orig_target = $n;
		my $new_target_hmm = "Target=$n_name $hmm_start $hmm_end";
		$tar = $split[8];
		$tar =~ s/$orig_target/$new_target_hmm/g;
		$tar =~ s/"//g; 
		}
    	             
	    	} 
		print "$split[0]\t$split[1]\t$hmm_type\t$split[3]\t$split[4]\t$split[5]\t$split[6]\t$split[7]\t$tar\n";
			
		}
		else{

		my $tar2;
		
			foreach my $n(@newarr){
                  if ($n =~ m/Target=.*/g)
                {
                $tar2 = $split[8];
                $tar2 =~ s/$n;//g;
                $tar2 =~ s/"//g; 
		}
		
                }
		
			
			print  "$split[0]\t$split[1]\t$split[2]\t$split[3]\t$split[4]\t$split[5]\t$split[6]\t$split[7]\t$tar2\n";
	   	 }
                      	 
	}

close FILE;
