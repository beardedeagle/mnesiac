# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [[0.4.0]] - 2019-04-02
### Added
- Ability to specify how many copies of schema can exist, by type.
- Ability to specify how many copies of a store can exist, per store by type.
- Ability to blacklist nodes, per store.
- `init_migration/1` and `rollback_migration/1` overridable callbacks in `Mnesiac.Store`.
- Structs for explicit config and store contracts.
- Specs for explicit library contracts.
- Escape hatch of sorts, which allows you to override the base Mnesiac configuration struct.

### Removed
- Removed `Mnesiac.StoreManager` module.
- Config directory. Configuration is now to be passed in directly.

## Changed
- `resolve_conflict/1` -> `resolve_conflict/2`, now accepts configuration.
- Standardized terminology in library.
- Bumped OTP version.
- Updated dependencies.

### Fixed
- More docs cleanup.

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

[0.4.0]: https://github.com/beardedeagle/mnesiac/compare/v0.3.3...v0.4.0
[0.3.3]: https://github.com/beardedeagle/mnesiac/compare/v0.3.2...v0.3.3
[0.3.2]: https://github.com/beardedeagle/mnesiac/compare/v0.3.1...v0.3.2
[0.3.1]: https://github.com/beardedeagle/mnesiac/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/beardedeagle/mnesiac/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/beardedeagle/mnesiac/compare/v0.1.0...v0.2.0
