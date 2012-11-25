package POEx::MUD::Mobile;
use 5.12.1;
use strictures 1;

use Carp;
use Moo;

use POEx::MUD qw/
  Tools::Format
  Types
/;

use namespace::clean -except => 'meta';

has name => (
  required  => 1,
  is        => 'ro',
  isa       => Str,
  writer    => 'set_name',
  predicate => 'has_name',
);

has stats => (
  required  => 1,
  is        => 'ro',
  isa       => InstanceOf['POEx::MUD::Mobile::Stats'],
  writer    => 'set_stats',
  predicate => 'has_stats',
);

has _description => (
  init_arg  => 'description',
  lazy      => 1,
  is        => 'ro',
  isa       => ArrayRef,
  writer    => 'set_description',
  predicate => 'has_description',
  builder   => '_build_description',
);

sub _build_description {
  [
    '%name% doesn't look like much.'
  ],
}

sub get_description {
  my ($self) = @_;
  join "\n",  map {;
    templatef( $_,
        name => $self->name,
    )
  } @{ $self->_description };
}

has _presence_desc => (
  init_arg  => 'presence_desc',
  lazy      => 1,
  is        => 'ro',
  isa       => ArrayRef,
  ## Description(s) when present.
  writer    => 'set_presence_desc',
  predicate => 'has_presence_desc',
  builder   => '_build_presence_desc',
);

sub _build_presence_desc {
  [
    '%name is here.'
  ],
}

sub get_presence_desc {
  my ($self) = @_;

  join "\n",  map {;
    templatef( $_,
        name => $self->name,
    )
  } @{ $self->_presence_desc };
}

1;
