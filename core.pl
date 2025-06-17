package OTP::Core;

use strict;

use Digest::SHA qw(hmac_sha1);
use OTP::Utils qw(decode_base32);

sub generate_totp {
    my ($secret, $time_step, $digits) = @_;
    $time_step ||= 30;
    $digits ||= 6;

    my $decoded_key = decode_base32($secret);
    my $tstamp = int(time() / $time_step);
    my $tbytes = pack('J>', $tstamp);

    my $hmac = hmac_sha1($tbytes, $decoded_key);

    my $offset = hex(unpack('H2', substr($hmac, -1))) & 0x0F;
    my $bin = unpack('N', substr($hmac, $offset, 4)) & 0x7FFFFFFF;

    my $otp = $bin % (10 ** $digits);
    return sprintf('%06d', $otp);
}

1;