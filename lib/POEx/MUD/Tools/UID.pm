package POEx::MUD::Tools::UID;
use strictures 1;

use Scalar::Util 'blessed';

use overload
  bool => sub { 1 },
  '""' => 'id',
  ## Explicit but unnecessary given stringify:
  '0+' => 'id',
  fallback => 1,
;

our $POEX_MUD_ID = 0;

sub new {
  my ($class) = @_;
  bless $class->can('id'), blessed($class) || $class
}

sub id {
  ++$POEX_MUD_ID
}

1;

=pod

=head1 NAME

POEx::MUD::Tools::UID - An always-increasing integer

=head1 SYNOPSIS

  ## Equivalent syntax:
  my $id = POEx::MUD::Tools::UID->id;
  my $id = POEx::MUD::Tools::UID::id;

  my $obj = POEx::MUD::Tools::UID->new;
  my $id  = $n->id;
  my $id  = "$obj";
  my $id  = $obj + 0;

=head1 DESCRIPTION

This is a unique ID intended for internal use; the class method B<id> 
increments and returns an automatically incrementing global.

The class can produce overloaded objects representing the next integer.

=cut
