package POEx::MUD::Server::With::Cmds::Move;
use 5.12.1;

use Moo::Role;

use namespace::clean;

no strict 'refs';
for my $direction (qw/up down north south east west/) {
  *{ __PACKAGE__ ."::user_cmd_$direction" } = sub {
    shift->_cmd_directional_move($direction, @_)
  };
}

use strictures 1;

sub _cmd_directional_move {
  my ($self, $direction) = splice @_, 0, 2;
  ## FIXME
}

1;
