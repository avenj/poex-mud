package POEx::MUD::ReadWrite;
use 5.12.1;

use Carp 'confess';

use Module::Runtime 'use_module';

sub new {
  my ($class, $type) = splice @_, 0, 2;
  $type ||= 'YAML';
  my $real = 'POEx::MUD::ReadWrite::'.$type;
  use_module($real)->new(@_)
}

## Subclasses should provide these:
sub freeze {
  confess "freeze() not implemented"
}

sub freeze_to_file {
  confess "freeze_to_file() not implemented"
}

sub thaw {
  confess "thaw() not implemented"
}

sub thaw_file {
  confess "thaw_file() not implemented"
}


1;
