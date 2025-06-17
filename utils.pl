package OTP::Utils;

use strict;

sub decode_base32 {
    my ($b32) = @_;
    $b32 = uc($b32);
    $b32 =~ tr/A-Z2-7//cd;

    my %b32map = (
        A => 0, B => 1, C => 2, D => 3, E => 4, F => 5, G => 6, H => 7,
        I => 8, J => 9, K => 10, L => 11, M => 12, N => 13, O => 14, P => 15,
        Q => 16, R => 17, S => 18, T => 19, U => 20, V => 21, W => 22, X => 23,
        Y => 24, Z => 25, 2 => 26, 3 => 27, 4 => 28, 5 => 29, 6 => 30, 7 => 31
    );

    my $bits = '';
    foreach my $char (split //, $b32) {
        $bits .= sprintf('%05b', $b32map{$char});
    }

    my $bytes = '';
    while (length($bits) >= 8) {
        my $byte = substr($bits, 0, 8);
        $bytes .= chr(oct("0b$byte"));
        $bits = substr($bits, 8);
    }

    return $bytes;
}

1;
