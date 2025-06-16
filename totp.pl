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

    # Gera o código TOTP
    my $oath = Authen::OATH->new();
    my $totp = $oath->totp($secret);
    unless (defined $totp) {
        error "[totp] Falha ao gerar TOTP\n";
        return;
    }

    message "[totp] Sending TOTP: $totp\n";

    # Monta o pacote de envio do TOTP (opcode 0x0C23)
    # 0x23, 0x0C + ASCII do código + null terminator
    my $packet = pack('C2', 0x23, 0x0C) . $totp . "\x00";

    # Envia ao servidor
    Network::Send::sendToServer($packet);

    # Cancelamos o processamento padrão do pacote para evitar duplicação
    return 0;
}

sub unload {
    # Unregister hooks when unloading the plugin
    Plugins::delHooks($hooks);
    message "[totp] Plugin unloaded.\n";
}

1;