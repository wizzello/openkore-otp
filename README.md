# tOTP Plugin for OpenKore

## ✪ Overview

tOTP is a plugin for **OpenKore** that automatically handles Time-based One-Time Password (TOTP) authentication during login.
It listens for OTP requests and generates the correct TOTP code using the seed provided in your `config.txt`.

✅ Compatible with servers that require OTP during login.
✅ Lightweight and written purely in Perl, no external dependencies beyond OpenKore.

---

## ⚙ Requirements

* OpenKore (recent version with plugin system support)
* A **Base32-encoded OTP seed** (provided by your game account)
* Perl modules:
  * `Digest::SHA`

---

## 🚀 Installation

1️⃣ **Place the plugin**

Download `tOTP.pl` and put it in your OpenKore `plugins/` directory:

```
/openkore/plugins/tOTP/tOTP.pl
```

2️⃣ **Configure your OTP seed**

In your `config.txt` add your seed:

```
otpSeed T0TPS33DROL4S3RV
```

3️⃣ **Modify OpenKore source (important!)**

⚠ **OpenKore does not trigger a hook for OTP requests by default.**
You must modify `src/Network/Receive.pm`:

Find the method:

```perl
sub received_login_token {
```

And replace this part:

```perl
sub received_login_token {
	my ($self, $args) = @_;
	# XKore mode 1 / 3.
	return if ($self->{net}->version == 1);
	my $master = $masterServers{$config{master}};

	# rathena use 0064 not 0825
	$messageSender->sendTokenToServer($config{username}, $config{password}, $master->{master_version}, $master->{version}, $args->{login_token}, $args->{len}, $master->{OTP_ip}, $master->{OTP_port});
}
```

👉 With:

```perl
sub received_login_token {
	my ($self, $args) = @_;
	# XKore mode 1 / 3.
	return if ($self->{net}->version == 1);
	my $master = $masterServers{$config{master}};

	if (length($args->{login_token}) == 0) {
		Plugins::callHook('totp/request_otp', $messageSender);
		return;
	}

	# rathena use 0064 not 0825
	$messageSender->sendTokenToServer($config{username}, $config{password}, $master->{master_version}, $master->{version}, $args->{login_token}, $args->{len}, $master->{OTP_ip}, $master->{OTP_port});
}
```

This change allows your plugin to handle and send the TOTP code.

---

## ⚠ Why is Receive.pm modification required?

OpenKore core does **not** provide a native event or plugin hook when the server requests an OTP (via packet `0AE3`).
Without modifying `Receive.pm`, the plugin has no way to know when the server is expecting the OTP code.

---

## 📝 Example `config.txt`

```
master Latam - ROla: Freya/Nidhogg/Yggdrasil
server 0
username exemple@mail.com
password Str0ngP4ssW0rd
loginPinCode 0123
char 0
otpSeed T0TPS33DROL4S3RV
```

---

## 🔑 How it works

* Server sends a `0AE3` packet requesting an OTP code.
* Modified `Receive.pm` triggers: `Plugins::callHook('totp/request_otp', $messageSender);`
* The plugin generates a valid TOTP code and sends it to the server.
* Login continues automatically.

---

## 📜 License

This plugin is licensed under the MIT License.
See [https://mit-license.org/](https://mit-license.org/) for details.

---

## 🤝 Contributing

Fork, enhance, and share improvements — especially ideas on how to eliminate the need for core source modifications!

---

## 💬 Support

* [OpenKore forums](https://forums.openkore.com/)
* [OpenKore GitHub](https://github.com/OpenKore/openkore)
