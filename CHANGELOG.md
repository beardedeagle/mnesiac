# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [[0.4.0]] - 2021-08-01
### Added
- Ability to specify how many copies of schema can exist, by type.
- Ability to specify how many copies of a store can exist, per store by type.
- Ability to blacklist Mnesia cluster nodes, per store.
- `init_schema/1`, `copy_schema/2`, `refresh_cluster/1` overridable callbacks in `Mnesiac.Store`.
- Structs for explicit config and store contracts.
- Specs for explicit library contracts.
- Escape hatch of sorts, which allows you to override the base Mnesiac configuration struct.
- `Mnesiac.validate_config/2` which can be used to validate the configuration being passed in to Mnesiac, possible to test override functions too.

### Removed
- Removed `Mnesiac.StoreManager` module.
- Removed config directory. Configuration is now to be passed in directly.

### Changed
- `resolve_conflict/1` -> `resolve_conflict/2`, now accepts configuration.
- Standardized terminology in library.
- Improved Travis CI jobs.
- Bumped OTP and Elixir version.
- Updated dependencies.

### Fixed
- More docs cleanup.

## [[0.3.9]] - 2021-02-21
### Changed
- Bumped OTP version.
- Bumped Elixir version.
- Updated Travis CI integration for new OTP release.
- Updated dependencies.
- Updated GitHub repo files.

## [[0.3.8]] - 2020-09-01
### Changed
- Moved `:mnesia` out of `extra_applications` into `included_applications`.
- Bumped OTP version.
- Updated Travis CI integration for new OTP release.
- Updated dependencies.
- Updated GitHub repo files.

## [[0.3.7]] - 2020-07-17
### Changed
- Bumped OTP version.
- Bumped Elixir version.
- Updated Travis CI integration for new OTP and Elixir releases.
- Updated dependencies.
- Updated GitHub repo files.

## [[0.3.6]] - 2020-03-01
### Added
- Additional GitHub repo files.

### Changed
- Bumped OTP version.
- Fixed Travis CI integration.

## [[0.3.5]] - 2020-02-27
### Changed
- Bumped OTP version.
- Bumped Elixir version.
- Updated dependencies.

## [[0.3.4]] - 2019-08-20
### Fixed
- Logger crashes in `Mnesiac` module.
- copy_table bug, closes #20.

### Changed
- Bumped OTP version.
- Bumped Elixir version.
- Updated dependencies.

## [[0.3.3]] - 2019-02-25
### Fixed
- Apply regression fix to `copy_store/0` and `resolve_conflict/1`.
- Docs cleanup.

## [[0.3.2]] - 2019-02-22
### Fixed
- Regression that made defining a custom store name impossible.

## [[0.3.1]] - 2019-02-21
### Added
- Inch reports.

### Fixed
- Misc docs.

## [[0.3.0]] - 2019-02-14
### Added
- Distributed testing suite.
- Implemented store as a macro, with overridable callbacks.

### Changed
- Bumped OTP version.
- Bumped Elixir version.
- Updated dependencies.
- Started using keepachangelog.com changelog format.
- Hex doc improvements.
- Travis CI improvements.

## [[0.2.0]] - 2018-07-30
### Added
- Additional tests.
- Created .github folder and files.
- Created badge links.
- Created dev and test instructions.

## [0.1.0] - 2018-07-29
### Added
- Initial release.

[0.4.0]: https://github.com/beardedeagle/mnesiac/compare/v0.3.9...v0.4.0
[0.3.9]: https://github.com/beardedeagle/mnesiac/compare/v0.3.8...v0.3.9
[0.3.8]: https://github.com/beardedeagle/mnesiac/compare/v0.3.7...v0.3.8
[0.3.7]: https://github.com/beardedeagle/mnesiac/compare/v0.3.6...v0.3.7
[0.3.6]: https://github.com/beardedeagle/mnesiac/compare/v0.3.5...v0.3.6
[0.3.5]: https://github.com/beardedeagle/mnesiac/compare/v0.3.4...v0.3.5
[0.3.4]: https://github.com/beardedeagle/mnesiac/compare/v0.3.3...v0.3.4
[0.3.3]: https://github.com/beardedeagle/mnesiac/compare/v0.3.2...v0.3.3
[0.3.2]: https://github.com/beardedeagle/mnesiac/compare/v0.3.1...v0.3.2
[0.3.1]: https://github.com/beardedeagle/mnesiac/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/beardedeagle/mnesiac/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/beardedeagle/mnesiac/compare/v0.1.0...v0.2.0
