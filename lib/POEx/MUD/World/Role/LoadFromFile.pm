package POEx::MUD::World::Role::LoadFromFile;
use 5.12.1;
use Carp;

use Moo::Role;

use POEx::MUD::ReadWrite;

use namespace::clean;

requires 'validate_loaded_file';

sub from_file {
  my ($class, %params) = @_;
  $class = blessed $class ? blessed $class : $class;

  my $path;
  confess "from_file() requires a file parameter"
    unless $path = $params{file};

  my $loaded = POEx::MUD::ReadWrite->new('YAML')->thaw_file($path);
  $const_params = $self->validate_loaded_file($loaded, \%params);

  $class->new(%$const_params)
}

1;
