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
use Globals;
use Log qw(message error);
use lib $Plugins::current_plugin_folder;
use OTP::Core;

Plugins::register(
    'otp',
    'Handles OTP requests by generating and sending TOTP',
    \&unload
);

# Add hook to listen for the custom OTP request event
# This event must be triggered by OpenKore PR #4036
my $hooks = Plugins::addHooks(
    ['pre_sendTokenToServer', \&hook_login_received]
);

sub hook_login_received  {
    my (undef, $hookArgs) = @_;
    my $args = $hookArgs->{args};

    if (length($args->{login_token}) != 0) {
        return;
    }

    if (!$config{otpSeed}) { 
        error "[OTP] ERROR: otpSeed is not set in config.txt\n";
        return;
    }

    my $otp = OTP::Core::generate_otp($config{otpSeed});
    message "[OTP] Generated OTP: $otp\n";

    my $packet = pack('v a6 C', 0x0C23, $otp, 0x00);
    $messageSender->sendToServer($packet);
    message "[OTP] OTP sent successfully\n";

    ${ $hookArgs->{handlerRef} } = 1;
}

sub unload {
    Plugins::delHooks($hooks);
    message "[OTP] Plugin unloaded.\n";
}

1;