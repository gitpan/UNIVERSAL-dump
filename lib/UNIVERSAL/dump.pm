package UNIVERSAL::dump;

# Make sure we have version info for this module
# Be strict from now on

$VERSION = '0.04';
use strict;

# Initialize the hash with presets

my %preset = (
 blessed => 'Scalar::Util::blessed',
 dump    => 'Data::Dumper::Dumper',
 peek    => 'Devel::Peek::Dump',
 refaddr => 'Scalar::Util::refaddr',
);

# Hash with installed handlers

my %installed;

# Satisfy require

1;

#---------------------------------------------------------------------------

# Perl specific subroutines

#---------------------------------------------------------------------------
#  IN: 1 class (ignored)
#      2..N method => subroutine pairs

sub import {

# Obtain the class (ignored for now)
# Set default method if nothing specified

    my $class = shift;
    unshift( @_,'dump' ) unless @_;

# Allow for redefining subroutines
# For all of the parameters to be handled
#  If we got a preset
#   Die now if we don't know how to handle the preset
#   Handle the preset by calling ourselves
#   And reloop

    no warnings 'redefine';
    foreach (@_) {
        unless (ref) {
            die qq{Don't know how to install method "UNIVERSAL::$_"\n}
             unless my $sub = $preset{$_};
            $class->import( {$_ => $sub} );
            next;
        }

#  For all the method / subroutine pairs
#   Normalize if another method name was specified
#   If there is already a method installed with that name
#    Croak if we're trying to install a different one

        while (my ($method,$sub) = each %{$_}) {
            $sub = $preset{$sub} if $preset{$sub};
            if (my $installed = $installed{$method}) {
                die qq{Cannot install "UNIVERSAL::$method" with "$sub": already installed with "$installed"\n} if $sub ne $installed;
            }

#   Fetch the module name from it
#   Turn it into something that can be used in a -require-
#   Mark this method as installed

            (my $module = $sub) =~ s#::[^:]+$##;
            $module =~ s#::#/#; $module .= ".pm";
            $installed{$method} = $sub;

#   Allow for variable references to subroutines
#   Create a method which
#    Obtains the object / class
#    Makes sure that we have the right module (even if it doesn't really exists)
#    Return dumper output if not in void context
#    Send dumper output to STDERR otherwise

            no strict 'refs';
            *{"UNIVERSAL::$method"} = sub {
                my $self = shift;
                eval { require $module };
                return $sub->( @_ ? @_ : $self ) if defined wantarray;
                print STDERR $sub->( @_ ? @_ : $self );
            } #$method
        }
    }
} #import

#---------------------------------------------------------------------------

__END__

=head1 NAME

UNIVERSAL::dump - add dump methods to all classes and objects

=head1 SYNOPSIS

  use UNIVERSAL::dump; # implicit 'dump'

 or:

  use UNIVERSAL::dump qw(dump peek); # create both "dump" and "peek"

 or:

  use UNIVERSAL::dump ( { _dump => 'dump' } ); # dump using "_dump"

 or:

  use UNIVERSAL::dump ( { bar => 'Bar::Dumper' } ); # "foo" dumper

 my $foo = Foo->new;
 print $foo->dump;         # send dump of $foo to STDOUT
 print $foo->dump( $bar ); # send dump of $bar to STDOUT

 $foo->dump;         # send dump of $foo to STDERR
 $foo->dump( $bar ); # send dump of $bar to STDERR

=head1 DESCRIPTION

Loading the UNIVERSAL::dump module adds one or more methods to all classes
and methods.  It is intended as a debugging aid, alleviating the need to
add and remove debugging code from modules and programs.

By default, it adds a method "dump" to all classes and objects.  This method
either dumps the object, or any parameters specified, using L<Data::Dumper>.

As an extra feature, the output is sent to STDERR whenever the method is
called in a void context.  This makes it easier to dump variable structures
while debugging modules and programs.

The name of the method can be specified by parameters when loading the module.
These are the method names that are currently recognized:

=over 2

=item blessed

Return or prints with which class the object (or any value) is blessed.
Uses L<Scalar::Util>'s "blessed" subroutine.

=item dump

Return or prints a representation of the object (or any value that is
specified).  Uses L<Data::Dumper>'s "Dumper" subroutine.

=item peek

Return or prints the internal representation of the object (or any value that
is specified).  Uses L<Devel::Peek>'s "Dump" subroutine.

=item refaddr

Return or prints with the memory address of the object (or any value
specified).  Uses L<Scalar::Util>'s "refaddr" subroutine.

=back

If you cannot use one of the preset names of methods, you can specify a
reference to a hash instead, in which the key is the new name of the method
and the value is the name with which the dumping method is normally indicated.

If you have a dumping subroutine that is not available by default, you can
add your own by specifying a reference to a hash, in which the key is the
method name, and the value is the (fully qualified) name of the subroutine.

To prevent different modules fighting over the same method name, a check
has been built in which will cause an exception when the same method is
attempted with a different subroutine name.

=head1 WHY?

One day, I finally had enough of always putting a "dump" and "peek" method
in my modules.  I came across L<UNIVERSAL::moniker> one day, and realized
that I could do something similar for my "dump" methods.

=head1 REQUIRED MODULES

 Data::Dumper (any)

=head1 CAVEATS

=head2 AUTOLOADing methods

Any method called "dump" (or whichever class or object methods you activate
with this module) will B<not> be AUTOLOADed because they are already found
in the UNIVERSAL package..

=head1 AUTHOR

Elizabeth Mattijsen, <liz@dijkmat.nl>.

Please report bugs to <perlbugs@dijkmat.nl>.

=head1 COPYRIGHT

Copyright (c) 2004 Elizabeth Mattijsen <liz@dijkmat.nl>. All rights
reserved.  This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
