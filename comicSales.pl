#!/usr/bin/perl

#Read the README
use strict;
use warnings;
use HTML::TreeBuilder;
use feature qw(say);
use List::Util qw(max min);
use ComicIssue;

#hard coded for now
my $file_in = "test.html";
#will store the information for each issue
my @issue_list; 

my $tree = HTML::TreeBuilder -> new();
$tree -> parse_file($file_in);

my @tables = $tree -> look_down("_tag" => "table");
#the second table tag has the relevant information
my @rows = $tables[1] -> look_down("_tag" => "tr");

for my $i (1..$#rows) {
	#stop parsing at empty string
	if (length $rows[$i] -> as_trimmed_text() == 0) {
		last;
	}
	my @cells = $rows[$i] -> content_list();
	#remove dollar sign from price
	my $price = $cells[3] -> as_trimmed_text();
	$price =~ s/\$//;
	#remove comma from sales number
	my $sales = $cells[5] -> as_trimmed_text();
	$sales =~ s/,//g;
	my $issue = ComicIssue -> new(rank => $cells[0] -> as_trimmed_text() , name => $cells[1] -> as_trimmed_text(), 
								number => $cells[2] -> as_trimmed_text(), price => $price, 
								publisher => $cells[4] -> as_trimmed_text(), sales => $sales);
	push @issue_list, $issue;
}

foreach my $issue (@issue_list) {
	say $issue -> toString();
}
say sprintf("The total sales for %d issues is %d.", scalar @issue_list, calcTotalSales(\@issue_list));
say sprintf("The average number of sales is %d.", calcAvgSales(\@issue_list));
say sprintf("The median number of sales is %d.", calcMedianSales(\@issue_list));
say sprintf("The greatest number of sales was %d, while the lowest number was %d.", calcMaxSales(\@issue_list), calcMinSales(\@issue_list));

$tree = $tree -> delete();

#
# Subroutines for stat calculations
#
sub calcTotalSales {
	my $total = 0;
	my ($list) = shift;
	foreach my $issue (@$list) {
		$total += $issue -> sales;
	}
	return $total;
}

sub calcAvgSales {
	my ($list) = shift;
	return calcTotalSales($list) / scalar @$list;
}

sub calcMedianSales {
	my ($list) = shift;
	if (scalar @$list % 2 == 0) {
		return ($list -> [scalar @$list / 2 - 1] -> sales + $list -> [scalar @$list / 2] -> sales) / 2;
	} else {
		return $list -> [int(scalar @$list / 2)] -> sales;
	}
}

sub calcMaxSales {
	my ($list) = shift;
	my @sorted = sort sort_Sales @$list;
	my $max = pop @sorted;
	return $max -> sales;
}

sub calcMinSales {
	my ($list) = shift;
	my @sorted = sort sort_Sales @$list;
	my $min = shift @sorted;
	return $min -> sales;
}

#
# Subroutines for sorting
# Sorting is done in ascending order
# In order to get descending, use reverse
#
sub sort_Name{
	return -1 if $a -> name lt $b -> name;
	return 0 if $a -> name eq $b -> name;
	return 1 if $a -> name gt $b -> name;
}

sub sort_Sales {
	return -1 if $a -> sales < $b -> sales;
	return 0 if $a -> sales == $b -> sales;
	return 1 if $a -> sales > $b -> sales;
}
