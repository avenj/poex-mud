package POEx::MUD::Conf;
use Carp;
use strictures 1;

use Scalar::Util 'blessed';
use POEx::MUD qw/
  ReadWrite::YAML
/;

use namespace::clean;

sub new {
  my $class = shift;
  my $self  = @_ > 1 ? {@_} : ref $_[0] eq 'HASH' ? $_[0] : {};
  bless $self,
    (blessed($class) || $class);

  $self
}

sub read_config_from {
  my ($self, $file) = @_;
  confess "Expected a file path" unless defined $file;

  my $cf = POEx::MUD::ReadWrite->new('YAML')->thaw_file($file);
  $cf->{lc $_} = delete $cf->{$_} for keys %$cf;

  $self->__inflate_to_obj($cf) || $cf
}

sub write_config_to {
  my ($self, $file) = @_;
  confess "Expected a file path" unless defined $file;
  my $data = POEx::MUD::ReadWrite::YAML->freeze(+{ %$self });
}

sub __inflate_to_obj {
  my ($self, $cf) = @_;
  $self->new($cf)
}

sub AUTOLOAD {
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
}

1;
