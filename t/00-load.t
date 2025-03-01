#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Fast::Rus' ) || print "Bail out!\n";
}

diag( "Testing Fast::Rus $Fast::Rus::VERSION, Perl $], $^X" );
