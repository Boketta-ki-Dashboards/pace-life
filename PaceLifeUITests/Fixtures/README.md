# Native photo-picker test fixture

`chapter-photo.png` is a synthetic 160 × 100 RGB checkerboard: alternating
20-pixel squares with RGB (68, 88, 103) and (181, 224, 208). It has no camera,
location or personal metadata. It is a test input, not an app screenshot or a
design reference.

`scripts/test-ios.sh` adds it to the selected simulator Photos library before
photo/full UI tests. Existing photos are never deleted. The UI test uses the
native picker, cancels once, imports a photo, relaunches the app, removes the
chapter attachment, then relaunches again. Its AppModel store is isolated using
`PACE_UI_TEST_SESSION`; the user's normal app data is not changed.

For tests started directly in Xcode, first add this fixture to the selected
simulator with `xcrun simctl addmedia <simulator-udid> PaceLifeUITests/Fixtures/chapter-photo.png`.
