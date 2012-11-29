package POEx::MUD::ReadWrite::BDB::Async;

use 5.12.1;

use Moo;
use POE;

extends 'POEx::MUD::ReadWrite::BDB';
with 'MooX::Role::POE::Emitter';


use namespace::clean;


has 'retry' => (
  is      => 'ro',
  writer  => 'set_retry',
  default => sub { 0 },
);

has 'error_event' => (
  is => 'ro',
  writer => 'set_error_event',
  default => sub {
    return sub {
      my ($kern, $self) = @_[KERNEL, OBJECT];
      my ($func, $err) = $_[ARG0];
      warn "Error in $func - $err";
    }
  },
);

sub send_error_event {
  my ($self, $func, $err) = @_;
  $self->yield( $self->error_event, $func, $err )
}


sub spawn {
  my ($self) = @_;

  $self->set_timeout(0);

  push @{ $self->object_states },
    $self => {
      get    => '_dbfetch',
      put    => '_dbstore',
      delete => '_dbdel',
      del    => '_dbdel',
      keys   => '_dbkeys',
    },
    $self => [
      bdb_try_open
      bdb_db_open
    ],
  ;

  $self->_start_emitter;
}

sub shutdown {
  my ($self) = @_;
  $self->_stop_emitter
}


sub bdb_try_open {
  my ($kern, $self) = @_[KERNEL, OBJECT];
  my ($type, $cb, $args, $tried)   = @_[ARG0 .. $#_];

  ++$tried;
  if ( $self->bdb_open ) {
    $self->yield( 'bdb_db_open', $cb, @$args )
  } else {
    if ($self->retry and $tried > $self->retry) {
      $self->send_error_event( 'try_open', 'exceeded maximum lock retries' );
      return
    }
    $self->yield( 'bdb_try_open', $type, $cb, $args, $tried )
  }
}

sub bdb_db_open {
  my ($kern, $self) = @_[KERNEL, OBJECT];
  my ($cb, @args)   = @_[ARG0 .. $#_];
  $self->call( $cb, @args )
}

sub async_get {
  my ($self, $key, $cb) = @_;
  $self->yield( get => $key, $cb );
}

sub _dbfetch {
  my ($kern, $self, $sender) = @_[KERNEL, OBJECT, SENDER];
  my ($key, $cb) = @_[ARG0, ARG1];

  $self->yield( 'bdb_try_open',
    'ro',
    sub {
      my $value = $self->bdb_fetch($key);

      if (ref $cb eq 'CODE') {
        $self->yield( $cb, $key, $value )
      } else {
        $kern->post( $sender,
          ($cb || 'bdb_got_result'),
          $key,
          $value 
        );
      }
    },
  );
}


sub async_put {
  my ($self, $key, $value, $cb) = @_;
  $self->yield( put => $key, $value, $cb );
}

sub _dbstore {
  my ($kern, $self, $sender) = @_[KERNEL, OBJECT, SENDER];
  my ($key, $value, $cb) = @_[ARG0, ARG1];

  $self->yield( 'bdb_try_open',
    'rw',
    sub {
      $self->bdb_put($key, $value);

      if (ref $cb eq 'CODE') {
        $self->yield( $cb, $key, $value )
      } else {
        $kern->post( $sender,
          ($cb || 'bdb_wrote_value'),
          $key,
          $value
        );
      }
    },
  );
}

sub async_del {
  my ($self, $key, $cb) = @_;
  $self->yield( delete => $key );
}

sub _dbdel {
  my ($kern, $self, $sender) = @_[KERNEL, OBJECT, SENDER];
  my ($key, $cb) = @_[ARG0, ARG1];

  $self->yield( 'bdb_try_open',
    'rw',
    sub {
      my $value = $self->bdb_delete($key);

      if (ref $cb eq 'CODE') {
        $self->yield( $cb, $key, $value )
      } else {
        $kern->post( $sender,
          ($cb || 'bdb_deleted_value'),
          $key,
          $value
        );
      }
    },
  );
}


sub async_keys {
  my ($self) = @_;
  $self->yield( 'keys' )
}

sub _dbkeys {
  my ($kern, $self, $sender) = @_[KERNEL, OBJECT, SENDER];
  my $cb = $_[ARG0];

  $self->yield( 'bdb_try_open',
    'ro',
    sub {
      my @keys = $self->bdb_keys;

      if (ref $cb eq 'CODE') {
        $self->yield( $cb, \@keys )
      } else {
        $kern->post( $sender,
          ($cb || 'bdb_keys'),
          \@keys
        );
      }
    },
  );
}

1;
