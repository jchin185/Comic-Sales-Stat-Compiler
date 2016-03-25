package ComicIssue;

use Moose;

has "rank" => (is => "rw", isa => "Num");
has "name" => (is => "rw", isa => "Str");
has "number" => (is => "rw", isa => "Num");
has "price" => (is => "rw", isa => "Num");
has "publisher" => (is => "rw", isa => "Str");
has "sales" => (is => "rw", isa => "Num");

sub toString {
	my $self = shift;
	return join(", ", $self -> rank, $self -> name, $self -> number,
		$self -> price, $self -> publisher, $self -> sales);
}
1;