
BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use Test::More tests => 4;
use strict;
use warnings;

use_ok( 'UNIVERSAL::dump' );

sub Foo::testing { $_[0] }
use UNIVERSAL::dump (testing => 'Foo::dump');

can_ok( 'UNIVERSAL::dump',qw(
 dump
 import
 testing
) );

require Data::Dumper;
my $foo = bless {},'Foo';
is( $foo->dump,Data::Dumper::Dumper( $foo ),"Check if Data::Dumper dump ok" );
is( $foo->testing,Foo::testing( $foo ),"Check if Foo dump ok" );
