#!/usr/bin/perl

=head1 NAME

Text::Roman - Allows conversion between Roman and Arabic algarisms.

=head1 SYNOPSIS

 use Text::Roman qw/
    isroman roman2int int2roman ismilhar milhar2int
    roman mroman2int ismroman
    /;
	
 print int2roman(123);

 $roman	= "XXXV";
 print roman2int($roman) if isroman($roman);

 $milhar = 'L_X_XXIII';     # = 60,023
 print milhar2int($milhar) if ismilhar($milhar);

=cut

# --- prologue ----------------------------------------------------------------

package Text::Roman;

require 5.000;

use warnings;
use strict;
use Exporter;

use vars qw/$VERSION @ISA @EXPORT_OK/;
$VERSION    = substr q$Revision: 3.3 $, 10;
@ISA        = qw/Exporter/;
@EXPORT_OK  = qw/
    int2roman roman2int isroman milhar2int ismilhar
    roman mroman2int ismroman
    /;

use vars qw/@RSN @RCN %R2A %A2R/;

@RSN = qw/I V X L C D M/;                       # Roman Simple Numerals
@RCN = qw/IV IX XL XC CD CM/;                   # Roman Complex Numerals
@R2A{@RSN, @RCN} = qw/
    1 5 10 50 100 500 1000 4 9 40 90 400 900
    /;                                          # numeric values
%A2R = reverse %R2A;                            # reverse for convenience

# --- module interface --------------------------------------------------------

=head1 DESCRIPTION

This package supports both conventional Roman algarisms (which range from 1 to 3999) and Milhar Romans, a variation which uses a bar across the algarism to indicate multiplication by 1,000.  For the purposes of this module, acceptable syntax consists of an underscore suffixed to the algarism e.g. IV_V = 4,005.  The term Milhar apparently derives from the Portuguese word for "thousands" and the range of this notation extends the range of Roman numbers to 3999 x 1000 + 3999 = 4,002,999.

Note: the functions in this package treat Roman algarisms in a case-insensitive manner such that "VI" == "vI" == "Vi" == "vi".

The following functions may be imported into the caller package by name:

=head2 isroman

Tests a string to be a valid Roman algarism.  Returns a boolean value.

=cut

sub isroman {
    local $_ = shift || $_;                             # roman algarism
    
    return if ! /^[@RSN]+$/;
    return if /([IXCM])\1{3,}|([VLD])\2+/i;             # tests repeatability
    my @re = qw/IXI|XCX|CMC/;
    for (1 .. $#RSN) {
        push @re, "$RSN[$_ - 1]$RSN[$_]$RSN[$_ - 1]";   # tests IVI
        push @re, "$RSN[$_]$RSN[$_ - 1]$RSN[$_]";       # and VIV conditions
        }
    my $re = join "|", @re;
    !/$re/;
    }

=head2 int2roman

Converts an integer expressed in Arabic numerals, to its corresponding Roman algarism.  If the integer provided is out of the range expressible in Roman notation, an I<undef> is returned.

=cut

sub int2roman {
    my $n = shift || $_;     # number, arabic numerals
    return unless $n > 0 && $n < 4000;

    my $ret = "";
    for (reverse sort { $a <=> $b } values %R2A) {
        $ret .= $A2R{$_} x int($n / $_);
        $n %= $_;
        }
    $ret;
    }

=head2 roman2int

Does the converse of I<int2roman()>, converting a Roman algarism to its integer value.

=cut

sub roman2int {
    local $_ = uc(shift || $_);    # roman algarism

    return unless isroman();

    my ($r, $ret, $_ret) = ($_, 0, 0);
    while ($r) {
        $r =~ s/^$_// && ($ret += $R2A{$&}, last) for @RCN, @RSN;
        return unless $ret > $_ret;
        $_ret = $ret;
        }
    $ret;
    }

=head2 ismilhar

Determines whether a string qualifies as a Milhar Roman algarism.

=cut

sub ismilhar {
    local $_ = shift || $_;
    return unless /^[_@RSN]+$/;

    my @r = split /_/;
    isroman() || return for @r;
    1;
    }

=head2 milhar2int

Converts a Milhar Roman algarism to an integer.

=cut

sub milhar2int {
    local $_ = shift || $_;

    return unless ismilhar();

    my @r = split /_/;
    my $ret = roman2int(pop @r);
    $ret += 1000 * roman2int() for @r;
    $ret;
    }

=head2 ismroman mroman2int roman

These functions belong to the module's old interface and are considered deprecated.  Do not use them in new code and they will eventually be discontinued; they map as follows:

=over

=item ismroman   => B<ismilhar>

=item mroman2int => B<milhar2int>

=item roman      => B<int2roman>

=back

=cut

1;

__END__

=head1 CHANGES

Some changes worth noting from this module's previous incarnation:

=over

=item I<namespace imports>

The call to B<use> must now explicitly request function names imported into its namespace.

=item I<argument defaults/void context>

All functions now will operate on B<$_> when no arguments are passed, and will set B<$_> when called in a void context.  This allows for writing code like:

    @x = qw/V III XI IV/;
    roman2int() for @x;
    print join("-", @x);

instead of the uglier:

    @x = qw/V III XI IV/;
    $_ = roman2int($_) for @x;
    print join("-", @x);

=back

=head1 SPECIFICATION

Roman algarisms may be described using the following BNF-like formula:

    a   = I{1,3}
    b   = V\a?|IV|\a
    e   = X{1,3}\b?|X{0,3}IX|\b
    ee  = IX|\b
    f   = L\e?|XL\ee?|\e
    g   = C{1,3}\f?|C{0,3}XC\ee?|\f
    gg  = XC\ee?|\f
    h   = D\g?|CD\gg?|\g
    j   = M{1,3}\h?|M{0,3}CM\gg?|\h

=head1 REFERENCES

For a description of the Roman numeral system see: F<http://www.novaroma.org/via_romana/numbers.html>.  A reference to Milhar Roman alagarisms (in Portuguese) may be found at: F<http://www.estado.estadao.com.br/redac/norn-nro.html>.  

=head1 AUTHOR

Erick Calder <ecalder@cpan.org>

=head1 ACKNOWLEDGEMENTS

This module was originally written by Peter de Padua Krauss <krauss@ifqsc.sc.usp.br> and submitted to CPAN by Stanislaw Pusep <stanis@linuxmail.org> who has relinquished control to me since the original author has never maintained it and can no longer be reached.

I have completely rewritten the module, implementing simpler algorithms to perform the same functionality, adding a test suite, a Changes file, etc.  and providing more comprehensive documentation.

=head1 AVAILABILITY + SUPPORT

For questions, comments and support please feel free to e-mail me.  This module may be found on the CPAN.  Additionally, both the module and its RPM package are available from:

F<http://perl.arix.com>

=head1 DATE

$Date: 2003/01/16 01:56:34 $

=head1 VERSION

$Revision: 3.3 $

=cut
