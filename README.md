# OTP Plugin for OpenKore

## ✪ Overview

OTP is a plugin for **OpenKore** that automatically handles Time-based One-Time Password (TOTP) authentication during login.
It listens for OTP requests and generates the correct TOTP code using the seed provided in your `config.txt`.

✅ Compatible with servers that require OTP during login.
✅ Lightweight and written purely in Perl, no external dependencies beyond OpenKore.

---

## ⚙ Requirements

* OpenKore (recent version with plugin system support)
* A **Base32-encoded OTP seed** (provided by your game account)
* Perl modules:
  * `MIME::Base32`
  * `Digest::SHA`

---

## 🚀 Installation

1️⃣ **Place the plugin**

Download `otp.pl` and put it in your OpenKore `plugins/` directory:

```
/openkore/plugins/OTP/otp.pl
```

Download `Core.pm` and put them in your OpenKore `plugins/OTP/` directory:

```
/openkore/plugins/OTP/OTP/Core.pm
```

2️⃣ **Configure your OTP seed**

In your `config.txt` add your seed:

```
otpSeed T0TPS33DROL4S3RV
```

3️⃣ **Ensure OpenKore core has the required hook**

⚠ This plugin depends on OpenKore having the `pre_sendTokenToServer` hook implemented.
➡ This is currently under review in the PR: [OpenKore PR #4036](https://github.com/OpenKore/openkore/pull/4036)

Please ensure this PR is merged into your OpenKore before using the plugin.

---

## 📝 Example `config.txt`

```
master Latam - ROla: Freya/Nidhogg/Yggdrasil
server 0
username exemple@mail.com
password Str0ngP4ssW0rd
loginPinCode 0123
otpSeed T0TPS33DROL4S3RV
```

---

## 🔑 How it works

* Server sends a `0AE3` packet requesting an OTP code.
* OpenKore calls the `pre_sendTokenToServer` hook.
* The plugin generates a valid TOTP code and sends it to the server.
* The plugin prevents `$messageSender->sendTokenToServer` from being called while the server is waiting for the OTP code.
* Login continues automatically.

---

## 📜 License

This plugin is licensed under the MIT License.
See [https://mit-license.org/](https://mit-license.org/) for details.

---

## 🤝 Contributing

Fork, enhance, and share improvements — especially ideas on how to eliminate the need for core source modifications!

---

## Special Thanks

This plugin was made possible thanks to contributions, ideas, and support from:

* **pogramos** – for the idea of creating a custom Base32 decoder instead of using external libraries.
* **SilverPhoenix28** – for sharing the way to handle OTP through `received_login_token` and `$messageSender`.
* **OpenKore Community** – for testing, feedback, and code reviews.

We appreciate every idea, report, and line of code that made this plugin better!

---

## 💬 Support

* [OpenKore forums](https://forums.openkore.com/)
* [OpenKore GitHub](https://github.com/OpenKore/openkore)
