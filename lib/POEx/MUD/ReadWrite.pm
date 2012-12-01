package POEx::MUD::ReadWrite;
use strictures 1;
use Module::Runtime 'use_module';
use Scalar::Util 'blessed';

our %Stateless;

use namespace::clean;

sub new {
  my ($class, $type) = splice @_, 0, 2;
  $type ||= 'YAML';
  my $real = 'POEx::MUD::ReadWrite::'.$type;

  if (blessed $Stateless{$real}) {
    return $Stateless{$real}
  }

  my $obj = use_module($real)->new(@_);

  return $Stateless{$real} = $obj
    if $obj->can('keeps_state')
    and !$obj->keeps_state;

  $obj
}

1;
