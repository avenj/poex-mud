package POEx::MUD::Backend;
our $VERSION = 0;

## FIXME use an ascii-only custom filter that can
##  set up an event object for us?

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
  unpack_sockaddr_in
  unpack_sockaddr_in6
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

        p_accept_failed
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

sub send {
  my $self = shift;
  $poe_kernel->call( $self->session_id, 'send', @_ );
  1
}

sub p_send {
  my ($self, $to, @out) = @_[OBJECT, ARG0 .. $#_];
  $self->users->{$to}->wheel->put($_) for @out;
}

sub p_create_listener {
  my $self = $_[OBJECT];
  my %args = @_[ARG0 .. $#_];
  $args{lc $_} = delete $args{$_} for keys %args;

  my $idle_allowed = delete $args{idle} || 300;
  my $bindaddr     = delete $args{addr} || '0.0.0.0';
  my $bindport     = delete $args{port} || 0;

  my $proto = 4;
  $proto = 6 if delete $args{ipv6} or ip_is_ipv6($bindaddr);

  my $ssl = delete $args{ssl} || 0;

  my $wheel = POE::Wheel::SocketFactory->new(
    SocketDomain => ( $proto == 6 ? AF_INET6 : AF_INET ),
    BindAddress  => $bindaddr,
    BindPort     => $bindport,
    SuccessEvent =>
      ( $proto == 6 ? '_accept_conn_v6' : '_accept_conn_v4' ),
    FailureEvent => 'p_accept_failed',
    Reuse        => 1,
  );

  my $id = $wheel->ID;

  my $listener = $self->__backend_listener_class->new(
    protocol => $proto,
    wheel => $wheel,
    addr  => $bindaddr,
    port  => $bindport,
    idle_allowed => $idle_allowed,
    ssl   => $ssl,
  ) or confess "Could not create new() ".$self->__backend_listener_class;

  $self->listeners->{$id} = $listener;

  my ($addr, $port) = (  $proto == 4 ?
      ( unpack_sockaddr_in($wheel->getsockname) )
      : ( unpack_sockaddr_in6($wheel->getsockname) )
  );

  $listener->set_port($port) if $port;

  $poe_kernel->post( $self->controller, 'mud_listener_created', $listener )
}

sub p_remove_listener {
  my $self = $_[OBJECT];
  my %args = @_[ARG0 .. $#_];
  $args{lc $_} = delete $args{$_} for keys %args;

  if (defined $args{listener} && $self->listeners->{ $args{listener} }) {
    my $listener = delete $self->listeners->{ $args{listener} };
    $listener->clear_wheel;

    $poe_kernel->post( $self->controller,
      'mud_listener_removed', $listener
    );

    return
  }

  if (defined $args{addr} && defined $args{port}) {
    for my $id (keys %{ $self->listeners }) {
      my $listener = $self->listeners->{$id};

      if ($args{port} == $listener->port
        && $args{addr} eq $listener->addr) {
          delete $self->listeners->{$id};
          $listener->clear_wheel;

          $poe_kernel->post( $self->controller,
            'mud_listener_removed', $listener
          )
      }
    }
    return
  }

  if (defined $args{port}) {
    PORT: for my $id (keys %{ $self->listeners }) {
      my $listener = $self->listeners->{$id};

      if ($args{port} == $listener->port) {
        delete $self->listeners->{$id};
        $listener->clear_wheel;

        $poe_kernel->post( $self->controller,
          'mud_listener_removed', $listener
        )
      }
    }
    return
  }

  if (defined $args{addr}) {
    ADDR: for my $id (keys %{ $self->listeners }) {
      my $listener = $self->listeners->{$id};
      if ($args{addr} eq $listener->addr) {
        delete $self->listeners->{$id};
        $listener->clear_wheel;
        $poe_kernel->post( $self->controller,
          'mud_listener_removed', $listener
        )
      }
    }
    return
  }
}

sub p_accept_failed {
  my $self = $_[OBJECT];
  my ($op, $errnum, $errstr, $listener_id) = @_[ARG0 .. ARG3];
  my $listener = delete $self->listeners->{$listener_id};
  if ($listener) {
    $listener->clear_wheel;
    $poe_kernel->post( $self->controller,
      'mud_listener_failed',
      $listener, $op, $errnum, $errstr
    );
  }
}

sub p_accept_conn {
  my $self = $_[OBJECT];
  my ($sock, $p_addr, $p_port, $listener_id) = @_[ARG0 .. ARG3];

  my ($type, $proto);
  if ($_[STATE] eq '_accept_conn_v6') {
    $type  = AF_INET6;
    $proto = 6;
  } else {
    $type  = AF_INET;
    $proto = 4;
  }

  $p_addr = inet_ntop( $type, $p_addr );

  my $sock_pack = getsockname($sock);
  my ($sockaddr, $sockport) = ( $proto == 4 ?
     ( unpack_sockaddr_in($sock_pack) )
     : ( unpack_sockaddr_in6($sock_pack) )
  );

  my $listener = $self->listeners->{$listener_id};
  my $wheel = POE::Wheel::ReadWrite->new(
    Handle => $sock,
    Filter => $self->filter,
    InputEvent   => 'p_sock_input',
    ErrorEvent   => 'p_sock_error',
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

  $poe_kernel->post( $self->controller, 'mud_user_connected', $user );
}

sub p_idle_alarm {
  my $self = $_[OBJECT];
  my $w_id = $_[ARG0];
  my $this_user = $self->users->{$w_id} || return;

  $poe_kernel->post( $self->controller,
    'mud_connection_idle',
    $this_user
  );

  $this_user->alarm_id(
    $poe_kernel->delay_set( 'p_idle_alarm', 
      $this_user->idle_allowed,
      $w_id 
    )
  );
}

sub p_sock_input {
  my $self           = $_[OBJECT];
  my ($input, $w_id) = @_[ARG0, ARG1];
  my $this_user      = $self->users->{$w_id} || return;

  $this_user->seen( time );
  $poe_kernel->delay_adjust( $this_user->alarm_id, $this_user->idle_allowed )
    if $this_user->has_alarm_id;

  ## FIXME send to mud_input .. custom filter?
}

sub p_sock_error {
  my $self            = $_[OBJECT];
  my ($errstr, $w_id) = @_[ARG2, ARG3];
  my $this_conn       = $self->users->{$w_id} || return;
  ## FIXME call disconnect/cleanup method
}

sub p_sock_flushed {
  my ($self, $w_id) = @_[OBJECT, ARG0];

  return
}
