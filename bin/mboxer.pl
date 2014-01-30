use strict;
use warnings;
use 5.010;

use Path::Iterator::Rule;
use Email::Folder;
use Email::Address;
use MongoDB;
use Data::Dumper qw(Dumper);

my $path_to_dir = shift or die "Usage: $0 path/to/mail\n";

my $client     = MongoDB::MongoClient->new(host => 'localhost', port => 27017);
my $database   = $client->get_database( 'mboxer' );
$database->drop;
my $collection = $database->get_collection( 'messages' );



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
		my $from_string = $msg->header('From');
        if (not defined $from_string) {
			warn "There is no From field in this message";
			next;
		}
		my @from = Email::Address->parse($from_string);
		if (@from > 1) {
			warn "Strange, there were more than one emails recognized in the From field: " . $msg->header('From');
		}
		if (not @from) {
			warn "Very strange. No email in the From field! " . $msg->header('From');
			next;
		}
		#say Dumper \@from;
		say $from[0]->address;
		say $from[0]->name;
		if ($from[0]->name eq 'Mail System Internal Data') {
			next;
		}
		#exit;
		my %doc = (
			#file => $file,
			From => {
				name => $from[0]->name,
				address => $from[0]->address,
			},
			Subject => $msg->header('Subject'),
		);
		$collection->insert(\%doc);
		exit if $count > 20;
	}
	#last;
	#exit;
}
say $count;



