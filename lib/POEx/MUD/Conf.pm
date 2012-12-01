package POEx::MUD::Conf;
use Carp;
use strictures 1;

use POEx::MUD qw/
  Tools::AutoloadAccessors
  ReadWrite
/;

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

1;
