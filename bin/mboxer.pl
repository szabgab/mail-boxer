use strict;
use warnings;
use 5.010;

use Path::Tiny qw(path);
use Path::Iterator::Rule;
use Email::Folder;

my $path_to_dir = shift or die "Usage: $0 path/to/mail\n";

my $rule = Path::Iterator::Rule->new;
my $it = $rule->iter( $path_to_dir );
while ( my $file = $it->() ) {
	next if not -f $file;
    say $file;
	my $folder = Email::Folder->new($file);
	while (my $msg = $folder->next_message) {  # Email::Simple objects
		#say $msg->header;
		# Use of uninitialized value $field in lc at .../5.18.1/Email/Simple/Header.pm line 123, <GEN0> line 14.
		say $msg->header('From');
		exit;
	}
	exit;
}



