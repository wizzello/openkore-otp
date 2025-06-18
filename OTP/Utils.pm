package OTP::Utils;

use strict;

sub base32_decode {
    my ($str) = @_;
    $str =~ tr/A-Z2-7//cd;
    my %map = map { substr("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567", $_, 1) => $_ } 0..31;
    my $bits = "";
    foreach my $char (split //, uc($str)) {
        my $val = $map{$char};
        $bits .= sprintf("%05b", $val);
    }
    my $bytes = pack("B*", $bits);
    return $bytes;
}

sub sha1 {
    my $msg = shift;

    my @h = (
        0x67452301,
        0xEFCDAB89,
        0x98BADCFE,
        0x10325476,
        0xC3D2E1F0
    );

    my $ml = length($msg) * 8;
    $msg .= chr(0x80);
    $msg .= chr(0x00) while ((length($msg) % 64) != 56);
    my $high = ($ml >> 32) & 0xFFFFFFFF;
    my $low  = $ml & 0xFFFFFFFF;
    $msg .= pack("NN", $high, $low);

    foreach my $chunk (unpack("(a64)*", $msg)) {
        my @w = unpack("N16", $chunk);
        push @w, 0 for (16..79);
        for my $i (16..79) {
            $w[$i] = _rol($w[$i-3] ^ $w[$i-8] ^ $w[$i-14] ^ $w[$i-16], 1);
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

            my $temp = (_rol($a,5) + $f + $e + $k + $w[$i]) & 0xFFFFFFFF;
            $e = $d;
            $d = $c;
            $c = _rol($b,30);
            $b = $a;
            $a = $temp;
        }

        $h[0] = ($h[0] + $a) & 0xFFFFFFFF;
        $h[1] = ($h[1] + $b) & 0xFFFFFFFF;
        $h[2] = ($h[2] + $c) & 0xFFFFFFFF;
        $h[3] = ($h[3] + $d) & 0xFFFFFFFF;
        $h[4] = ($h[4] + $e) & 0xFFFFFFFF;
    }

    return pack("N5", @h);
}

sub _rol {
    my ($val, $bits) = @_;
    return (($val << $bits) | ($val >> (32 - $bits))) & 0xFFFFFFFF;
}

sub hmac_sha1 {
    my ($key, $data) = @_;
    my $block_size = 64;
    if (length($key) > $block_size) {
        $key = sha1($key);
    }
    $key .= chr(0) x ($block_size - length($key));
    my $o_key_pad = $key ^ (chr(0x5c) x $block_size);
    my $i_key_pad = $key ^ (chr(0x36) x $block_size);
    return sha1($o_key_pad . sha1($i_key_pad . $data));
}

1;