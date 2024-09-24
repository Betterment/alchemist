# 0.10.0

## What's Changed
* feat: break out smoke test goldens into directories based on flutter version by @btrautmann in https://github.com/Betterment/alchemist/pull/126
* fix: Could not override GoldenTestTheme by @Brainyoo in https://github.com/Betterment/alchemist/pull/127
* ci: channel compatibility workflow by @btrautmann in https://github.com/Betterment/alchemist/pull/123


**Full Changelog**: https://github.com/Betterment/alchemist/compare/v0.9.0...v0.10.0

# 0.9.0

## What's Changed
* feat: `GoldenTestTheme` by @btrautmann in https://github.com/Betterment/alchemist/pull/124


**Full Changelog**: https://github.com/Betterment/alchemist/compare/v0.8.0...v0.9.0

# 0.8.0

## What's Changed
* docs: fix readme relative link (Separate local & CI tests) by @FirentisTFW in https://github.com/Betterment/alchemist/pull/100
* docs: fix a small typo under RECOMMENDED_SETUP_GUIDE.md by @pedromassango in https://github.com/Betterment/alchemist/pull/116
* fix: loading fonts from other packages by @krispypen in https://github.com/Betterment/alchemist/pull/111
* feat: allow updating goldens on CI by @btrautmann in https://github.com/Betterment/alchemist/pull/121
* chore: bump flutter/dart min sdk constraints by @btrautmann in https://github.com/Betterment/alchemist/pull/118

## New Contributors
* @FirentisTFW made their first contribution in https://github.com/Betterment/alchemist/pull/100
* @pedromassango made their first contribution in https://github.com/Betterment/alchemist/pull/116
* @krispypen made their first contribution in https://github.com/Betterment/alchemist/pull/111

**Full Changelog**: https://github.com/Betterment/alchemist/compare/v0.7.0...v0.8.0

# 0.7.0
- fix: upgrade to flutter 3.13 (#95)
- fix: render objects not rendering text (#98)

# 0.6.1

- fix: dialogs and dropdown menus not being displayed correctly

# 0.6.0

- chore: upgrade to flutter 3.7.0 (#87)

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
