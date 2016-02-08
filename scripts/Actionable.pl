#!/usr/bin/perl
use strict;
use warnings;

if($ARGV[0] eq 'somatic'){
	Somatic($ARGV[1], $ARGV[2]);
	# 1 == Annotations
	# 2 == somaticFile
}
elsif($ARGV[0] eq 'germline'){
	Germline($ARGV[1], $ARGV[2], $ARGV[3], $ARGV[4]);
	# 1 == somaticFile
	# 2 == germlineFil
	# 3 == Annotations
	# 4 == CancerGene List [reference]
}
elsif($ARGV[0] eq 'rnaseq'){
#	Rnaseq($ARGV[1], $ARGV[2])
}

sub Germline{
	# First remove anything somatic
	my ($somatic, $germline, $annotation, $cancerGeneList) = (@_);

	unless (open(ANN_FH, "$somatic")){
		print STDERR "Can not open file $somatic\n";
		exit;
	}
	# Somatic file to hash
	my %DATA;
	while(<ANN_FH>){
		chomp;
		my @local = split ("\t", $_);
		my $key = join "\t", @local[0..4];
		$DATA{"$key"} = "somatic";
	}
	close ANN_FH;
	# Annotations to hash
	unless (open(REF, "$annotation")){
		print STDERR "Can not open file $annotation\n";
		exit;
	}
	my %ANNOTATION;
	while(<REF>){
		chomp;
		my @local = split ("\t", $_);
		my $key = join "\t", @local[0..4];
		my $end = @local - 1 ;
		my $value = join "\t", @local[5..$end];
		$ANNOTATION{$key} =$value;
	}
	close REF;
	# CancerGeneList to hash
	unless (open(REF, "$cancerGeneList")){
		print STDERR "Can not open file $cancerGeneList\n";
		exit;
	}
	my %CANCER_GENE;
	while(<REF>){
		chomp;
		my @local = split ("\t", $_);
		$CANCER_GENE{$local[0]} ='yes';
	}
	close REF;
	# Germline mutation to work on.
	unless (open (ORI,"$germline")){
		print STDERR "Can not open file $germline\n";
		exit;
	}
	my $head =`grep -m1 -P "^Chr\tStart\tEnd\tRef\tAlt\t" $annotation |sort |uniq`;
	chomp($head);
	print "$head\tSample\tCaller\tQUAL\tFS\tTotalReads\tAltReads\tVAF\tSource\n";
	while (<ORI>){
		chomp;
		my @temp = split("\t", $_);
		my $vcf;
		my $end = @temp - 1 ;
		my $site_sample = "$temp[0]\t$temp[1]\t$temp[2]\t$temp[3]\t$temp[4]\t$temp[5]";
		my $site = "$temp[0]\t$temp[1]\t$temp[2]\t$temp[3]\t$temp[4]";
		$vcf = join "\t", @temp[5..$end];
		if (!exists $DATA{$site}){ # i.e. position is germline!!
		#if (!exists $DATA{$site_sample}){ # i.e. position in sample is germline
			my $source = findSource($ANNOTATION{"$site"});
			my @ANN = split("\t", $ANNOTATION{"$site"});
			if($source =~ /[ACMG-clinvar|hgmd|CancerGene]/){
				my $vaf = VAF($temp[9], $temp[10]);
				if($source =~ /^CancerGene$/ and (exists $CANCER_GENE{$ANN[1]})){
					print "$temp[0]\t$temp[1]\t$temp[2]\t$temp[3]\t$temp[4]\t$ANNOTATION{$site}\t$vcf\t$vaf\t$source\n";
				}
				else{
					print "$temp[0]\t$temp[1]\t$temp[2]\t$temp[3]\t$temp[4]\t$ANNOTATION{$site}\t$vcf\t$vaf\t$source\n";
				}
			}
		}
	}
	close ORI;
}
sub findSource{
	my ($input)= (@_);
	my %source;
	my @ANN = split("\t", $input);
	if($ANN[60] =~ /CLINSIG=(.*pathogenic.*);CLNDBN=/ and $ANN[1] eq $ANN[146]){    # Clinvar
		if ($1 =~ /^pathogenic/ or $1 =~ /\|pathogenic/ or $1 =~ /^probable-pathogenic/ or $1 =~ /\|probable-pathogenic/){
			$source{'ACMG-clinvar'} = 'yes';
		}
	}
	if($ANN[63] =~ /^Disease causing mutation$/){  # HGMD
		$source{'hgmd'} = 'yes';	
	}
	if($ANN[3] =~ /stop/ or $ANN[3] =~ /frameshift/ or $ANN[3] =~ /nonsynonymous/){
		$source{'CancerGene'} = 'yes';
	}
	my $return = join(";", (sort keys %source));
	return($return);
}
sub Somatic{
#/data/Clinomics/Ref/annovar/hg19_SomaticActionableSites.txt NCI0276/NCI0276/db/NCI0276.somatic
	my ($ref, $subject) = (@_);
	unless (open(ANN_FH, "$ref")){
		print STDERR "\n\nCan not open $ref\n"; 
		exit;
	}
	my %DATA;
	while(<ANN_FH>){
		chomp;
		my @local = split ("\t", $_);
		my $key = join "\t", @local[0..2];
		my $end = @local - 1 ;
		my $value = join "\t", @local[3..$end];
		$DATA{"$key"} = $value;
	}
	close ANN_FH;
	unless (open (ORI,"$subject")){
		print STDERR "\n\nCan not open $subject\n"; 
		exit;
	}
	print "Chr\tStart\tEnd\tRef\tAlt\tSample\tCaller\tQUAL\tFS\tTotalReads\tAltReads\tVAF\tSource\n";
	while (<ORI>){
		chomp;
		my @temp = split("\t", $_);
		my $val;
		my $vcf;	
		my $end = @temp - 1 ;
		my $vaf = VAF($temp[9], $temp[10]);
		$val = "$temp[0]\t$temp[1]\t$temp[2]";
		$vcf = join "\t", @temp[3..$end];
		if (exists $DATA{$val}){
			print "$val\t$vcf\t$vaf\t$DATA{$val}\n";
		}
	}
	close ORI;
}

sub VAF{
	my ($total, $var) = (@_);
	my $vaf =0;
	if($var =~ /,/ or $total =~ /\./ or $total =~ /NA/){ 
		return($vaf);
	}
	elsif($total == 0){
		return($vaf);
	}
	else{
		$vaf = sprintf("%0.2f", $var/$total);
		return($vaf);
	}

}
