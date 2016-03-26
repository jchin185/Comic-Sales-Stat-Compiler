#!/usr/bin/perl

#Read the README
use strict;
use warnings;
use HTML::TreeBuilder;
use feature qw(say);
use List::Util qw(max min);
use Getopt::Long;
use ComicIssue;

#date flag
my $input_url = "";
#file flag
my $input_file = "";
#publisher to search for
my $publisher_name = "";
#help flag
my $help = "";

#how many issues to display, default 10
my $max_limit = 10;

#replace with Pod::Usuage
my $help_string = "Usuage: perl comicSales.pl [switches] [arguments]
-d or --date		specify a month and year in mm/yyyy to get information from
-f or --file		specify a html file to get information from
-l or --limit		specify a limit of how many issues to show only, 
					default 10, use none to show all
					does not affect actual number of issues in list, use instead --hardlimit
-p or --publisher	specify to look for a specific publisher, case insensitive
-h or --help		this help menu";

GetOptions("d|date=s" => \$input_url, "f|file=s" => \$input_file, "p|publisher=s" => \$publisher_name,
			"l|limit=s" => \&handle_limit, "h|help|?" => \$help);

#help takes precedence
if ($help) {
	say $help_string;
	exit(0);
}

if ($input_url and $input_file) {
	say "You are only allowed to specify either a date or an input html file.";
	say $help_string;
	exit(2);
} elsif (!$input_url and !$input_file) {
	say "You must specify either a date or an input html file.";
	say $help_string;
	exit(2);
}

my $tree;
my $url = "http://www.comichron.com/monthlycomicssales/";

#must match mm/yyyy format
if ($input_url) {
	if ($input_url =~ m/(\d{2})\/(\d{4})/) {
		#url is in the form yyyy/yyyy-mm.html
		$tree = HTML::TreeBuilder -> new_from_url($url.$2."/".$2."-".$1.".html");
	} else {
		say $help_string;
		exit(2);
	}
} 

if ($input_file) {
	$tree = HTML::TreeBuilder -> new_from_file($input_file);
}

#will store the information for each issue
my @issue_list; 

my @tables = $tree -> look_down("_tag" => "table");
#the second table tag has the relevant information
my @rows = $tables[1] -> look_down("_tag" => "tr");

for my $i (1..$#rows) {
	#stop parsing at empty string
	if (length $rows[$i] -> as_trimmed_text() == 0) {
		last;
	}
	my @cells = $rows[$i] -> content_list();
	my ($rank, $name, $number, $price, $publisher, $sales, $issue);
	$rank = $cells[0] -> as_trimmed_text();
	#stop parsing if there is no rank
	#indicates that there is a special note
	#eg 04/1997
	if ($rank !~ m/\d+/) {
		last;
	}
	#there isn't any special formatting for the issue name
	$name = $cells[1] -> as_trimmed_text();
	#may be missing issue number field in html, means there is only 5 fields, not 6
	if (scalar @cells == 5) {
		#remove dollar sign from price
		$price = $cells[2] -> as_trimmed_text();
		$price =~ s/\$//;
		#check p flag
		$publisher = $cells[3] -> as_trimmed_text();
		if ($publisher_name and lc($publisher) ne lc($publisher_name)) {
			next;
		}
		#remove comma from sales number
		$sales = $cells[4] -> as_trimmed_text();
		$sales =~ s/,//g;
		$issue = ComicIssue -> new(rank => $rank , name => $name, price => $price, 
									publisher => $publisher, sales => $sales);
	} elsif (scalar @cells == 6) {
		#html may have 6 fields, but issue number is empty
		#give default value 1
		$number = $cells[2] -> as_trimmed_text();
		if ($number eq "") {
			$number = 1;
		}
		#remove * from issue number
		$number =~ s/\*//;
		#remove any non numbers from issue number
		#eg in '2 2nd Ptg' remove the 2nd Ptg
		if ($number =~ m/\b(\d+(\.\d{2,})?)\b.+/) {
			$number = $1;
		}
		$publisher = $cells[4] -> as_trimmed_text();
		if ($publisher_name and lc($publisher) ne lc($publisher_name)) {
			next;
		}
		#remove dollar sign from price
		$price = $cells[3] -> as_trimmed_text();
		$price =~ s/\$//;
		#remove comma from sales number
		$sales = $cells[5] -> as_trimmed_text();
		$sales =~ s/,//g;
		$issue = ComicIssue -> new(rank => $rank , name => $name, number => $number, 
									price => $price, publisher => $publisher, sales => $sales);
	}
	push @issue_list, $issue;
}

for my $i (0..$max_limit - 1) {
	if(defined $issue_list[$i]) {
		say $issue_list[$i] -> toString();
	} else {
		last;
	}
}

say sprintf("The total sales for %d issues is %d.", scalar @issue_list, calcTotalSales(\@issue_list));
say sprintf("The average number of sales is %d.", calcAvgSales(\@issue_list));
say sprintf("The median number of sales is %d.", calcMedianSales(\@issue_list));
say sprintf("The greatest number of sales was %d, while the lowest number was %d.", calcMaxSales(\@issue_list), calcMinSales(\@issue_list));

$tree = $tree -> delete();

#
# Subroutines for dealing with getopt arguments
#
sub handle_limit {
	my ($opt_name, $opt_value) = @_;
	if ($opt_value =~ m/\d+/) {
		if ($opt_value > 0) {
			$max_limit = $opt_value;
		} 
	} elsif ($opt_value eq "none") {
		$max_limit = 1000;
	} else {
		$max_limit = 10;
	}
}

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
	my @sorted = sort(sort_Sales @$list);
	if (scalar @sorted % 2 == 0) {
		return ($sorted[scalar @sorted / 2 - 1] -> sales + $sorted[scalar @sorted / 2] -> sales) / 2;
	} else {
		return $sorted[int(scalar @sorted / 2)] -> sales;
	}
}

sub calcMaxSales {
	my ($list) = shift;
	my @sorted = sort(sort_Sales @$list);
	my $max = pop @sorted;
	return $max -> sales;
}

sub calcMinSales {
	my ($list) = shift;
	my @sorted = sort(sort_Sales @$list);
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
