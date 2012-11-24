package POEx::MUD::World::Room;
use 5.10.1;
use strictures 1;

use Carp;
use Moo;

use overload
  'bool' => sub { 1 },
  '""'   => 'id',
  fallback => 1;

## A Room belongs to a Map.

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
  ## FIXME set of Mobile objects present in this room?
);



sub next_in_direction {
  my ($self, $direction) = @_;
  $self->adjoining->{$direction}
}


sub add_mobile {
  my ($self, $mobile_obj) = @_;
  ## FIXME
}

sub del_mobile {
  my ($self, $mobile_id) = @_;
  ## FIXME
}

sub add_user {
  my ($self, $user_obj) = @_;
  ## FIXME
}

sub del_user {
  my ($self, $user_id) = @_;
  ## FIXME
}

1;
