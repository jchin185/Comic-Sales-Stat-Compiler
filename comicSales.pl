#!/usr/bin/perl

#Read the README
use strict;
use warnings;
use HTML::TreeBuilder;
use feature qw(say);

#hard coded for now
my $file_in = "test.html";
#will store the information for each issue
my @issue_info; 

my $tree = HTML::TreeBuilder -> new();
$tree -> parse_file($file_in);

my @tables = $tree -> look_down("_tag" => "table");
#the second table tag has the relevant information
my @rows = $tables[1] -> look_down("_tag" => "tr");

my $total_sales = 0;
my $avg = 0;

foreach my $tablerow_elem (@rows) {
	#stop parsing at empty string
	if (length $tablerow_elem -> as_trimmed_text() == 0) {
		last;
	}

	#may not be needed
	#pattern is RANK TITLE ISSUE PRICE PUBLISHER SALES
	#/(\d+)(.+)(\d)(\$\d+\.\d{2})(\w*?)((\d{3},\d{3})|(\d{1,3}))/
	
	my @cells = $tablerow_elem -> content_list();
	my $num_cells = $tablerow_elem -> content_list();
	
	my $info = "";
	for (my $i = 0; $i < $num_cells - 1; $i++) {
		$info .= "|".$cells[$i] -> as_trimmed_text()."|";
	}
	my $sales = $cells[$#cells] -> as_trimmed_text();
	if ($sales =~ s/,//) {
		$total_sales += $sales;
	}
	$info .= "|".$sales."|";
	push @issue_info, $info;
}

#first entry is header
shift @issue_info;

foreach my $iss (@issue_info) {
		say $iss;
}
say "Average sales is ", calcAvg($total_sales, scalar @issue_info);
$tree = $tree -> delete();

sub calcAvg {
	my ($total, $num_items) = @_;
	return $total / $num_items;
}
