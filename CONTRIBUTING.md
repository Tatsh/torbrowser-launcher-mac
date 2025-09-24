# How to contribute to torbrowser-launcher-mac

Thank you for your interest in contributing to torbrowser-launcher-mac! Please follow these
guidelines to help maintain code quality and consistency.

## General Guidelines

- Follow the coding standards and rules described below for each file type.
- Ensure all code passes linting and tests before submitting a pull request.
- Write clear commit messages and document your changes in the changelog if relevant.
- Contributors are listed in `package.json`.
- Update relevant fields in `.wiswa.jsonnet` such as authors, dependencies, etc.
- All contributed code must have a license compatible with the project's license (MIT).
- Add missing words to `.vscode/dictionary.txt` as necessary (sorted and lower-cased).

## Development Environment

- macOS 11 or later
- Xcode latest supported for your version of macOS
- [`cmake-format`](https://pypi.org/project/cmakelang/) in `PATH`
- [`cmake`](https://cmake.org/) in `PATH`
- [`pre-commit`](https://pre-commit.com/)
- [`swift-format`](https://github.com/swiftlang/swift-format) in `PATH`
- Use [Yarn](https://yarnpkg.com/) to install Node.js based dependencies:
  - Install Node.js dependencies: `yarn`
- Install [pre-commit](https://pre-commit.com/) and make sure it is enabled by running
  `pre-commit install` in the repository checkout.

It is best to make installations with a package manager such as [MacPorts](https://www.macports.org/)
or [Homebrew](https://brew.sh/).

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

## Quality Assurance & Scripts

The following scripts are available via `yarn` (see `package.json`):

- `yarn qa`: Run all QA checks (type checking, linting, spelling, formatting).
- `yarn check-formatting`: Check code formatting.
- `yarn format`: Auto-format code.
- `yarn check-spelling`: Run spell checker.

The above all need to pass for any code changes to be accepted.

## Writing code

If contributing new code, ensure tests are written to cover it if possible. Testable code goes in
`TorBrowserLauncherLib`, while non-testable code goes in `TorBrowserLauncher` (mostly UI code).
What is testable and not testable is not well-defined. Abstractions should be made to separate
testable and not testable code. Reference existing tests for techniques on handling `Task` blocks,
mocking, etc.

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

## Pulling

Always rebase and do not create merge commits. Commit or stash your changes and then use
`git rebase origin/master`. This can be made easier by using `git up` from [PyGitUp].

## Markdown Guidelines

- `<kbd>` tags are allowed.
- Headers do not have to be unique if in different sections.
- Line length rules do not apply to code blocks.
- See [Markdown instructions] for more.

## JSON, YAML, TOML, INI Guidelines

- JSON and YAML files should generally be recursively sorted by key.
- In TOML/INI, `=` must be surrounded by a single space on both sides.
- See [JSON/YAML guidelines] and [TOML/INI guidelines] for more details.

## Submitting Changes

Do not submit PRs solely for dependency bumps. Dependency bumps are either handled by running Wiswa
locally or allowing Dependabot to do them.

1. Fork the repository and create your branch from `master`.
2. Ensure your code follows the above guidelines.
3. Run all tests (`yarn test`) and QA scripts (`yarn qa`). Be certain pre-commit runs on your
   commits.
4. Submit a pull request with a clear description of your changes.

[Markdown instructions]: .github/instructions/markdown.instructions.md
[JSON/YAML guidelines]: .github/instructions/json-yaml.instructions.md
[TOML/INI guidelines]: .github/instructions/toml-ini.instructions.md
