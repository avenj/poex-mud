use Test::More;
use strict; use warnings qw/FATAL all/;

use_ok('POEx::MUD::Tools::UID');
my $obj = new_ok('POEx::MUD::Tools::UID');

my @ids;

push @ids,
  POEx::MUD::Tools::UID->id,
  $obj->(),
  $obj->id,
  "$obj",
  $obj+0
;

my %seen;
ok( @ids == 5, '5 IDs generated' );
ok(!(grep { $seen{$_}++ } @ids), 'IDs are all unique' );

done_testing;
