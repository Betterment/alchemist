# 0.6.0

- chore: upgrade to flutter 3.7.0

# 0.6.0-dev.1

- chore: upgrade flutter to beta version (#84)

# 0.5.1

- fix: properly clear window size overrides after test run (#81)
- fix: ensure that error messages are always legible (#78)

# 0.5.0

- chore: upgrade to flutter 3.3.0

# 0.4.1

- chore: downgrade min sdk to 2.16.2

# 0.4.0

- fix: add default localizations
- refactor: move constraints to golden test group and scenario
- ci: add workflow that will upload code coverage after a merge to main
- refactor: move constraints to golden test group and scenario
- fix: fix bug where localizations were not resolved correctly due to nested `MaterialApp`s
- feat: add improved example project
- docs: update simulating gestures snippet
- chore: upgrade to very_good_analysis 3.0.0
- chore: upgrade to flutter 3.0.0
- ci: fix the title of the semantic PR job

# 0.3.3

- chore: upgrade flutter to 2.10.4
- ci: use semantic-pull-request github action over semantic-pull-requests app
- fix: use `home` instead of `builder` when `pumpWidget` in `GoldenTestAdapter.pumpGoldenTest`
- chore: fix repo links in README
- chore: update example to use builder

# 0.3.2

- feat: add `pumpWidget` callback to `goldenTest`
- feat: add scroll interaction

# 0.3.1

- feat: export test asset bundle

# 0.3.0

- chore: remove dependabot
- feat!: Improve reliability, add unit tests
- fix: CI tests fail when using CompositedTransformFollower
- ci: use codecov instead of lcov reporter
- feat: renderShadows flag
- chore: add brandon, marcos, and joanna to codeowners
- fix!: load asset images for tests
- chore: remove duplicate vgv logos
- docs: update readme

# 0.2.1

- chore: Change test version constraints and fixed documentation

# 0.2.0

- feat: Add generic interactions, including built-in interactions like `press` and `longPress`

# 0.1.0

- feat: initial version
