# Tor Browser Launcher for macOS

Tor Browser Launcher is intended to make Tor Browser easier to install and use for macOS users. You install torbrowser-launcher from your distribution's package manager and it handles everything else:

* Downloads and installs the most recent version of Tor Browser, or launches Tor Browser if it's already at the latest version at launch time.

You might want to check out the [security design doc](https://github.com/micahflee/torbrowser-launcher/blob/develop/security_design.md).

![Tor Browser Launcher screenshot](/screenshot.png)

## Uninstallation

Delete and app bundle (or uninstall it with your package manager) and run the following commands:

```sh
defaults delete sh.tat.abstractcat.torbrowser-launcher
rm -fR ~/Library/Application\ Support/Tor\ Browser\ Launcher/
```
