package POEx::MUD::Types;

use strictures 1;

use base 'Exporter';
use MooX::Types::MooseLike;
use MooX::Types::MooseLike::Base qw/:all/;

our @EXPORT_OK;

use Scalar::Util 'blessed';

my $typedefs = [
  {
    name => 'InetProtocol',
    test => sub { $_[0] && $_[0] == 4 || $_[0] == 6 },
    message => sub { "$_[0] is not inet protocol 4 or 6" },
  },
];

MooX::Types::MooseLike::register_types(
  $typedefs, __PACKAGE__
);
our @EXPORT = (
  @EXPORT_OK,
  @MooX::Types::MooseLike::Base::EXPORT_OK
);

1;
