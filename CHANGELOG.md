# Changelog

## 0.3.0
- Added a universal installer for CC:Tweaked.
- Added a boot-time updater that reads manifest.txt.
- Downloads releases to a staging directory before applying them.
- Checks downloaded file sizes before replacing installed files.
- Keeps user data outside the update manifest.
- Attempts rollback if replacing a system file fails.

## Known limitations
- Not tested inside Minecraft/CC:Tweaked yet.
- Current desktop is terminal-based, not a full graphical Windows-like shell.
- Integrity validation is based on file size, not cryptographic hashes.
- This release manifest currently tracks the core system and boot/update scripts.
