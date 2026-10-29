# Venera (Maintained Fork)

[![Flutter](https://img.shields.io/badge/flutter-3.41.4-blue)](https://flutter.dev/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Upstream](https://img.shields.io/badge/fork%20of-venera--app%2Fvenera-orange)](https://github.com/venera-app/venera)

A high-performance, cross-platform comic reader supporting local files and dynamic network sources, built with **Flutter** and **Rust**.

This repository is an actively maintained fork of [venera-app/venera](https://github.com/venera-app/venera) (the next-generation successor to [PicaComic](https://github.com/wgh136/PicaComic)).

---

## What We Improved in this Fork

This fork modernizes the application architecture, decomposes monolithic files into modular components, eliminates technical debt, and introduces an automated testing suite:

### 1. Strongly Typed Settings Architecture
* **Modular Configuration**: Decoupled settings management out of `appdata.dart` into a dedicated, strongly-typed [`settings.dart`](lib/foundation/settings.dart).
* **Compile-Time Safety**: Added typed getters and setters for UI, Reader, Network, Storage, and Sync settings while preserving 100% backward compatibility for index-based access (`settings['key']`).
* **Granular Overrides**: Cleaned up device-specific and comic-specific reader override logic.

### 2. Elimination of `GlobalState` Anti-Pattern
* **Reactive State Management**: Removed the static raw `State<T>` pointer registry across the application.
* **Flutter-Idiomatic Patterns**:
  - Replaced manual state lookups in `follow_updates_page.dart` with reactive `ChangeNotifier` events.
  - Replaced cross-tab lookups in `explore_page.dart` with standard Flutter `GlobalKey` references.
  - Replaced reader gesture lookups in `comic_image.dart` with scoped context hierarchy access.
  - Prevented potential cross-widget memory leaks upon disposal.

### 3. Decomposed Monolithic Codebases
* **UI Components**: Decomposed the monolithic 1,710-line `comic.dart` into single-responsibility modules:
  - `comic.dart` &mdash; Dedicated comic card, tile, and history badge presentation.
  - `sliver_grid_comics.dart` &mdash; Responsive sliver grid layout and keyword blocking filters.
  - `comic_list.dart` &mdash; Paginated list container with pull-to-refresh and infinite scroll state.
  - `star_rating.dart` &mdash; Independent rating stars and interactive modal rating widget.
* **JS Engine Parser**: Decomposed the 1,301-line `parser.dart` into focused domain extensions:
  - `parser.dart` &mdash; Core parser lifecycle, semver comparison, manifest & key validation.
  - `parser_explore_category.dart` &mdash; Explore feeds, taxonomy, and category comic loaders.
  - `parser_search_favorites.dart` &mdash; Keyword search, account auth, and cloud favorite folders.
  - `parser_comic_details.dart` &mdash; Comic details, reader images, thumbnail decoders, and comments.

### 4. Unit Testing Suite
* Added unit test suites under `test/`:
  - `settings_test.dart` &mdash; Validates default values, typed accessors, reactive updates, device ID generation, and reader overrides.
  - `semver_test.dart` &mdash; Validates semver comparison and hotfix precedence rules.

### 5. Extended Custom Comic Sources
* Support for modular JavaScript comic source extensions running on an embedded QuickJS engine.
* Added Next.js-based reader parser implementation (`yiff_comics.js`).

---

## Features

- **Local Reading**: Read local folders, ZIP/CBZ archives, and image collections.
- **Dynamic JavaScript Comic Sources**: Add, write, or update comic sources via JavaScript without recompiling the app.
- **Native Performance**: Rust-powered async networking (`rhttp` / Reqwest) and image decoding (`lodepng_flutter`, `flutter_7zip`).
- **Offline Downloads & Sync**: Download comics for offline reading; sync history and favorites across devices via WebDAV.
- **Interactive Reader**: Left-to-Right, Right-to-Left, and continuous vertical webtoon scroll modes.
- **Headless Mode**: Server/CLI automation mode for scraping or downloading.

---

## Build from Source

### Prerequisites
1. **Flutter SDK** (>= 3.24 / 3.41): [flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install)
2. **Rust Toolchain** (>= 1.85): [rustup.rs](https://rustup.rs/)

### Steps
```bash
# 1. Clone your fork
git clone https://github.com/wieserd/venera.git
cd venera

# 2. Get dependencies
flutter pub get

# 3. Run unit tests
flutter test

# 4. Run or build for your platform
flutter run -d macos    # macOS Desktop
flutter build apk       # Android APK
flutter build windows   # Windows Desktop
```

---

## Documentation

* [Writing a Comic Source](doc/comic_source.md)
* [JavaScript Runtime API](doc/js_api.md)
* [Headless Mode Guide](doc/headless_doc.md)

---

## Upstream & Acknowledgements

* **Upstream Project**: [venera-app/venera](https://github.com/venera-app/venera) & [wgh136/PicaComic](https://github.com/wgh136/PicaComic)
* **Tag Translations**: [EhTagTranslation Database](https://github.com/EhTagTranslation/Database)
* **License**: [MIT License](LICENSE)
