package POEx::MUD::ReadWrite::BDB;
use 5.10.1;
use strictures 1;

use Carp;
use Moo;

use DB_File;
use Fcntl qw/:DEFAULT :flock/;
use IO::File;
use Storable;
use Time::HiRes 'sleep';


use namespace::clean;

has file    => ()

has perms   => ()

has timeout => ()

# Skip timeout notification:
has quiet => ()

has tied    => (
  init_arg  => undef,
  is        => 'ro',
  predicate => 'has_tied',
  writer    => '_set_tied',
  clearer   => '_clear_tied',
  default   => { {} },
);

has _orig   => (
  init_arg  => undef,
  is        => 'ro',
  predicate => '_has_orig',
  writer    => '_set_orig',
  clearer   => '_clear_orig',
  default   => { {} },
);

has _lockfh => (
  writer => '_set_lockfh',
);

has _lockm  => (
  writer => '_set_lockm',
);

has bdb     => (
  predicate => 'has_bdb',
  writer    => '_set_bdb',
);

sub BUILDARGS {
  my ($class, @args) = @_;
  @args == 1 ? { file => $args[0] } : { @args }
}

sub bdb_open {
  my ($self, %args) = @_;

  if ( $self->has_tied ) {
    carp "bdb_open() on previously open db ".$self->file;
    return
  }

  my ($lflags, $fflags);
  if ($args{ro} || $args{readonly}) {
    $lflags = LOCK_SH | LOCK_NB;
    $fflags = O_CREAT | O_RDONLY ;
    $self->_set_lockm(LOCK_SH);
  } else {
    $lflags = LOCK_EX | LOCK_NB;
    $fflags = O_CREAT | O_RDWR;
    $self->_set_lockm(LOCK_EX);
  }

  my $orig = tie %{ $self->_orig }, "DB_File", $self->file,
    $fflags, $self->perms, $DB_HASH
    or confess "could not tie bdb: ".join ' ', $self->file, $!;

  $orig->sync;

  my $fd = $orig->fd;
  my $fh = IO::File->new("<&=$fd") or confess "failed dup: $!";
  my $ti = 0;
  my $timeout = $self->timeout;
  until ( flock $fh, $lflags ) {
    if ($ti >= $timeout) {
      carp "lock timed out trying to open ".$self->file
        unless $self->quiet;
      undef $orig; undef $fh; untie %{ $self->_orig };
      return
    }
    sleep 0.01;
    $ti += 0.01;
  }

  my $db = tie %{ $self->tied }, "DB_File", $self->file,
    $fflags, $self->perms, $DB_HASH,
    or confess "could not reopen bdb: ".join ' ', $self->file, $!;

  $self->_set_lockfh($fh);
  $self->_set_bdb($db);
  undef $orig;

  ## FIXME install filters

  1
}

sub bdb_close {
  my ($self) = @_;
  return unless $self->has_tied;

  ## FIXME

  $self->_clear_tied;
}

sub bdb_keys {
  my ($self) = @_;
  return unless $self->has_tied;
  keys %{ $self->tied }
}

sub bdb_fetch {

}

sub bdb_put {

}

sub bdb_delete {

}

sub bdb_dump {

}

## FIXME
##  dump via Storable
##  use db locking logic from Bot::Cobalt::DB


1;
