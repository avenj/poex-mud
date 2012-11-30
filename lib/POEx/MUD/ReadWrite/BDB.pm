package POEx::MUD::ReadWrite::BDB;
use 5.10.1;
use strictures 1;

## BDB backend
## Mostly intended as cache for really huge worlds.

use Carp;
use Moo;

with 'POEx::MUD::ReadWrite::Interface';


use DB_File;
use Fcntl qw/:DEFAULT :flock/;
use IO::File;
use Storable ();
use Time::HiRes 'sleep';


use namespace::clean;


has file    => (
  required => 1,
  is       => 'ro',
);

has perms   => (
  is      => 'ro',
  writer  => 'set_perms',
  default => sub { 0644 },
);

has timeout => (
  is      => 'ro',
  writer  => 'set_timeout',
  default => sub { 5 },
);

# Skip timeout notification:
has quiet => (
  is      => 'ro',
  writer  => 'set_quiet',
  default => sub { 0 },
);

has tied    => (
  init_arg  => undef,
  is        => 'ro',
  predicate => 'has_tied',
  writer    => '_set_tied',
  clearer   => '_clear_tied',
  default   => sub { {} },
);

has _orig   => (
  init_arg  => undef,
  is        => 'ro',
  predicate => '_has_orig',
  writer    => '_set_orig',
  clearer   => '_clear_orig',
  default   => sub { {} },
);

has _lockfh => (
  lazy    => 1,
  is      => 'ro',
  writer  => '_set_lockfh',
  clearer => '_clear_lockfh',
);

has _lockm  => (
  lazy    => 1,
  is      => 'ro',
  writer  => '_set_lockm',
  clearer => '_clear_lockm',
);

has bdb     => (
  lazy      => 1,
  is        => 'ro',
  predicate => 'has_bdb',
  writer    => '_set_bdb',
  clearer   => '_clear_bdb',
);

sub BUILDARGS {
  my ($class, @args) = @_;
  @args == 1 ? { file => $args[0] } : { @args }
}

sub bdb_open {
  my ($self, %args) = @_;

  if ( $self->is_open ) {
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
    if ($ti > $timeout) {
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

  $db->filter_fetch_value(sub { $self->thaw($_) });
  $db->filter_store_value(sub { $self->nfreeze($_) });

  $self
}

sub bdb_close {
  my ($self) = @_;
  return unless $self->is_open;

  $self->bdb->sync if $self->_lockm == LOCK_EX;

  untie %{ $self->tied } or carp "bdb_close: untie: $!";
  flock( $self->_lockfh, LOCK_UN ) or carp "bdb_close: unlock: $!";

  $self->_clear_bdb;
  $self->_set_tied({});
  $self->_clear_lockfh;
  $self->_clear_lockm;

  1
}

sub bdb_keys {
  my ($self) = @_;
  return unless $self->is_open;
  keys %{ $self->tied }
}

sub bdb_fetch {
  my ($self, $key) = @_;
  return unless $self->is_open;
  $self->tied->{$key}
}

sub bdb_put {
  my ($self, $key, $value) = @_;
  return unless $self->is_open;
  $self->tied->{$key} = $value
}

sub bdb_delete {
  my ($self, $key) = @_;
  return unless $self->is_open;
  return unless exists $self->tied->{$key};
  delete $self->tied->{$key}
}

sub bdb_dump {
  my ($self) = @_;
  return unless $self->is_open;
  require Data::Dumper;
  Data::Dumper::Dump( $self->tied )
}

sub is_open {
  my ($self) = @_;
  return $self if $self->has_tied and tied %{ $self->tied };
  return
}

sub DESTROY {
  my ($self) = @_;
  $self->bdb_close if $self->is_open
}


sub freeze {
  my ($self, $data) = @_;
  Storable::nfreeze($data)
}

sub thaw {
  my ($self, $data) = @_;
  Storable::thaw($data)
}

1;
