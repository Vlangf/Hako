<p align="center">
  <img src="Resources/hako_logo.png" alt="Hako" width="200">
</p>

<p align="center">A modern clipboard manager for macOS, built with SwiftUI and SwiftData.</p>

This project is a fork of [Clipy](https://github.com/Clipy/Clipy), fully modernized for macOS 15+.

---

## Features

- Clipboard history with configurable size
- Snippet management with folders and drag-and-drop
- Global keyboard shortcuts (customizable)
- Inline and folder-based menu layouts
- Image and color code preview in menu
- Application exclusion list
- Screenshot observation
- Localized: English, Japanese, German, Italian, Chinese (Simplified)

## What's Changed from Clipy

| Area | Before (Clipy) | After (Hako) |
|------|----------------|--------------|
| Data | Realm | SwiftData |
| Reactivity | RxSwift | Combine |
| DI | AppEnvironment stack | @Observable AppState |
| Preferences | AppKit XIBs | SwiftUI TabView |
| Logging | Fabric/Crashlytics | os.Logger |
| Tests | Quick/Nimble | Swift Testing |
| Caching | PINCache | Custom ImageCache |
| Screenshots | RxScreeen | NSMetadataQuery |
| Dependencies | CocoaPods | Swift Package Manager |
| Target | macOS 10.10+ / Swift 4 | macOS 15+ / Swift 5.9+ |
| Architecture | Apple Silicon only (arm64) | |

## Requirements

- macOS 15.0 (Sequoia) or later
- Apple Silicon Mac

## How to Build

1. Clone the repository
2. Open `Hako.xcodeproj` in Xcode 16+
3. Wait for SPM packages to resolve
4. Build and run (Cmd+R)

## Dependencies (SPM)

- [Magnet](https://github.com/Clipy/Magnet) — Global keyboard shortcuts
- [KeyHolder](https://github.com/Clipy/KeyHolder) — Shortcut recording UI
- [Sauce](https://github.com/Clipy/Sauce) — Key code utilities

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

Hako is available under the MIT license. See the [LICENSE](LICENSE) file for details.

Based on [Clipy](https://github.com/Clipy/Clipy) — Copyright (c) 2015-2018 Clipy Project.

Icons are copyrighted by their respective authors.

## Special Thanks

- [@naotaka](https://github.com/naotaka) for publishing [ClipMenu](https://github.com/naotaka/ClipMenu) as OSS
- [Clipy Project](https://github.com/Clipy) for the original clipboard manager
