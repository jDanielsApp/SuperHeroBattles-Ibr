# SuperHeroBattle

Native iOS superhero battle simulator built with SwiftUI, Clean Architecture, Realm and Apple Foundation Models.

## Stack

- Swift 6, SwiftUI, iOS 26.0+
- Apple Foundation Models for AI-generated combat narratives
- RealmSwift for local match history
- SuperHeroAPI as the hero data source
- XCTest for unit and UI tests
- Xcode 27.2 project format (`project.xcproj`)

## Getting started

1. Copy `SuperHeroBattle/Config/Secrets.example.xcconfig` to `SuperHeroBattle/Config/Secrets.xcconfig`.
2. Set `SUPERHERO_API_TOKEN` to your SuperHeroAPI token.
3. Open `SuperHeroBattle.xcodeproj` and run the `SuperHeroBattle` scheme.

Builds from the command line require the full Xcode toolchain:

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodebuild -project SuperHeroBattle.xcodeproj -scheme SuperHeroBattle \
  -destination 'generic/platform=iOS Simulator' build
```
