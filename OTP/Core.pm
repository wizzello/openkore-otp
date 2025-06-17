package OTP::Core;

use strict;

use MIME::Base32 qw(decode_base32);
use Digest::SHA qw(hmac_sha1);

sub generate_otp {
    my ($seed) = @_;

    # contador big‑endian 64 bits
    my $counter = pack("Q>", int(time / 30));

    # decodifica Base32 com o módulo oficial
    my $key = decode_base32(uc $seed);

    # HMAC‑SHA1 e truncação dinâmica
    my $hmac = hmac_sha1($counter, $key);
    my $off  = ord(substr($hmac, -1)) & 0x0F;
    my $bin  = unpack("N", substr($hmac, $off, 4)) & 0x7FFFFFFF;
    my $otp  = $bin % (10 ** 6);

    return sprintf "%0*d", 6, $otp;
}

1;