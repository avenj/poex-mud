package POEx::MUD::Tools::AutoloadAccessors;
use 5.10.1;
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

our $AUTOLOAD;
my $loader = sub {
  my ($self, $val) = @_;
  my $subname = (split /::/, $AUTOLOAD)[-1];
  return if index($subname, 'DESTROY') == 0;

  confess "No such subroutine $subname"
    unless blessed $self;

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
  ## FIXME better solution for new()
  *{ $pkg .'::new' } = $constructor
    unless $pkg->can('new');
  1
}

1;

=pod

=head1 NAME

POEx::MUD::Tools::AutoloadAccessors - Tiny class builder

=head1 SYNOPSIS

  package MyClass;
  use POEx::MUD::Tools::AutoloadAccessors;
  ## .. define methods, etc
  ## Override new() to add attribs if needed
  ## (it just needs to return a blessed hashref)

  package Other;
  ## Any attribs specified are read-write and have
  ## a 'has_' prefixed predicate method:
  my $obj = MyClass->new(
    things => 1,
    stuff  => 'meh',
    hash   => {
      objects => [],
    },
  );

  my $stuff = $obj->stuff;   ## reader
  $obj->stuff('and things'); ## writer
  $obj->has_stuff;           ## predicate

  ## Hashes are automatically blessed back into MyClass:
  my $array = $obj->hash->objects
    if $obj->hash->has_objects;

=head1 DESCRIPTION

A tiny class builder, sort of. This is the slow/deprecated approach to 
accessor generation; it is used by L<POEx::MUD::Conf> to inflate 
configuration files into objects and ought not be used for normal classes.

Abuses AUTOLOAD to provide read-write accessors and predicate methods for 
arbitrary attributes specified at construction time.

A default B<new()> constructor is provided; it takes either a hash or a 
reference to a hash mapping attributes to values. (If you'd like to 
override it, define your own B<new()> that returns a blessed hash reference, 
and call C<import()> on this module after blessing.)

Hashes are automatically blessed back into the class, so this works:

  my $obj = MyClass->new( things => { stuff => 1 } );
  $obj->things->stuff;

Calling B<new()> on the object works with the default constructor:

  my $new_obj = MyClass->new(
    new_attrib => $value,
    ## Include previous attribs also:
    %$obj
  );

You can override the default constructor with your own; it just needs to 
return a blessed hashref:

  package MyClass;
  use POEx::MUD::Tools::AutoloadAccessors ();
  sub new {
    my $class = shift;
    my $self = {
      ## Add some precreated accessors with default values
      abc  => '123',
      nada => undef,
      ## ...plus any specified:
      @_
    };

    bless $self, $class;
    POEx::MUD::Tools::AutoloadAccessors->import;
    $self
  }

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
