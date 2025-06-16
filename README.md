## TOTP Plugin for OpenKore

This plugin adds **TOTP/OTP** support to the OpenKore login process using the **Authen::OATH** Perl module, allowing you to log into Ragnarok Online servers that require two-factor authentication (2FA) with minimal setup.

---

### 📋 Prerequisites

* **OpenKore** installed and functioning.
* Perl (bundled with OpenKore).
* **Authen::OATH** Perl module. Install via CPAN if not already present:

  ```bash
  cpan Authen::OATH
  ```

---

### ⚙️ Installation

1. **Download** `totp.pl` and place it in the `plugins/` folder of your OpenKore directory.
2. Open the `config.txt` file located in the main OpenKore folder.
3. Add the following line, replacing `YOUR_BASE32_SECRET` with your Base32-encoded TOTP secret key:

   ```ini
   totpSecret YOUR_BASE32_SECRET
   ```
4. **Save** `config.txt`.
5. **Restart** OpenKore so the plugin is loaded at startup.

---

### 🚀 Usage

1. Launch OpenKore normally. When the server requests a TOTP code, this plugin will detect the request automatically.
2. The plugin uses **Authen::OATH** to generate the current TOTP code from your secret and sends it to the server.
3. If the code is correct, OpenKore will continue to the world selection screen.

> **Note:** This plugin listens for packet `0x0AE3` (roughly 28 bytes) to trigger the TOTP prompt.

---

### 🔧 Configuration

* **totpSecret**: Your Base32-encoded TOTP secret key (e.g., `JBSWY3DPEHPK3PXP`).

Other OpenKore settings remain in `config.txt` as usual.

---

### 🐞 Troubleshooting

* **No code sent**:

  * Verify `totpSecret` is correctly set in `config.txt`.
  * Ensure there are no extra spaces or hidden characters.

* **Error messages**:

  * `Error: 'totpSecret' not found in config.txt` → Check that `totpSecret` is spelled correctly.
  * `Authen::OATH module not found` → Install it via CPAN: `cpan Authen::OATH`.

Logs will show messages from `[totp]` prefix for easier diagnosis.

---

### 📖 How It Works

1. **Intercept**: Hooks into packet `0x0AE3` to detect when the server asks for the OTP.
2. **Generate**: Uses `Authen::OATH->totp($secret)` to compute the 6-digit TOTP code.
3. **Send**: Packages the code in packet `0x0C23` and sends it to the server.

---

### 📬 Feedback & Contributions

If you discover any bugs or have suggestions, please open an issue in the repository or contact the author directly.
