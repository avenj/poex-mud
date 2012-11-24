package POEx::MUD::World;
use 5.10.1;
use strictures 1;

## Provide proxy methods to manipulate a Map
## Manipulate objects within Rooms belonging to the Map

use Carp;
use Moo;

has map => (
  required  => 1,
  is        => 'ro',
  isa       => InstanceOf['POEx::MUD::World::Map'],
  writer    => 'set_map',
  predicate => 'has_map',
);


sub add_room {
  my ($self, $room_obj) = @_;
  $self->map->add_room($room_obj)
}

sub del_room {
  my ($self, $room_id) = @_;
  $self->map->del_room($room_id)
}

sub get_room {
  my ($self, $room_id) = @_;
  $self->map->get_room($room_id)
}


## Mobiles
sub move_mobile {
  my ($self, %params) = @_;
  $params{lc $_} = delete $params{$_} for keys %params;

  for my $req (qw/from to mobile/) {
    confess "Missing required param $req"
      unless defined $params{$req}
  }

  $self->del_mobile($params{from}, $params{mobile});
  $self->add_mobile($params{to}, $params{mobile});
}

sub add_mobile {
  my ($self, $room_id, $mobile) = @_;
  ## FIXME
}

sub del_mobile {
  my ($self, $room_id, $mobile) = @_;
  ## FIXME
}


1;
