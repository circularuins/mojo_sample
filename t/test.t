use strict;
use warnings;
use Test::More;
use Test::Mojo;

require 'myapp.pl';

my $t = Test::Mojo->new;
$t->get_ok('/html/foobar')->status_is(200);

done_testing;
