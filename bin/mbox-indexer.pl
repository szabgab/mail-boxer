use strict;
use warnings;
use 5.010;

use Moo;
use MooX::Options;

use Path::Iterator::Rule;
use Email::Folder;
use Email::Address;
use MongoDB;
use Data::Dumper qw(Dumper);
use Log::Log4perl;

option path    => (is => 'ro', required => 1, format => 's',
	doc => 'path/to/mail');

option limit   => (is => 'ro', required => 0, format => 'i',
	doc => 'limit number of messages to be processed');

Log::Log4perl->init("log.conf");

main->new_with_options->process();
exit;

sub process {
	my ($self) = @_;

	my $dir = $self->path;

	my $log = Log::Log4perl->get_logger('process');
	$log->info("Starting to process in '$dir'");

	my $client     = MongoDB::MongoClient->new(host => 'localhost', port => 27017);
	my $database   = $client->get_database( 'mboxer' );
	$database->drop;
	my $collection = $database->get_collection( 'messages' );
	
	my $count = 0;
	
	my $rule = Path::Iterator::Rule->new;
	my $it = $rule->iter( $dir );
	while ( my $file = $it->() ) {
		next if not -f $file;
		$log->info("Processing $file");
		my $folder = Email::Folder->new($file);
		while (my $msg = $folder->next_message) {  # Email::Simple objects
			$count++;
			#say $msg->header;
			# Use of uninitialized value $field in lc at .../5.18.1/Email/Simple/Header.pm line 123, <GEN0> line 14.
			#say $msg->header('From');
			my %doc;
	
			add_from(\%doc, $msg) or next;
			add_to(\%doc, $msg);
	
			#file => $file,
			$doc{Subject} = $msg->header('Subject'),
			$collection->insert(\%doc);
			exit if defined $self->limit and $count > $self->limit;
		}
		#last;
		#exit;
	}
	$log->info("Count: $count");
}

sub add_to {
	my ($doc, $msg) = @_;

	my $log = Log::Log4perl->get_logger('add_to');
	my $to_string = $msg->header('To');
	if (not defined $to_string) {
		$log->warn("There is no To field in this message");
		return;
	}
	$log->info("To: $to_string");

	my @to = Email::Address->parse($to_string);
	if (not @to) {
		$log->warn("Very strange. No email recognized in the To field! " . $msg->header('To'));
		return;
	}

	$log->info('name: ' . $to[0]->name);
	$log->info('phrase: ' . ($to[0]->phrase // ''));
	$log->info('address: ' . $to[0]->address);

	foreach my $t (@to) {
		my %h = (address => lc $t->address);
		if (defined $t->phrase and $t->phrase ne $t->address) {
			$h{name} = $t->phrase;
		}
		push @{ $doc->{To} }, \%h;
	}

	return;
}

sub add_from {
	my ($doc, $msg) = @_;

	my $log = Log::Log4perl->get_logger('add_from');

	my $from_string = $msg->header('From');
	#$log->info("From: $from_string");
	if (not defined $from_string) {
		$log->warn("There is no From field in this message");
		return 1;
	}
	my @from = Email::Address->parse($from_string);
	#$log->info(Dumper \@from);
	if (@from > 1) {
		$log->warn("Strange, there were more than one emails recognized in the From field: " . $msg->header('From'));
	}
	if (not @from) {
		$log->warn("Very strange. No email in the From field! " . $msg->header('From'));
		return 1;
	}
	#say Dumper \@from;
	#say $from[0]->address;
	#say $from[0]->name;
	if ($from[0]->name eq 'Mail System Internal Data') {
		return;
	}

	$doc->{From} = {
		address => lc $from[0]->address,
	};

	if (defined $from[0]->phrase and $from[0]->phrase ne $from[0]->address) {
		$doc->{From}{name} = $from[0]->phrase;
	}

	return 1;
}


