#!/usr/bin/perl

#Read the README
#use strict;
#use warnings;
use HTML::TreeBuilder;

#hard coded for now
my $file_in = "2016-02.html";
#start of volume sales info
my $vol_start = "Trade Paperback titlePricePublisherEst. sales";
#will store the information for each issue
my @issue_info; 

my $tree = HTML::TreeBuilder -> new();
$tree -> parse_file($file_in);

my @tables = $tree -> look_down("_tag" => "table");

#the second table tag has the relevant information
my @rows = $tables[1] -> look_down("_tag" => "tr");

foreach my $tablerow_elem (@rows) {
	#stop parsing at empty string
	if (length $tablerow_elem -> as_trimmed_text() == 0) {
		last;
	}

	#may not be needed
	#pattern is RANK TITLE ISSUE PRICE PUBLISHER SALES
	#/(\d+)(.+)(\d)(\$\d+\.\d{2})(\w*?)((\d{3},\d{3})|(\d{1,3}))/
	
	my @cells = $tablerow_elem -> content_list();

	#there may be no issue number, meaning one less field
	if (not defined $cells[5]) {
		push @issue_info, join "||", ($cells[0] -> as_trimmed_text() , $cells[1] -> as_trimmed_text()
										, $cells[2] -> as_trimmed_text() , $cells[3] -> as_trimmed_text()
										, $cells[4] -> as_trimmed_text());
	} else {
		push @issue_info, join "||", ($cells[0] -> as_trimmed_text() , $cells[1] -> as_trimmed_text()
										, $cells[2] -> as_trimmed_text() , $cells[3] -> as_trimmed_text()
										, $cells[4] -> as_trimmed_text(), $cells[5] -> as_trimmed_text());
	}
}

foreach my $iss (@issue_info) {
		print $iss, "\n";
	}

$tree = $tree -> delete;
