package POEx::MUD::Backend::User;
use strictures 1;

use Carp;
use Moo;

use POEx::MUD::Types;

use namespace::clean -except => 'meta';

has 'alarm_id' => (
  ## Idle alarm ID.
  lazy      => 1,
  isa       => Defined,
  is        => 'rw',
  predicate => 'has_alarm_id',
  default   => sub { 0 },
);

has 'idle_allowed' => (
  ## From Listener
  lazy    => 1,
  is      => 'rwp',
  isa     => Num,
  default => sub { 300 },
);

has peeraddr => (
  required => 1,
  isa    => Str,
  is     => 'ro',
);

has peerport => (
  required => 1,
  isa      => Str,
  is       => 'ro',
);

has seen => (
  ## TS of last activity
  lazy    => 1,
  isa     => Num,
  is      => 'rw',
  default => sub { time },
);

has sockaddr => (
  required => 1,
  isa      => Str,
  is       => 'ro',
);

has sockport => (
  required => 1,
  isa      => Int,
  is       => 'ro',
);

has 'wheel_id' => (
  lazy      => 1,
  isa       => Defined,
  is        => 'ro',
  writer    => '_set_wheel_id',
  predicate => 'has_wheel_id',
);

has wheel => (
  required  => 1,
  isa       => InstanceOf['POE::Wheel'],
  is        => 'ro',
  clearer   => 'clear_wheel',
  writer    => 'set_wheel',
  predicate => 'has_wheel',
  trigger => sub {
    my ($self, $wheel) = @_;
    $self->_set_wheel_id( $wheel->ID )
  },
);
