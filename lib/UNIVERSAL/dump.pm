package UNIVERSAL::dump;

# Make sure we have version info for this module
# Be strict from now on

$VERSION = '0.03';
use strict;

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
# Set default method and subroutine name if nothing specified

    my $class = shift;
    unshift( @_,dump => 'Data::Dumper::Dumper' ) unless @_;

# Allow for redefining subroutines
# While there are parameters to be handled
#  Get the next method/subroutine pair
#  If there is already a method installed with that name
#   Croak if we're trying to install a different one

    no warnings 'redefine';
    while (@_) {
        my ($method,$sub) = splice @_,0,2;
        if (my $installed = $installed{$method}) {
            die qq{Cannot install "UNIVERSAL::$method" with "$sub": already installed with "$installed"\n} if $sub ne $installed;
        }

#  Fetch the module name from it
#  Turn it into something that can be used in a -require-
#  Mark this method as installed

        (my $module = $sub) =~ s#::[^:]+$##;
        $module =~ s#::#/#; $module .= ".pm";
        $installed{$method} = $sub;

#  Allow for variable references to subroutines
#  Create a method which
#   Obtains the object / class
#   Makes sure that we have the right module (even if it doesn't really exists)
#   Return dumper output if not in void context
#   Send dumper output to STDERR otherwise

        no strict 'refs';
        *{"UNIVERSAL::$method"} = sub {
            my $self = shift;
            eval { require $module };
            return $sub->( @_ ? @_ : $self ) if defined wantarray;
            print STDERR $sub->( @_ ? @_ : $self );
        } #$method
    }
} #import

#---------------------------------------------------------------------------

__END__

=head1 NAME

UNIVERSAL::dump - add dump methods to all classes and objects

=head1 SYNOPSIS

  use UNIVERSAL::dump; # implicit dump => 'Data::Dumper::Dumper'

 or:

  use UNIVERSAL::dump (
   _dump => 'Data::Dumper::Dumper',
  );

 or:

  use UNIVERSAL::dump ( # create both "dump" as well as "peek"
   dump => 'Data::Dumper::Dumper',
   peek => 'Devel::Peek::Dump',
  );

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

The name of the method, and the name of the subroutine to be called, can be
specified by parameters when loading the module.  One example is creating a
"peek" method that will us L<Devel::Peek> to dump the contents of the object
or anything else passed to the dump method.

As an extra feature, the output is sent to STDERR whenever the method is
called in a void context.  This makes it easier to dump variable structures
while debugging modules and programs.

To prevent different modules fighting over the same method name, a check
has been built in which will cause an exception when the same method is
attempted with a different subroutine name.

=head1 WHY?

One day, I finally had enough of always putting a "dump" and "peek" method
in my modules.  I came across L<UNIVERSAL::moniker> one day, and realized
that I could do something similar for my "dump" methods.

=head1 MORE EXOTIC USES

This module can be used for more exotic uses as well.

=head2 blessed

 use UNIVERSAL::dump blessed => 'Scalar::Util::blessed';

 if ($foo->blessed eq 'Foo') {
    print "This is a Foo object\n";
 }

Adds the "blessed" method to all objects.  Returns the class with which the
the object or specified value is not blessed.  Returns undef in every other
case.  Prints the return value to STDERR if called in void context.

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
