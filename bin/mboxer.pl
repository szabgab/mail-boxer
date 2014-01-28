use strict;
use warnings;
use 5.010;

use Path::Iterator::Rule;
use Email::Folder;
#use MongoDB;
use Data::Dumper qw(Dumper);

my $path_to_dir = shift or die "Usage: $0 path/to/mail\n";

#my $client     = MongoDB::MongoClient->new(host => 'localhost', port => 27017);
#my $database   = $client->get_database( 'mboxer');
#my $collection = $database->get_collection( 'messages' );
#

my $count = 0;

my $rule = Path::Iterator::Rule->new;
my $it = $rule->iter( $path_to_dir );
while ( my $file = $it->() ) {
	next if not -f $file;
	say $file;
	my $folder = Email::Folder->new($file);
	while (my $msg = $folder->next_message) {  # Email::Simple objects
		$count++;
		#say $msg->header;
		# Use of uninitialized value $field in lc at .../5.18.1/Email/Simple/Header.pm line 123, <GEN0> line 14.
		#say $msg->header('From');
		#Email::Address->parse($line);
		foreach my $h ($msg->headers) {
			$main::count{$h}++;
		}
		#exit if $count > 20;
		#exit if $main::cnt++ > 40;
	}
	last;
	#exit;
}
say $count;
foreach my $k (sort keys %main::count) {
	say "$k  $main::count{$k}";
}
#print Dumper \%main::count;



