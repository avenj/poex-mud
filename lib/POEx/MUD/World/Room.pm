package POEx::MUD::World::Room;
use 5.10.1;
use strictures 1;

use Carp;
use Moo;

use Scalar::Util 'blessed';

use overload
  'bool'   => sub { 1 },
  '""'     => 'id',
  fallback => 1;

## A Room belongs to a Map.

use namespace::clean;


has adjoining => (
  ## HashRef: $direction -> $room_id
  lazy      => 1,
  is        => 'ro',
  isa       => HashRef,
  writer    => 'set_adjoining',
  predicate => 'has_adjoining',
);

has description => (
  ## Array of strings describing this room.
  required  => 1,
  is        => 'ro',
  isa       => ArrayRef,
  writer    => 'set_description',
  predicate => 'has_description',
);

has id => (
  required  => 1,
  is        => 'ro',
  isa       => Defined,
  writer    => 'set_id',
  predicate => 'has_id',
);

has mobiles => (
  lazy      => 1,
  is        => 'ro',
  isa       => HashRef,
  writer    => '_set_mobiles',
  predicate => '_has_mobiles',
  default   => sub { {} },
);

has present_users => (
  lazy      => 1,
  is        => 'ro',
  isa       => HashRef,
  writer    => '_set_present_users',
  predicate => '_has_present_users',
  default   => sub { {} },
);

sub from_file {
  my ($class, %params) = @_;
  my $path;
  confess "from_file() requires a file parameter"
    unless $path = $params{file};

  require POEx::MUD::ReadWrite;
  my $loaded = POEx::MUD::ReadWrite->new('YAML')->thaw_file($path);
  $self->validate_loaded_file($loaded);

  ## FIXME set up params from validated ref

  $class->new(%params)
}

sub validate_loaded_file {
  my ($self, $loaded) = @_;
  ## FIXME
}

sub add_adjoining {
  my ($self, $direction, $room_id) = @_;
  $room_id = blessed $room_id ? $room_id->id : $room_id ;
  $self->adjoining->{$direction} = $room_id
}

sub del_adjoining {
  my ($self, $direction) = @_;
  delete $self->adjoining->{$direction}
}

sub next_id_in_direction {
  my ($self, $direction) = @_;
  $self->adjoining->{$direction}
}


sub description_as_string {
  my ($self) = @_;
  join "\n", @{ $self->description }
}


sub add_mobile {
  my ($self, $mobile_obj) = @_;
  confess "Expected a POEx::MUD::Mobile"
    unless blessed $mobile_obj and $mobile_obj->isa('POEx::MUD::Mobile');
  $self->mobiles->{ $mobile_obj->id } = $mobile_obj
}

sub del_mobile {
  my ($self, $mobile_id) = @_;
  delete $self->mobiles->{ $mobile_obj->id }
}

sub add_user {
  my ($self, $user_obj) = @_;
  ## FIXME Character obj?
  $self->present_users->{ $user_obj->id } = $user_obj
}

sub del_user {
  my ($self, $user_id) = @_;
  delete $self->present_users->{ $user_obj->id }
}

1;
