#############################################################################
#
# OTP Authentication plugin by wizzello and pogramos
#
# Openkore: http://openkore.com/
#
# This source code is licensed under the MIT License.
# See https://mit-license.org/
#
#############################################################################

package OTP;

use strict;

use Plugins;
use lib $Plugins::current_plugin_folder;
use OTP::Core;

# Load necessary OpenKore modules
use Globals;
use Digest::SHA qw(hmac_sha1);
use Log qw(message error);

# Register the plugin and provide unload handler
Plugins::register(
    'otp',
    'Handles OTP requests by generating and sending TOTP',
    \&unload
);

# Add hook to listen for the custom OTP request event
# This event must be triggered by a modified OpenKore source (see README.md)
my $hooks = Plugins::addHooks(
    ['login_token_requested', \&on_request_otp]
);

# This function is called when OpenKore requests an OTP code.
# It generates the TOTP code and sends it to the server.
sub on_request_otp {
    my (undef, $messageSender) = @_;

    if (!$config{otpSeed}) {
        error "[OTP] ERROR: otpSeed is not set in config.txt\n";
        return;
    }

    my $totp = OTP::Core::generate_otp($config{otpSeed});
    message "[OTP] Generated TOTP: $totp\n";

    my $packet = pack('v a6 C', 0x0C23, $totp, 0x00);

    $messageSender->sendToServer($packet);
    message "[OTP] TOTP sent successfully\n";
}

sub unload {
    # Unregister hooks when unloading the plugin
    Plugins::delHooks($hooks);
    message "[OTP] Plugin unloaded.\n";
}

1;
