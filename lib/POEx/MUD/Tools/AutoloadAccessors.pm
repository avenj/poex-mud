package POEx::MUD::Tools::AutoloadAccessors;
use Carp;
use strictures 1;

use Scalar::Util 'blessed';
use POEx::MUD::ReadWrite;

use namespace::clean;

my $constructor = sub {
  my $class = shift;
  my $self  = @_ > 1 ? {@_} : ref $_[0] eq 'HASH' ? $_[0] : {};
  bless $self,
    (blessed($class) || $class);

  $self
};

my $loader = sub {
  my ($self, $val) = @_;
  my $subname = $AUTOLOAD;
  return unless blessed $self and index($subname, 'DESTROY') == -1;
  $subname = (split /::/, $subname)[-1];

  if (index($subname, 'has_') == 0) {
    ## Predicate.
    return exists $self->{ substr($subname, 4) } ? 1 : ()
  }

  ## Cannot autoviv new methods, existing are rw():
  confess "No such method or value: $subname"
    unless exists $self->{$subname};
  $self->{$subname} = $val if defined $val;

  if (ref $self->{$subname} eq 'HASH') {
    ## $cf->somekey->another->value()
    return $self->new(%{$self->{$subname}})
  }

  $self->{$subname}
};

sub import {
  my $pkg = caller;
  no strict 'refs';
  *{ $pkg .'::AUTOLOAD' } = $loader;
  *{ $pkg .'::new' } = $constructor
    unless $pkg->can('new');
  1
}

1;
