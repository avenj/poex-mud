package POEx::MUD::Server;
use 5.10.1;
use strictures 1;

use Carp;
use Moo;
use POE;

with 'MooX::Role::POE::Emitter';

use namespace::clean -except => 'meta';

has 'backend' => (
  lazy    => 1,
  is      => 'ro',
  isa     => sub {
    blessed $_[0] and $_[0]->isa('POEx::MUD::Backend')
    or confess "Expected a POEx::MUD::Backend, got $_[0]"
  },
  writer    => 'set_backend',
  predicate => 'has_backend',
  builder   => '_build_backend',
);

sub _build_backend {
  my ($self) = @_;
  require POEx::MUD::Backend;
  POEx::MUD::Backend->new(
    ## FIXME get config opts
  );
}

sub BUILD {
  my ($self) = @_;

  push @{ $self->object_states },
    $self => [ qw/
      mud_backend_registered
      mud_listener_created
      mud_listener_removed
      mud_listener_failed
      mud_user_connected
      mud_connection_idle
      mud_backend_registered
    / ];

  $self->_start_emitter;

  $self->backend->spawn;
  $poe_kernel->post( $self->backend->session_id, 'register' );
}


sub mud_backend_registered {
  my ($kernel, $self) = @_[KERNEL, OBJECT];
  my $backend = $_[ARG0];
  $self->set_backend( $backend ) unless $self->has_backend;
}

sub mud_input {
  ## FIXME
}

sub mud_listener_created {
  my ($kernel, $self) = @_[KERNEL, OBJECT];
  my $listener = $_[ARG0];
  $self->emit( 'listener_created', $listener );
}

sub mud_listener_removed {
  my ($kernel, $self) = @_[KERNEL, OBJECT];
  my $listener = $_[ARG0];
  $self->emit( 'listener_removed', $listener );
}

sub mud_listener_failed {
  my ($kernel, $self) = @_[KERNEL, OBJECT];
  my ($listener, $op, $errnum, $errstr) = @_[ARG0 .. $#_];
  $self->emit( 'listener_failed', @_[ARG0 .. $#_] )
}

sub mud_user_connected {
  my ($kernel, $self) = @_[KERNEL, OBJECT];
  my $user = $_[ARG0];
  ## FIXME
}

sub mud_connection_idle {
  ## FIXME where do we handle idle disconnect?
}

1;
