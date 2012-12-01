use Test::More;
use strict; use warnings qw/FATAL all/;

use_ok('POEx::MUD::Tools::UID');
my $obj_simple = new_ok('POEx::MUD::Tools::UID');

my @ids;

push @ids, POEx::MUD::Tools::UID->id, $obj_simple->(), $obj_simple->id;

my %seen;
ok( @ids == 3, '3 IDs generated' );
ok(!(grep { $seen{$_}++ } @ids), 'IDs are all unique' );

done_testing;
