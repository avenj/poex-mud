package POEx::MUD::Server;
use 5.10.1;
use strictures 1;

use Carp;
use Moo;

with 'MooX::Role::POE::Emitter';

use namespace::clean -except => 'meta';

has 'backend' => (
  ## FIXME
);

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

  ## FIXME set up and start backend (backend builder, call from here?)
  ## FIXME register with backend
}


sub mud_backend_registered {
  my ($kernel, $self) = @_[KERNEL, OBJECT];
  my $backend = $_[ARG0];
  $self->set_backend( $backend );
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
