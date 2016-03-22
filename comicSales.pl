#!/usr/bin/perl

#Read the README
use strict;
use warnings;
use HTML::TreeBuilder;
use feature qw(say);

#hard coded for now
my $file_in = "2016-02.html";
#will store the information for each issue
my @issue_info; 

my $tree = HTML::TreeBuilder -> new();
$tree -> parse_file($file_in);

my @tables = $tree -> look_down("_tag" => "table");
#the second table tag has the relevant information
my @rows = $tables[1] -> look_down("_tag" => "tr");

my $total_sales = 0;
my $avg = 0;

for my $i (1..$#rows) {
	#stop parsing at empty string
	if (length $rows[$i] -> as_trimmed_text() == 0) {
		last;
	}
	my @cells = $rows[$i] -> content_list();
	my $info = "";
	for (my $i = 0; $i < scalar @cells - 1; $i++) {
		$info .= "|".$cells[$i] -> as_trimmed_text()."|";
	}
	#remove comma from sales number
	my $sales = $cells[$#cells] -> as_trimmed_text();
	$sales =~ s/,//;
	$total_sales += $sales;
	$info .= "|".$sales."|";
	push @issue_info, $info;
}

foreach my $iss (@issue_info) {
	say $iss;
}
say sprintf("The total sales for %d issues is %d.", scalar @issue_info, $total_sales);
say sprintf("The average sales is %f.", calcAvg($total_sales, scalar @issue_info));
$tree = $tree -> delete();

sub calcAvg {
	my ($total, $num_items) = @_;
	return $total / $num_items;
}
