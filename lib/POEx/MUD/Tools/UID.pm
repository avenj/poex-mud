package POEx::MUD::Tools::UID;
use strictures 1;

our $POEX_MUD_ID = 1;

sub id {
  ++$POEX_MUD_ID
}

1;
