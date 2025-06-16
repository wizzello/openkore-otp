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
use Authen::OATH;
use Network::Send;

Plugins::register(
    'totpAuthentication',
    'Adds TOTP login Authentication',
    \\&unload
);

# Hook to intercept TOTP request (opcode 0x0AE3)
# You need to add the following packet to packet_list
# '0AE3' => ['received_login_token', 'v l Z20 Z*', [qw(len login_type flag login_token)]],
my $hooks = Plugins::addHooks(
    ['packet/received_login_token', \&onReceivedLoginToken]
);

sub onReceivedLoginToken {
    message "[totp] Detected TOTP request packet (0x0AE3)\n";

    unless ($config{'totpSecret'}) {
        error "[totp] Error: 'totpSecret' not configured in config.txt\n";
        return;
    }

    # Generates the TOTP code 
    # (Initially using Authen OATH, but in the future it may be a custom implementation)
    my $oath = Authen::OATH->new();
    my $totp = $oath->totp($config{'totpSecret'});
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