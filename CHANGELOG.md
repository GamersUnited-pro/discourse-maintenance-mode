# Changelog

## v1.0.31 - 2025-08-23
### New Features
- Added `CHANGELOG.md` to track plugin updates.
- Added ability to configure **allowed paths** via Admin → Settings → Plugins.
- Added ability to configure **exempt groups** via Admin → Settings → Plugins.

### Bug Fixes
- Fixed `allowed_paths` being interpreted as a **string** instead of a **list** (`plugin.rb`).
- Fixed plugin being enabled/disabled when using the maintenance mode toggle
