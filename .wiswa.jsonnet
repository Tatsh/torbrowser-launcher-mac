{
  uses_user_defaults: true,
  project_name: 'torbrowser-launcher-mac',
  version: '0.1.0',
  security_policy_supported_versions: { '0.1.x': ':white_check_mark:' },
  description: 'Tor Browser Launcher for macOS, inspired by the Linux version.',
  keywords: ['macos', 'package manager', 'tor'],
  want_codeql: false,
  want_tests: false,
  project_type: 'swift',
  gitignore+: [
    '*.profraw',
    '.DS_Store',
  ],
  prettierignore+: [
    '*.strings',
    '*.swift',
  ],
  package_json+: {
    cspell+: {
      ignorePaths+: [
        '*.pbxproj',
        '*.xc*',
        '*.xib',
        '.yarn/**/*.cjs',
      ],
    },
    prettier+: {
      overrides+: [
        {
          files: ['.swift-format'],
          options: {
            parser: 'json',
          },
        },
        {
          files: ['*.plist', '*.plist.in'],
          options: {
            parser: 'xml',
          },
        },
      ],
    },
    scripts+: {
      build: 'cmake --preset=default && cmake --build build',
      'check-formatting': "swift-format lint -r . && prettier -c . && markdownlint-cli2 --config package.json --configPointer /markdownlint-cli2 '**/*.md' '#node_modules'",
      'check-spelling': "cspell --no-progress './**/*'  './**/.*'",
      format: "swift-format -i -r . && prettier -w . && markdownlint-cli2 --config package.json --configPointer /markdownlint-cli2 --fix '**/*.md' '#node_modules'",
      qa: 'yarn check-spelling && yarn check-formatting',
    },
  },
  vscode+: {
    extensions+: {
      recommendations+: [
        'swiftlang.swift-vscode',
        'vknabel.vscode-apple-swift-format',
        'vadimcn.vscode-lldb',
      ],
    },
    launch+: {
      configurations: [
        {
          args: [
            '-XCTest',
            'TorBrowserLauncherTests.DownloaderTest/testInvalidBinaryURI',
            '${workspaceFolder}/build/TorBrowserLauncherTests/Debug/TorBrowserLauncherTests.xctest',
          ],
          name: 'Debug Test',
          program: '/Applications/Xcode.app/Contents/Developer/usr/bin/xctest',
          request: 'launch',
          type: 'lldb',
        },
      ],
    },
    settings+: {
      '[swift]': {
        'editor.defaultFormatter': 'vknabel.vscode-apple-swift-format',
        'editor.tabSize': 4,
      },
    },
  },
  cz+: {
    commitizen+: {
      version_files+: [
        'CMakeLists.txt',
      ],
    },
  },
}
