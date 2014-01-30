use strict;
use warnings;
use 5.010;

use MongoDB;
use Data::Dumper qw(Dumper);

my $client     = MongoDB::MongoClient->new(host => 'localhost', port => 27017);
my $database   = $client->get_database( 'mboxer' );
my $collection = $database->get_collection( 'messages' );

print "mail-boxer> ";
my $term = <STDIN>;
chomp $term;

my $messages = $collection->find({ 'From.address' => qr/$term/ } );
while (my $m = $messages->next) {
	say '';
	say $m->{From}{name};
	say $m->{From}{address};
	say $m->{Subject};
	say Dumper $m;
}


