package OTP::Core;

use strict;

use Plugins;
use lib $Plugins::current_plugin_folder;
use OTP::Utils;

sub generate_otp {
    my ($base32_secret) = @_;
    my $secret = OTP::Utils::base32_decode($base32_secret);
    my $time_step = 30;
    my $counter = int(time() / $time_step);
    my $high = ($counter >> 32) & 0xFFFFFFFF;
    my $low  = $counter & 0xFFFFFFFF;
    my $msg = pack("NN", $high, $low);
    my $hash = OTP::Utils::hmac_sha1($secret, $msg);

    my $offset = ord(substr($hash, -1)) & 0x0f;
    my $binary = ((ord(substr($hash, $offset, 1)) & 0x7f) << 24) |
                 ((ord(substr($hash, $offset+1, 1)) & 0xff) << 16) |
                 ((ord(substr($hash, $offset+2, 1)) & 0xff) << 8) |
                 (ord(substr($hash, $offset+3, 1)) & 0xff);

    my $otp = $binary % 1_000_000;
    return sprintf("%06d", $otp);
}

1;