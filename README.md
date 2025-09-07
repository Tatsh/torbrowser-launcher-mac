# torbrowser-launcher-mac

[![GitHub tag (with filter)](https://img.shields.io/github/v/tag/Tatsh/torbrowser-launcher-mac)](https://github.com/Tatsh/torbrowser-launcher-mac/tags)
[![License](https://img.shields.io/github/license/Tatsh/torbrowser-launcher-mac)](https://github.com/Tatsh/torbrowser-launcher-mac/blob/master/LICENSE.txt)
[![GitHub commits since latest release (by SemVer including pre-releases)](https://img.shields.io/github/commits-since/Tatsh/torbrowser-launcher-mac/v0.0.1/master)](https://github.com/Tatsh/torbrowser-launcher-mac/compare/v0.0.1...master)
[![CodeQL](https://github.com/Tatsh/torbrowser-launcher-mac/actions/workflows/codeql.yml/badge.svg)](https://github.com/Tatsh/torbrowser-launcher-mac/actions/workflows/codeql.yml)
[![QA](https://github.com/Tatsh/torbrowser-launcher-mac/actions/workflows/qa.yml/badge.svg)](https://github.com/Tatsh/torbrowser-launcher-mac/actions/workflows/qa.yml)
[![Tests](https://github.com/Tatsh/torbrowser-launcher-mac/actions/workflows/tests.yml/badge.svg)](https://github.com/Tatsh/torbrowser-launcher-mac/actions/workflows/tests.yml)
[![Coverage Status](https://coveralls.io/repos/github/Tatsh/torbrowser-launcher-mac/badge.svg?branch=master)](https://coveralls.io/github/Tatsh/torbrowser-launcher-mac?branch=master)
[![GitHub Pages](https://github.com/Tatsh/torbrowser-launcher-mac/actions/workflows/pages.yml/badge.svg)](https://tatsh.github.io/torbrowser-launcher-mac/)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://github.com/pre-commit/pre-commit)
[![Stargazers](https://img.shields.io/github/stars/Tatsh/torbrowser-launcher-mac?logo=github&style=flat)](https://github.com/Tatsh/torbrowser-launcher-mac/stargazers)

[![@Tatsh](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fpublic.api.bsky.app%2Fxrpc%2Fapp.bsky.actor.getProfile%2F%3Factor%3Ddid%3Aplc%3Auq42idtvuccnmtl57nsucz72%26query%3D%24.followersCount%26style%3Dsocial%26logo%3Dbluesky%26label%3DFollow%2520%40Tatsh&query=%24.followersCount&style=social&logo=bluesky&label=Follow%20%40Tatsh)](https://bsky.app/profile/Tatsh.bsky.social)
[![Mastodon Follow](https://img.shields.io/mastodon/follow/109370961877277568?domain=hostux.social&style=social)](https://hostux.social/@Tatsh)

Tor Browser Launcher is intended to make Tor Browser easier to install and use for macOS users. You
install torbrowser-launcher from your distribution's package manager and it handles everything else:

- Downloads and installs the most recent version of Tor Browser, or launches Tor Browser if it's
  already at the latest version at launch time.

You might want to check out the [security design doc](https://github.com/micahflee/torbrowser-launcher/blob/develop/security_design.md).

![Tor Browser Launcher screenshot](/screenshot.png)

To view the settings dialogue, use a terminal and pass `--settings`:

```shell
open '/Applications/Tor Browser Launcher.app' --args --settings
```

## Troubleshooting

To start with a clean environment, run the following commands:

```sh
killall 'Tor Browser Launcher'  # or quit the app
defaults delete sh.tat.torbrowser-launcher-mac
rm -rf "${HOME}/Library/Application Support/Tor Browser Launcher"
```

Then run the launcher.
