# Contributing to Alchemist

Thanks for checking out `alchemist`! Your contributions are greatly appreciated 🎉. 
The following guidelines should get you started out on your path towards contribution.

## Creating a Bug Report

If you've found a bug, [create an issue using the bug report template][bug_report_template] rather than immediately opening a pull request. This allows us to triage the issue as necessary and discuss potential solutions. Please try to provide as much information as possible, including detailed reproduction steps. Once one of the package maintainers has reviewed the issue and an agreement is reached regarding the fix, a pull request can be created.

## Creating a Feature Request

Use the built-in [Feature Request template][feature_request_template] to add in any relevant details with your request. Once one of the package maintainers has reviewed the issue and triaged it, a pull request can be created.

## Creating a Pull Request

Before creating a pull request please:

1. Fork the repository and create your branch from `main`.
2. Install all dependencies (`flutter pub get`).
3. Make your changes.
4. Add tests — only PR's with 100% test coverage are accepted!
5. Ensure the existing test suite passes locally.
6. Format your code (`dart format .`).
7. Analyze your code (`dart analyze --fatal-infos --fatal-warnings .`).
8. Create the Pull Request with [semantic title](https://github.com/zeke/semantic-pull-requests).
9. Verify that all status checks are passing.

## License

This packages uses the [MIT license](https://github.com/Betterment/alchemist/blob/main/LICENSE)

[bug_report_template]:  https://github.com/Betterment/alchemist/issues/new?assignees=&labels=&template=bug_report.yaml
[feature_request_template]:  https://github.com/Betterment/alchemist/issues/new?assignees=&labels=&template=feature_request.yaml
