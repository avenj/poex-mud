package POEx::MUD::World::Map;
use 5.10.1;
use strictures 1;

use Carp;
use Moo;

use namespace::clean -except => 'meta';

with 'POEx::MUD::World::Role::LoadFromFile';

has rooms => (
  ## Keyed on room ID
  required  => 1,
  is        => 'ro',
  isa       => HashRef,
  writer    => 'set_rooms',
  predicate => 'has_rooms',
);


sub validate_loaded_file {
  my ($self, $loaded, $params) = @_;
  ## FIXME
}

sub add_room {
  my ($self, $room_obj) = @_;
  confess "add_room expected a POEx::MUD::World::Room, got $room_obj"
    unless blessed $room_obj and $room_obj->isa('POEx::MUD::World::Room');
  $self->rooms->{ $room_obj->id } = $room_obj
}

sub del_room {
  my ($self, $room_id) = @_;
  delete $self->rooms->{$room_id}
}

sub get_room {
  my ($self, $room_id) = @_;
  $self->rooms->{$room_id}
}


1;
