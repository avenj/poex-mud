package POEx::MUD::ReadWrite::Interface;
use Carp 'confess';

use Role::Tiny;

requires qw/
  freeze
  thaw
/;

## These are optional, but die if called and not overriden
sub freeze_to_file {
  confess "freeze_to_file() not implemented"
}

sub thaw_file {
  confess "thaw_file() not implemented"
}

1;
