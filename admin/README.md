#PHP-Userhandler

This is a repo meant to deal with the vast majority of handling cases for user work:

- Creation
- Login
- Authentication after-the-fact
- Forgotten passwords
- One-Time Passwords
- Etc

## Instructions

1. Move `api.php` to target API directory
2. Edit `api.php` as needed to fix paths
2. Edit `SAMPLE_CONFIG.php` to suit your configuration, and re-save as `CONFIG.php`.

Then you're set!

## Libraries

Libraries that may need minor tweaking to "play nice" have been included as subtrees, and those that should be used verbatim have been included as submodules.

Considering replacing the "current" [reCAPTCHA](https://developers.google.com/recaptcha/docs/php) API v1.11 [provided by Google in 2010](https://code.google.com/p/recaptcha/downloads/list?q=label:phplib-Latest) with the [php5 version on GitHub](https://github.com/AlekseyKorzun/reCaptcha-PHP-5).

### Subtrees

- [otphp](https://github.com/tigerhawkvok/otphp) is a subtree in the `totp/` directory. The relevant files are in `totp/lib/OTPHP`. The command to update this is `git subtree pull --prefix totp otphp master --squash`. It is a fork from [Spomky Labs](https://github.com/Spomky-Labs/otphp) frozen at the 2.0.x branch, before it was made abstract.
- [base32](https://github.com/ChristianRiesen/base32) is a subtree in the `base32/` directory. The relevant file is `base32/src/Base32/Base32.php`. The command to update this is `git subtree pull --prefix base32 base32 master --squash`
- [phpqrcode](https://github.com/t0k4rt/phpqrcode) is a subtree in the `qr/` directory. The relevant file is `qr/qrlib.php`. The command to update this is `git subtree pull --prefix qr qr master --squash`
- [twilio-php](https://github.com/twilio/twilio-php) is a subtree in the `twilio/` directory. The relevant file is `twilio/Services/Twilio.php`. The command to update this is `git subtree pull --prefix twilio twilio master --squash`
- [php-core](https://github.com/tigerhawkvok/php-core.git) is a subtree in the `core/` directory. The relevant file is `core/core.php`. The command to update this is `git subtree pull --prefix core core master --squash`.
- [zxcvbn](https://github.com/dropbox/zxcvbn) is a subtree in the `js/zxcvbn` directory. The relevant file is `js/zxcvbn/zxcvbn.js`. The command to update this is `git subtree pull --prefix js/zxcvbn zxcvbn master --squash`.


## Server configuration

The server is expected to have the basic number of columns and types listed in `SAMPLE-CONFIG.php`. If you change any of the default mappings, be sure to update the variables.

## Installation

1. Edit `SAMPLE-CONFIG.php` to suit your configuration and re-save it as `CONFIG.php`.
2. Upload this whole directory to your webserver.
3. Where you need access to any login functions or scripts, include `path_to_dir/login.php`.
   1. If you want to actually output the login screen, be sure to print the variable `$login_output`.
4. Set `handlers/temp` as server-writeable.

You're set!

### JavaScript

This loads a number of libraries asynchronously in `js/loadJQuery.js`. If you encounter issues, you may want to manually insert these libraries into your pages. In particular, it may have issues with pages that are served as XHTML.

### Debugging odd behavior

The most likely reason for a misbehaving application is something else bound to the document onload handler. Anything you want to be handled on load insert into a function named `lateJS()`, and it will be called by the script.

If you have functions that redraw the screen, and want to force a user to use two-factor authentication, there may be issues. Check for the variable `window.totpParams.tfaLock`; it will be set as `true` when a lock is needed, and you can wrap any redrawing functions in there.
