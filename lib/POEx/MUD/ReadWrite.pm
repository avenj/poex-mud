package POEx::MUD::ReadWrite;

use Module::Runtime 'use_module';

sub new {
  my ($class, $type) = splice @_, 0, 2;
  $type ||= 'YAML';
  my $real = 'POEx::MUD::ReadWrite::'.$type;
  use_module($real)->new(@_)
}

1;
