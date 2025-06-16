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
use Log qw(message error);
use Utils;
use Config;
use Authen::OATH;
use Network::Send;

Plugins::register(
    'totpAuthentication',
    'Adds TOTP login Authentication',
    \\&unload
);

# Hook to intercept TOTP request (opcode 0x0AE3)
my $hooks = Plugins::addHooks(
    ['packet/0x0AE3', \&onAskOtp]
);

sub onAskOtp {
    my ($hook, $args) = @_;
    # Get the payload without the 4-byte header
    my $msg = $args->{msg};

    # Checks if it is indeed a TOTP request (typical size of 28 bytes)
    if (length($msg) != 28) {
        return;
    }

    # Get TOTP secret key from config.txt (Base32)
    my $secret = Config::get('totpSecret');
    unless ($secret) {
        error "[totp] Error: 'totpSecret' not configured in config.txt\n";
        return;
    }

    # Generates the TOTP code 
    # (Initially using Authen OATH, but in the future it may be a custom implementation)
    my $oath = Authen::OATH->new();
    my $totp = $oath->totp($secret);
    unless (defined $totp) {
        error "[totp] Failed to generate TOTP\n";
        return;
    }

    message "[totp] Sending TOTP: $totp\n";

    # Assembles the TOTP sending packet (opcode 0x0C23) 
    # 0x23, 0x0C + ASCII code + null terminator
    # And send to the server
    my $packet = pack('C2', 0x23, 0x0C) . $totp . "\x00";
    Network::Send::sendToServer($packet);

    # Overrides default packet processing to avoid duplication
    return 0;
}

sub unload {
    # Unregister hooks when unloading the plugin
    Plugins::delHooks($hooks);
    message "[totp] Plugin unloaded.\n";
}

1;