# Change log
Record of the modification in project development.

## [Unreleased] - yyyy-mm-dd
### Added
### Changed
### Deprecated
### Removed
### Fixed
### Known Issue

## [1.3.1] - 2023-04-15
### Added
### Changed
### Deprecated
### Removed
### Fixed
- [Issue 43 : Partition names should be prefixed by "p" for NVMe](https://github.com/suikan4github/kaiten-yaki/pull/43). Thank you Uraza for your contribution. 
### Known Issue

## [1.3.0] - 2022-05-15
### Added
- [Issue 31 : Add extra partition functionality.](https://github.com/suikan4github/kaiten-yaki/issues/31)
- [Issue 33 : Support "M/G/T" as size prefix.](https://github.com/suikan4github/kaiten-yaki/issues/33)

### Changed
- [Issue 38 : "Ready to reboot" message should be changed](https://github.com/suikan4github/kaiten-yaki/issues/38)
- [Issue 39 : Change message style](https://github.com/suikan4github/kaiten-yaki/issues/39)

### Deprecated
- [Issue 34 : BIOS support should be obsoleted ](https://github.com/suikan4github/kaiten-yaki/issues/34)

### Removed
- [Issue 35 : Remove XTERMFONTSIZE variable.](https://github.com/suikan4github/kaiten-yaki/issues/35)

### Fixed
- [Issue 32 : Ubuntu 22.04 fails to deactivate the swap](https://github.com/suikan4github/kaiten-yaki/issues/32)
- [Issue 36 : Clear the PASSPHRASE variable at the end of installation](https://github.com/suikan4github/kaiten-yaki/issues/36)

### Known Issue

## [1.2.0] - 2021-10-16
### Added
### Changed
- [Issue 25 : Refactoring: Sourcing config.sys is not needed in the chrooted_job](https://github.com/suikan4github/kaiten-yaki/issues/25)
- [Issue 26 : Update AN01 for btrfs](https://github.com/suikan4github/kaiten-yaki/issues/26)
- [Issue 27 : Eliminates the confirmation dialog](https://github.com/suikan4github/kaiten-yaki/issues/27)

### Deprecated
### Removed
- [Issue 28 : Move application notes to Wiki](https://github.com/suikan4github/kaiten-yaki/issues/28)

### Fixed
- [Issue 24 : Fail to install the ubuntu when the / volume is btrfs](https://github.com/suikan4github/kaiten-yaki/issues/24)
- [Issue 29 : Item should be added to /etc/dracut.conf.d/10-crypt.conf , rather than be overwritten](https://github.com/suikan4github/kaiten-yaki/issues/29)

### Known Issue

## [1.1.0] - 2021-07-11
Added ITERTIME parameter and corrected other small issues. Application notes AN01 - AN04 are added. 
The Followings are tested distributions 
- Ubuntu 20.04.2
- Ubuntu MATE 20.04.2
- Ubuntu 21.04
- Void Linux glibc 20210218 mate
- Void Linux musl 20210218 mate
- Void Linux glibc 20210218 base

See [Testing before release v1.1.0](https://github.com/suikan4github/kaiten-yaki/issues/16).
### Added
- [Issue 13 : Add ITERTIME configuration parameter to config.txt](https://github.com/suikan4github/kaiten-yaki/issues/13)
- [Issue 18 : Add a consideration of the number of key slot](https://github.com/suikan4github/kaiten-yaki/issues/18)
- [Issue 19 : Add a consideration of more flexible partitioning](https://github.com/suikan4github/kaiten-yaki/issues/19)
- [Issue 20 : Add a consideration of LUKS stretching](https://github.com/suikan4github/kaiten-yaki/issues/20)
- [Issue 21 : Add a document of how to recover from the mistyping of passphrase](https://github.com/suikan4github/kaiten-yaki/issues/21)

### Changed
- [Issue 5 : OVERWRITEINSTALL confirmation is missing](https://github.com/suikan4github/kaiten-yaki/issues/5)
- [Issue 6 : Remove loglevel dependency from the void-kaiten-yaki.sh ](https://github.com/suikan4github/kaiten-yaki/6)
- [Issue 7 : Add the return status validation ](https://github.com/suikan4github/kaiten-yaki/7)
- [Issue 11 : Make chroot'ed job independent script file ](https://github.com/suikan4github/kaiten-yaki/11)
- [Issue 12 : change ERASEALL=0 as default ](https://github.com/suikan4github/kaiten-yaki/12)
- [Issue 14 : Change config.sh description ](https://github.com/suikan4github/kaiten-yaki/14)

### Deprecated
### Removed
### Fixed
- [Issue 8 : Wrong message after cancellation ](https://github.com/suikan4github/kaiten-yaki/8)
- [Issue 15 : CITERTIME parameter is not passed to the chrooted_job ](https://github.com/suikan4github/kaiten-yaki/15)
- [Issue 17 : Unmount fails ](https://github.com/suikan4github/kaiten-yaki/17)

### Known Issue

## [1.0.0] - 2021-07-03

### Added
- [Issue 1 : Support non-GUI install for Void Linux.](https://github.com/suikan4github/kaiten-yaki/issues/1)

### Changed
### Deprecated
### Removed
### Fixed
### Security
### Known Issue


[Unreleased]: https://github.com/suikan4github/kaiten-yaki/compare/v1.3.0...develop
[1.3.1]: https://github.com/suikan4github/kaiten-yaki/compare/v1.3.0...v1.3.1
[1.3.0]: https://github.com/suikan4github/kaiten-yaki/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/suikan4github/kaiten-yaki/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/suikan4github/kaiten-yaki/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/suikan4github/kaiten-yaki/compare/v0.0.0...v1.0.0
