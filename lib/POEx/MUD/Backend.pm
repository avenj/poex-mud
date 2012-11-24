package POEx::MUD::Backend;
our $VERSION = 0;

use 5.10.1;
use strictures 1;

use Carp;
use Moo;

use POEx::MUD qw/
  Backend::Listener
  Backend::User

  Types
/;

use Net::IP::Minimal qw/
  ip_is_ipv6
/;

use POE qw/
  Session
  Wheel::ReadWrite
  Wheel::SocketFactory
  Filter::Line
/;

use Socket qw/
  AF_INET AF_INET6
  inet_ntop
/;


use namespace::clean -except => 'meta';


has session_id => (
  init_arg  => undef,
  lazy      => 1,
  is        => 'ro',
  writer    => '_set_session_id',
  predicate => 'has_session_id',
  default   => sub { undef },
);

has controller => (
  ## A Server session, for example.
  lazy => 1,
  isa  => Value,
  is   => 'ro',
  writer    => 'set_controller',
  predicate => 'has_controller',
);

has listeners => (
  is  => 'rwp',
  isa => HashRef,
  default => sub { {} },
  clearer => 1,
);

has users => (
  is  => 'rwp',
  isa => HashRef,
  default => sub { {} },
  clearer => 1,
);

has filter => (
  lazy => 1,
  isa => InstanceOf['POE::Filter'],
  is  => 'rwp',
  default => sub {
    my ($self) = @_;
    POE::Filter::Line->new(
      InputRegexp   => '\015?\012',
      OutputLiteral => "\015\012",
    );
  },
);


has '__backend_user_class' => (
  lazy => 1,
  is   => 'rw',
  default => sub { 'POEx::MUD::Backend::User' },
);

has '__backend_listener_class' => (
  lazy => 1,
  is   => 'rw',
  default => sub { 'POEx::MUD::Backend::Listener' },
);


sub spawn {
  my ($class, %args) = @_;
  $args{lc $_} = delete $args{$_} for keys %args;

  my $self = ref $class ? $class : $class->new;

  my $sess_id = POE::Session->create(
    object_states => [
      $self => {
        register => 'p_register_controller',
        shutdown => 'p_shutdown',
        send     => 'p_send',

        'create_listener' => 'p_create_listener',
        'remove_listener' => 'p_remove_listener',

        '_accept_conn_v4' => 'p_accept_conn',
        '_accept_conn_v6' => 'p_accept_conn',
      },
      $self => [ qw/
        _start
        _stop

        p_idle_alarm
        p_sock_input
        p_sock_error
        p_sock_flushed
      / ],
    ],
  )->ID or confess "could not spawn POE::Session and retrieve ID";

  $self
}

sub p_register_controller {
  my $self = $_[OBJECT];
  $self->set_controller( $_[SENDER]->ID );
  $poe_kernel->refcount_increment( $self->controller, "MUD Running" );
  $poe_kernel->post( $self->controller, 'mud_backend_registered', $self );
}

sub shutdown {
  my $self = shift;
  $poe_kernel->post( $self->session_id, 'shutdown', @_ );
  1
}

sub p_shutdown {
  my $self = $_[OBJECT];

  $poe_kernel->refcount_decrement( $self->session_id, "MUD Running" );
  $poe_kernel->refcount_decrement( $self->controller, "MUD Running" );

  ## FIXME call disconnect method for all users

  $self->clear_listeners;
  $self->clear_users;
}

sub p_send {}
sub p_create_listener {}
sub p_remove_listener {}

sub p_accept_conn {
  my $self = $_[OBJECT];
  my ($sock, $p_addr, $p_port, $listener_id) = @_[ARG0 .. ARG3];

  my $type;

  my $type = $_[STATE] eq '_accept_conn_v6' ? AF_INET6 : AF_INET ;
  my $p_addr = inet_ntop( $type, $p_addr );

  my $sock_pack = getsockname($sock);
  ## FIXME 
  my ($proto, $sockaddr, $sockport) = get_unpacked_addr($sock_pack);
  my $listener = $self->listeners->{$listener_id};
  my $wheel = POE::Wheel::ReadWrite->new(
    Handle => $sock,
    Filter => $self->filter,
    InputEvent => 'p_sock_input',
    ErrorEvent => 'p_sock_error',
    FlushedEvent => 'p_sock_flushed',
  );

  unless ($wheel) {
    carp "Wheel creation failed in _accept_conn";
    return
  }

  my $w_id = $wheel->ID;
  my $user = $self->__backend_user_class->new(
    protocol => $proto,
    wheel    => $wheel,
    peeraddr => $p_addr,
    peerport => $p_port,
    sockaddr => $sockaddr,
    sockport => $sockport,
    seen     => time,
    idle_allowed => $listener->idle_allowed,
  );

  $self->users->{$w_id} = $user;
  $user->alarm_id(
    $poe_kernel->delay_set( 'p_idle_alarm', $user->idle_allowed, $w_id )
  );

  $poe_kernel->post( $self->controller, 'mud_listener_open', $user );
}

sub p_idle_alarm {}
sub p_sock_input {}
sub p_sock_error {}
sub p_sock_flushed {}
