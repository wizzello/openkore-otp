#############################################################################
#
# TOTP Authentication plugin by wizzello and pogramos
#
# Openkore: http://openkore.com/
#
# This source code is licensed under the MIT License.
# See https://mit-license.org/
#
#############################################################################

package tOTP;

use strict;

# Load necessary OpenKore modules
use Plugins;
use Globals;
use Utils;
use Digest::SHA qw(hmac_sha1);
use Log qw(message error);

# Register the plugin and provide unload handler
Plugins::register(
    'tOTP',
    'Handles OTP requests by generating and sending TOTP',
    \&unload
);

# Add hook to listen for the custom OTP request event
# This event must be triggered by a modified OpenKore source (see README.md)
my $hooks = Plugins::addHooks(
    ['totp/request_otp', \&on_request_otp]
);

# This function is called when OpenKore requests an OTP code.
# It generates the TOTP code and sends it to the server.
sub on_request_otp {
    my (undef, $sender) = @_;

    if (!$config{otpSeed}) {
        error "[tOTP] ERROR: otpSeed is not set in config.txt\n";
        return;
    }

    my $totp = generate_totp($config{otpSeed});
    message "[tOTP] Generated TOTP: $totp\n";

    my $packet = pack('v a6 C', 0x0C23, $totp, 0x00);

    $sender->sendToServer($packet);
    message "[tOTP] TOTP sent successfully\n";
}

sub decode_base32 {
    # Converts a Base32 string (your OTP seed) into raw bytes
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

# Generate a TOTP code based on the secret seed
sub generate_totp {
    my($secret, $time_step, $digits) = @_;
    # Default time step is 30 seconds and code length is 6 digits
    $time_step ||= 30;
    $digits ||= 6;

    my $decoded_key = decodeBase32($secret);
    my $tstamp = int(time() / $time_step);
    my $tbytes = pack('J>', $tstamp);

    my $hmac = hmac_sha1($tbytes, $decoded_key);

    my $offset = hex(unpack('H2', substr($hmac, -1))) & 0x0F;
    my $bin = unpack('N', substr($hmac, $offset, 4)) & 0x7FFFFFFF;

    my $otp = $bin % (10 ** $digits);
    
    return $otp;
}

sub unload {
    # Unregister hooks when unloading the plugin
    Plugins::delHooks($hooks);
    message "[tOTP] Plugin unloaded.\n";
}

1;
