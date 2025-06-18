# OTP Generator Plugin for OpenKore

## 🎯 Overview

This plugin **generates Time-based One-Time Passwords (TOTP)** on demand, without modifying OpenKore core.

* **Plugin Name:** OTP
* **Repository:** [https://github.com/wizzello/openkore-otp](https://github.com/wizzello/openkore-otp)
* **License:** [MIT](https://github.com/wizzello/openkore-otp/LICENSE)

---

## 🔗 Dependencies

* **OpenKore** (version with plugin hook `request_otp_login` from PR #4036)
* **No external Perl modules** required; pure Perl implementation.

---

## 🚀 Installation

1. **Clone the repository** into your OpenKore plugins folder:

   ```bash
   cd openkore/plugins
   git clone https://github.com/wizzello/openkore-otp OTP
   ```

2. **Ensure your OpenKore is updated** to include PR #4036, which triggers the hook `request_otp_login` in `received_login_token`.

---

## 🔧 Configuration

Add your Base32-encoded OTP seed to `config.txt`:

```ini
otpSeed T0TPS33DROL4S3RV
```

---

## 🔑 Usage Flow

* Server sends a `0AE3` packet requesting an OTP code.
* OpenKore calls the hook `request_otp_login` instead of sending its default token logic.
* This plugin generates a valid TOTP code and returns it via the hook reference.
* Core then sends your OTP to the server with `sendOtpToServer`.

---

## ⚙️ Examples

### Hook Implementation in OpenKore (after PR #4036)

```perl
sub received_login_token {
    my ($self, $args) = @_;

    return if $self->{net}->version == 1;
    my $master = $masterServers{$config{master}};
    my $login_type = $args->{login_type};

    if ($login_type == 400 || $login_type == 1000) {
        die 'ERROR: otpSeed is not set in config.txt' unless $config{otpSeed};

        my $otp;
        Plugins::callHook('request_otp_login', { otp => \$otp, seed => $config{otpSeed} });
        debug "Generated OTP: $otp\n", 'parseMsg', 2;
        $messageSender->sendOtpToServer($otp);
    }
    # ... other cases ...
}
```

### Plugin Code Snippet

```perl
# Add hook listener
my $hooks = Plugins::addHooks([
    'request_otp_login', \&generate
]);

sub generate {
    my ($plugin, $args) = @_;
    my $otp_ref = $args->{otp};
    my $seed    = $args->{seed};
    $$otp_ref   = _generate_otp($seed);
}
```

---

## 🔄 Branch Dependency

This branch **depends on** the acceptance of [OpenKore PR #4036](https://github.com/OpenKore/openkore/pull/4036), which introduces the `request_otp_login` hook.

---

## 🤝 Contributing

Feel free to open issues or submit pull requests to improve this plugin or reduce core modifications further.

---

## Special Thanks

This plugin was made possible thanks to contributions, ideas, and support from:

* **pogramos** – for the idea of creating a custom Base32 decoder instead of using external libraries.
* **OpenKore Community** – for testing, feedback, and code reviews.

We appreciate every idea, report, and line of code that made this plugin better!

---

## 💬 Support

* [OpenKore forums](https://forums.openkore.com/)
* [OpenKore GitHub](https://github.com/OpenKore/openkore)
