package POEx::MUD::Backend::Listener;

use 5.10.1;
use Carp;

use Moo;
use POEx::MUD::Types;

use namespace::clean -except => 'meta';

has addr => (
  required => 1,
  isa      => Str,
  is       => 'ro',
);
has port => (
  required => 1,
  isa      => Int,
  is       => 'ro',
);

has idle_allowed => (
  lazy => 1,
  isa  => Num,
  is   => 'ro',
  predicate => 'has_idle_allowed',
  writer    => 'set_idle_allowed',
  default   => sub { 300 },
);

has protocol => (
  lazy => 1,
  isa  => InetProtocol,
  is   => 'ro',
  default => sub {
    ## FIXME check w/ ip_is_* if none given
  },
);

has wheel_id => (
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
  predicate => 'has_wheel',
  writer    => 'set_wheel',
  trigger   => sub {
    my ($self, $wheel) = @_;
    $self->_set_wheel_id( $wheel->ID )
  },
);

1;
