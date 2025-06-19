#############################################################################
#
# OTP Generator plugin by wizzello and pogramos
#
# Openkore: http://openkore.com/
# Repository: https://github.com/wizzello/openkore-otp
#
# This source code is licensed under the MIT License.
# See https://mit-license.org/
#
#############################################################################

package OpenKore::Plugin::OTP;

use strict;
use Plugins;

Plugins::register(
    'otp',
    'Handles OTP requests by generating TOTP',
    \&unload
);

# Add hook to listen for the custom OTP request event
# This event must be triggered by OpenKore PR #4036
my $hooks = Plugins::addHooks(
    ['request_otp_login', \&generate]
);

sub generate {
    my ($plugin, $args) = @_;
    my $otp = $args->{otp};
    my $seed = $args->{seed};

    $$otp = _generate_otp($seed);
}

sub _generate_otp {
    my ($seed) = @_;

    my $secret = _base32_decode($seed);
    my $time_step = 30;
    my $digits = 6;

    my $time = time();
    my $counter = int($time / $time_step);

    my $bin_code = '';
    for my $i (7, 6, 5, 4, 3, 2, 1, 0) {
        $bin_code .= chr(($counter >> ($i * 8)) & 0xFF);
    }

    my $hash = _hmac_sha1($secret, $bin_code);

    my $offset = ord(substr($hash, -1)) & 0xf;
    my $dt = unpack "N", substr($hash, $offset, 4);
    $dt &= 0x7fffffff;
    
    my $modulus = 10 ** $digits;

    return sprintf("%0*d", $digits, $dt % $modulus);
}

sub _base32_decode {
    my ($base32_string) = @_;

    $base32_string =~ s/\s//g;
    $base32_string = uc($base32_string);
    $base32_string =~ s/=+$//;

    my $alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    my $bits = '';

    for my $char (split //, $base32_string) {
        my $index = index($alphabet, $char);
        die "Caractere inválido no Base32: $char" if $index == -1;
        $bits .= sprintf("%05b", $index);
    }
    
    my $bytes = '';
    for (my $i = 0; $i < length($bits); $i += 8) {
        if ($i + 8 <= length($bits)) {
            my $byte_bits = substr($bits, $i, 8);
            $bytes .= chr(oct("0b$byte_bits"));
        }
    }

    return $bytes;
}

sub _sha1 {
    my ($message) = @_;

    my @h = (
        0x67452301,
        0xEFCDAB89,
        0x98BADCFE,
        0x10325476,
        0xC3D2E1F0
    );

    my @msg_bytes = unpack("C*", $message);
    my $msg_len = @msg_bytes;

    push @msg_bytes, 0x80;
    while ((@msg_bytes % 64) != 56) {
        push @msg_bytes, 0x00;
    }

    my $bit_len = $msg_len * 8;
    for my $i (7, 6, 5, 4, 3, 2, 1, 0) {
        push @msg_bytes, ($bit_len >> ($i * 8)) & 0xFF;
    }

    for (my $chunk = 0; $chunk < @msg_bytes; $chunk += 64) {
        my @w = ();
        
        for my $i (0..15) {
            my $offset = $chunk + $i * 4;
            $w[$i] = ($msg_bytes[$offset] << 24) | 
                     ($msg_bytes[$offset + 1] << 16) |
                     ($msg_bytes[$offset + 2] << 8) | 
                     $msg_bytes[$offset + 3];
        }
        
        for my $i (16..79) {
            $w[$i] = _rotl($w[$i-3] ^ $w[$i-8] ^ $w[$i-14] ^ $w[$i-16], 1);
        }

        my ($a, $b, $c, $d, $e) = @h;

        for my $i (0..79) {
            my ($f, $k);
            if ($i <= 19) {
                $f = ($b & $c) | ((~$b) & $d);
                $k = 0x5A827999;
            } elsif ($i <= 39) {
                $f = $b ^ $c ^ $d;
                $k = 0x6ED9EBA1;
            } elsif ($i <= 59) {
                $f = ($b & $c) | ($b & $d) | ($c & $d);
                $k = 0x8F1BBCDC;
            } else {
                $f = $b ^ $c ^ $d;
                $k = 0xCA62C1D6;
            }

            my $temp = _add32(_rotl($a, 5), $f, $e, $w[$i], $k);
            $e = $d;
            $d = $c;
            $c = _rotl($b, 30);
            $b = $a;
            $a = $temp;
        }

        $h[0] = _add32($h[0], $a);
        $h[1] = _add32($h[1], $b);
        $h[2] = _add32($h[2], $c);
        $h[3] = _add32($h[3], $d);
        $h[4] = _add32($h[4], $e);
    }

    my $result = '';
    for my $word (@h) {
        for my $i (3, 2, 1, 0) {
            $result .= chr(($word >> ($i * 8)) & 0xFF);
        }
    }
    
    return $result;
}

sub _add32 {
    my (@nums) = @_;
    my $result = 0;
    for my $num (@nums) {
        $result += $num;
    }
    return $result & 0xFFFFFFFF;
}

sub _rotl {
    my ($val, $bits) = @_;
    return (($val << $bits) | ($val >> (32 - $bits))) & 0xFFFFFFFF;
}

sub _hmac_sha1 {
    my ($key, $data) = @_;
    my $block_size = 64;
    if (length($key) > $block_size) {
        $key = _sha1($key);
    }
    $key .= "\x00" x ($block_size - length($key));
    my $i_key_pad = $key ^ (chr(0x36) x $block_size);
    my $o_key_pad = $key ^ (chr(0x5c) x $block_size);
    return _sha1($o_key_pad . _sha1($i_key_pad . $data));
}

sub unload {
    Plugins::delHooks($hooks);
}

1;