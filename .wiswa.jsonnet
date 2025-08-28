(import 'defaults.libjsonnet') + {
  // Shared
  github_username: 'Tatsh',
  authors: [
    {
      'family-names': 'Udvare',
      'given-names': 'Andrew',
      email: 'audvare@gmail.com',
      name: '%s %s' % [self['given-names'], self['family-names']],
    },
  ],
  project_name: 'torbrowser-launcher-mac',
  version: '0.0.0',
  description: 'TorBrowser Launcher for macOS, inspired by the Linux version.',
  keywords: ['macos', 'package manager', 'tor'],
  copilot: {
    intro: 'torbrowser-launcher-mac is a tool for getting the latest TorBrowser and launching it, modeled on the Linux version.',
  },
  social+: {
    mastodon+: { id: '109370961877277568' },
  },

  // GitHub
  github+: {
    funding+: {
      ko_fi: 'tatsh2',
      liberapay: 'tatsh2',
      patreon: 'tatsh2',
    },
  },

  project_type: 'swift',
}
