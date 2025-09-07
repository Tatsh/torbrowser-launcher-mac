# Contributing

## Environment

Ensure you have the following:

- macOS 11 or later
- Xcode latest supported for your version of macOS
- [`cmake-format`](https://pypi.org/project/cmakelang/) in `PATH`
- [`cmake`](https://cmake.org/) in `PATH`
- [`pre-commit`](https://pre-commit.com/)
- [`swift-format`](https://github.com/swiftlang/swift-format) in `PATH`
- [`yarn`](https://yarnpkg.com/) in `PATH`

It is best to make installations with a package manager such as [MacPorts](https://www.macports.org/)
or [Homebrew](https://brew.sh/).

### Recommended

- VS Code with extensions mentioned in [recommendations](/.vscode/extensions.json).
- [PyGitUp]

## Set up

1. Fork the repository.
1. Clone your fork.
1. Inside the cloned code, run `yarn` and `pre-commit install`.
1. Create a branch for your changes.
1. Build and install to a prefix:
   - `mkdir build`
   - `cd build`
   - `cmake -G Xcode -DBUILD_TESTS=ON "-DCMAKE_INSTALL_PREFIX=$(pwd -P)/prefix" -DCMAKE_BUILD_TYPE=Debug`
   - `cmake --build . --config Debug`
   - `cmake --install . --config Debug`
1. Open the project in Xcode: `open TorBrowserLauncher.xcodeproj`.
1. Run the application: `open 'prefix/Tor Browser Launcher.app'`.

Other generators such as Ninja are not fully supported and will not create a correct installation.

### Writing code

For general guidelines that apply to all files, refer to the general
[Copilot instructions](/.github/instructions/general.instructions.md).

If contributing new code, ensure tests are written to cover it if possible. Testable code goes in
`TorBrowserLauncherLib`, while non-testable code goes in `TorBrowserLauncher` (mostly UI code).
What is testable and not testable is not well-defined. Abstractions should be made to separate
testable and not testable code. Reference existing tests for techniques on handling `Task` blocks,
mocking, etc.

### Pulling

Always rebase and do not create merge commits. Commit or stash your changes and then use
`git rebase origin/master`. This can be made easier by using `git up` from [PyGitUp].

## Committing

### Pre-requisites

Before committing, run the following tasks and ensure all succeed.

- Format the code:

  ```shell
  yarn format
  ```

- Ensure the project builds:

  ```shell
  cmake --build build --config Debug
  ```

- Run tests:

  ```shell
  ctest -VV -C Debug TorBrowserLauncher
  ```

- Run QA checks:

  ```shell
  yarn qa
  ```

  Make sure spelling errors are resolved and new words are added to
  [`.vscode/dictionary.txt`](/.vscode/dictionary.txt).

### Messages

Use a short one-word prefix in messages in lowercase followed by a colon and then the message.
Messages should be in imperative form and generally lowercase. Examples:

- `ignore: add *.bak`
- `readme: update`
- `settings: add a setting for y`
- `tests: add a test for x`

A second part to the message can be added, as well as tags:

```plain
settings: add a setting for y

y is important for something.

Closes: #5
Link: https://www.example.com/
```

In general, do not bypass the pre-commit hooks.

[PyGitUp]: https://github.com/msiemens/PyGitUp

## API documentation

- [Application](https://tatsh.github.io/torbrowser-launcher-mac/app/documentation/tor_browser_launcher/)
- [Library](https://tatsh.github.io/torbrowser-launcher-mac/lib/documentation/torbrowserlauncherlib/)
