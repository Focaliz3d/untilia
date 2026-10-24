# Untilia

Three independent countdowns, with local start and deadline dates, time zones,
elapsed-time tracking, French and English, and portrait/landscape layouts.
The app works offline, with settings stored only on the device.

## Build

Open `Untilia.xcodeproj` and select the shared `Untilia` scheme. The app targets
iOS 17.6 or later. Select your own Apple signing team for device builds.

```sh
xcodebuild test -project Untilia.xcodeproj -scheme Untilia \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro Max' \
  -only-testing:UntiliaTests
```

`UntiliaUITests` covers paging, clock visibility, settings, calendars and help.
Run those tests separately with parallel testing disabled.

## Versioning

The About/help header reads `CFBundleShortVersionString` and `CFBundleVersion`
from the app bundle. Update `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION`
in the Xcode project before each distributed build; local compilations do not
automatically increment the build number. Disable automatic build renumbering
when uploading so the tag, archive and displayed version remain identical.

## Support and privacy

[Support and privacy policy](https://focaliz3d.github.io/untilia/) is served from
`index.html` in this repository. Preserve it when updating the app sources.
The privacy manifest declares app-local preferences (`UserDefaults`, CA92.1),
with no tracking or collected data.
