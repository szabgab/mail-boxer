use strict;
use warnings;
use 5.010;

use MongoDB;

my $client     = MongoDB::MongoClient->new(host => 'localhost', port => 27017);
my $database   = $client->get_database( 'mboxer' );
my $collection = $database->get_collection( 'messages' );

print "mail-boxer> ";
my $term = <STDIN>;
chomp $term;

my $res= $collection->find({ From => { address => $term } });


