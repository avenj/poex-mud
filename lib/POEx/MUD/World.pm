package POEx::MUD::World;
use 5.10.1;
use strictures 1;

## Provide proxy methods to manipulate a Map
## Manipulate objects within Rooms belonging to the Map

## World is a Emitter
## Coordinate World-related actions here and emit them

use Carp;
use Moo;

with 'MooX::Role::POE::Emitter';

use Scalar::Util 'blessed';

use namespace::clean -except => 'meta';


has map => (
  lazy      => 1,
  is        => 'ro',
  isa       => InstanceOf['POEx::MUD::World::Map'],
  writer    => 'set_map',
  predicate => 'has_map',
  ## FIXME create / load rooms to Map in builder
);


sub spawn {
  my ($self) = @_;
  $self->_start_emitter;
}

sub shutdown {
  my ($self) = @_;
  $self->_shutdown_emitter;
}


## Rooms
sub add_room {
  my ($self, $room_obj) = @_;
  $self->emit( 'room_added', $room_obj )
    if $self->map->add_room($room_obj);
}

sub del_room {
  my ($self, $room_id) = @_;
  $room_id = blessed $room_id ? $room_id->id : $room_id;
  if (my $room_obj = $self->map->del_room($room_id) ) {
    $self->emit( 'room_deleted', $room_obj )
  }
}

sub get_room {
  my ($self, $room_id) = @_;
  $self->map->get_room($room_id)
}

## Users
sub add_user_to_room {
  my ($self, $user, $room_id) = @_;
  $room_id = blessed $room_id ? $room_id->id : $room_id;
  ## FIXME
}

sub del_user_from_room {
  my ($self, $user, $room_id) = @_;
  $room_id = blessed $room_id ? $room_id->id : $room_id;
  ## FIXME
}

sub move_user {
  my ($self, %params) = @_;
  ## FIXME
}

## Mobiles
sub move_mobile {
  my ($self, %params) = @_;
  $params{lc $_} = delete $params{$_} for keys %params;

  for my $req (qw/from to mobile/) {
    confess "Missing required param $req"
      unless defined $params{$req}
  }

  ## FIXME should've got mobile obj

  $self->del_mobile($params{from}, $params{mobile});
  $self->add_mobile($params{to},   $params{mobile});

  $self->emit( 'mobile_moved',
    $params{from},
    $params{to},
    $params{mobile}
  );

  1
}

sub add_mobile {
  my ($self, $room_id, $mobile) = @_;
  $room_id = blessed $room_id ? $room_id->id : $room_id;
  ## FIXME
}

sub del_mobile {
  my ($self, $room_id, $mobile) = @_;
  $room_id = blessed $room_id ? $room_id->id : $room_id;
  ## FIXME
}


1;
