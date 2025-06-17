#############################################################################
#
# TOTP Authentication plugin by wizzello
#
# Openkore: http://openkore.com/
#
# This source code is licensed under the MIT License.
# See https://mit-license.org/
#
#############################################################################

package totp;

use strict;

use Plugins;
use Globals;
use Utils;
use Log qw(message error);
use Digest::SHA qw(hmac_sha1);

use Network::Send;

Plugins::register(
    'totpAuthentication',
    'Adds TOTP login Authentication',
    \\&unload
);

# Global variable to store the login token received from server
my $login_token = '';
my $login_type = 0;

# Hook to intercept TOTP request (opcode 0x0AE3)
# You need to add the following packet to packet_list
# '0AE3' => ['received_login_token', 'v l Z20 Z*', [qw(len login_type flag login_token)]],
my $hooks = Plugins::addHooks(
    ['packet/received_login_token', \&onReceivedLoginToken]
);

# Generate OTP using SHA1
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

sub generate_totp {
    my($secret, $time_step, $digits) = @_;
    $time_step ||= 30;
    $digits ||= 6;

    my $decoded_key = decode_base32($secret);
    my $tstamp = int(time() / $time_step);
    my $tbytes = pack('J>', $tstamp);

    my $hmac = hmac_sha1($tbytes, $decoded_key);

    my $offset = hex(unpack('H2', substr($hmac, -1))) & 0x0F;
    my $bin = unpack('N', substr($hmac, $offset, 4)) & 0x7FFFFFFF;

    my $otp = $bin % (10 ** $digits);
    
    return $otp;
}

sub onReceivedLoginToken {
    my (undef, $args) = @_;

    message "[totp] Detected TOTP request packet (0x0AE3)\n";

    # Extract information from the packet
    my $packet_len = $args->{len} || 0;
    $login_type = $args->{login_type} || 0;
    my $flag = $args->{flag} || 0;
    $login_token = $args->{login_token} || '';

    message "[totp] Packet length: $packet_len, Login type: $login_type, Flag: $flag\n";

    # Check if this is a TOTP request (typically when login_token is empty or minimal)
    if ($packet_len == 28 && !$login_token) {
        message "[totp] TOTP request detected - generating and sending TOTP code\n";

        unless ($config{'totpSecret'}) {
            error "[totp] Error: 'totpSecret' not configured in config.txt\n";
            return;
        }

        # Generates the TOTP code 
        # (Initially using Authen OATH, but in the future it may be a custom implementation)
        my $totp = generate_totp($config{'totpSecret'});
        unless (defined $totp) {
            error "[totp] Failed to generate TOTP\n";
            return;
        }

        message "[totp] Generated TOTP: $totp\n";

        sendTOTPCode($totp);
    }

    # Overrides default packet processing to avoid duplication
    return 0;
}

sub sendTOTPCode {
    my ($totp) = @_;
    
    # Validate TOTP code format
    unless ($totp =~ /^\d{6}$/) {
        error "[totp] Invalid TOTP code format: $totp\n";
        return;
    }
    
    message "[totp] Sending TOTP code: $totp\n";
    
    # Create the packet based on your network capture
    # Opcode 0x0C23 + TOTP code as ASCII string + null terminator
    my $packet = pack('v', 0x0C23) . $totp . "\x00";
    
    # Send using OpenKore's network system
    if ($net && $net->getState() == Network::IN_GAME || $net->getState() == Network::CONNECTED_TO_LOGIN_SERVER) {
        $net->send($packet);
        message "[totp] TOTP packet sent successfully\n";
    } else {
        error "[totp] Cannot send TOTP - not connected to server\n";
    }
}

sub unload {
    # Unregister hooks when unloading the plugin
    Plugins::delHooks($hooks);
    message "[totp] Plugin unloaded.\n";
}

1;