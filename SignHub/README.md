# SignHub - iOS IPA Library, Signer & Installer

![iOS 16+](https://img.shields.io/badge/iOS-16.0%2B-blue?style=flat-square&logo=apple)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange?style=flat-square&logo=swift)
![Xcode 15+](https://img.shields.io/badge/Xcode-15.0%2B-blueviolet?style=flat-square&logo=xcode)
![License MIT](https://img.shields.io/badge/License-MIT-green?style=flat-square)

**SignHub** is an on-device iOS & iPadOS application library, code signer, and wireless installer designed in the spirit of GBox, E-Sign, and K-Sign. Built natively using SwiftUI, Swift Concurrency (`async`/`await`), and Swift 5.9+, SignHub delivers an Apple-native experience with responsive layouts for iPhone and iPad, an embedded local HTTPS server for wireless OTA installations, and a dual code signing pipeline wrapping both `zsign` (C++) and a native Swift Mach-O engine.

---

## Architecture Overview

```
                      ┌──────────────────────────────────────────────┐
                      │                 SignHub App                  │
                      │  (SwiftUI + MVVM + Swift Concurrency + async) │
                      └──────────────────────┬───────────────────────┘
                                             │
      ┌──────────────────┬───────────────────┼───────────────────┬──────────────────┐
      ▼                  ▼                   ▼                   ▼                  ▼
┌───────────┐      ┌───────────┐       ┌───────────┐       ┌───────────┐      ┌───────────┐
│   Apps    │      │  Sources  │       │   Files   │       │ Downloads │      │ Settings  │
│  Library  │      │ Repos     │       │ Documents │       │ Queue & BG│      │ & Certs   │
└─────┬─────┘      └─────┬─────┘       └─────┬─────┘       └─────┬─────┘      └─────┬─────┘
      │                  │                   │                   │                  │
      │                  ▼                   ▼                   │                  ▼
      │          ┌──────────────┐     ┌──────────────┐           │          ┌──────────────┐
      │          │ JSON Parsers │     │ IPA Inspector│           │          │ Keychain     │
      │          │AltStore/Scarl│     │Mach-O/Plist  │           │          │ & Biometrics │
      │          └──────────────┘     └──────┬───────┘           │          └──────┬───────┘
      │                                      │                   │                 │
      └──────────────────────────────────────┼───────────────────┘                 │
                                             ▼                                     ▼
                              ┌─────────────────────────────┐         ┌────────────────────────┐
                              │     Signing Orchestrator    │         │  Certificate Manager   │
                              │  - Info.plist Customizer    │◄────────┤  - P12 PKCS#12 Parser  │
                              │  - Mach-O Dylib Injector    │         │  - Provisioning CMS    │
                              │  - zsign C++ Bridge / Swift │         │  - UDID & Expiry Watch │
                              └──────────────┬──────────────┘         └────────────────────────┘
                                             │
                                             ▼
                              ┌─────────────────────────────┐
                              │     Installation Engine     │
                              │  - Network.framework HTTPS  │
                              │  - manifest.plist Generator │
                              │  - itms-services:// OTA     │
                              └─────────────────────────────┘
```

---

## Table of Contents
1. [Core Features](#core-features)
2. [Project Structure](#project-structure)
3. [Design System & UI Components](#design-system--ui-components)
4. [Subsystem Architecture](#subsystem-architecture)
   - [Code Signing Pipeline](#1-code-signing-pipeline-zsign--native-swift)
   - [Mach-O Dylib Injection](#2-mach-o-dylib-injection)
   - [Wireless Installation Engine](#3-wireless-installation-engine)
   - [Repository Normalization Engine](#4-repository-normalization-engine)
   - [Background Download Sessions](#5-background-download-sessions)
   - [Certificate Expiry Tracking & Notifications](#6-certificate-expiry-tracking--notifications)
5. [Known iOS Limitations & Constraints](#known-ios-limitations--constraints)
6. [Info.plist Keys & Entitlements](#infoplist-keys--entitlements)
7. [Step-by-Step Build & Run Guide](#step-by-step-build--run-guide)
8. [Unit Testing Suite](#unit-testing-suite)

---

## Core Features

- **App Repository Ecosystem**:
  - Direct integration with AltStore format v1 repositories.
  - Full compatibility with Scarlet format (`ITEMS` and `META` JSON schemas).
  - Add repos via URL or built-in live camera QR code scanner.
  - Pull-to-refresh, repository re-ordering, search, and categorization.
- **Background Downloads Engine**:
  - Managed background `URLSession` downloads with automatic resumption.
  - Real-time download speed calculation and dynamic progress rings.
  - Direct URL import to queue custom `.ipa` links.
- **Local File Management & IPA Inspection**:
  - Integrated Documents manager with swipe actions (Sign, Share, Rename, Delete).
  - Multi-select edit mode with batch operations.
  - Built-in IPA Inspector: inspects `Info.plist`, embedded entitlements, architectures, minimum iOS, and checks for FairPlay DRM encryption.
- **Enterprise & Developer Certificate Management**:
  - Secure import of `.p12` and `.mobileprovision` certificate pairs.
  - Hardware Keychain storage for passwords (passwords are never saved in plain text).
  - Inspection of Team Name, Team ID, Common Name, SHA-1 fingerprint, serial number, and UDID device lists.
  - Status indicator badges: Valid (Green), Expiring Soon (Amber, <30 days), Expired (Red).
  - Multiple certificates supported with quick default switcher.
- **Customizable Code Signing**:
  - Change application display name, bundle identifier, version, and build number.
  - Custom app icon selection directly from Photos or Files.
  - Dynamic library (`.dylib`) and `.framework` injection directly into Mach-O binaries (`LC_LOAD_DYLIB`).
  - Automatic removal of `PlugIns/` app extensions to prevent profile mismatch crashes.
  - Removal of `UISupportedDevices` to allow running restricted apps on iPad or non-whitelisted devices.
  - Enable iTunes File Sharing (`UIFileSharingEnabled` & `LSSupportsOpeningDocumentsInPlace`).
  - Enable iPad Multitasking and Fullscreen (`UIRequiresFullScreen = false`).
  - Real-time streaming log console during code signing.
- **Wireless Installation (OTA)**:
  - Zero-dependency local secure server powered by `Network.framework` (`NWListener`).
  - Generates signed Apple wireless app installation manifests (`manifest.plist`).
  - Launches native `itms-services://?action=download-manifest&url=...` scheme for on-device installation.
  - Step-by-step progress sheet with troubleshooting diagnostics.
- **Signed Apps Tracker & Background Refresh**:
  - Dedicated tracker monitoring signed applications and remaining days before expiry.
  - One-tap re-sign action using default certificate.
  - Local push notifications scheduled at 7 days, 3 days, 1 day, and 2 hours before expiration.
  - `BGTaskScheduler` background task registration (`com.signhub.refresh`).
- **Security & Convenience**:
  - Biometric App Lock via Face ID / Touch ID (`LocalAuthentication`).
  - AES-GCM-256 encrypted backups of sources, certificates, and preferences (`.signhubbackup`).
  - Full localization support: English (`en`) and Arabic (`ar` with RTL layout support).

---

## Project Structure

```
SignHub/
├── SignHub.xcodeproj/
│   └── project.pbxproj               # Complete Xcode 15 project configuration
├── SignHub/
│   ├── App/
│   │   ├── SignHubApp.swift          # Main entrypoint, scene lifecycle, background task
│   │   ├── RootView.swift            # Adaptive container, Face ID lock overlay, toasts
│   │   ├── AppState.swift            # Central observable state and theming
│   │   ├── TabNavigation.swift       # iPhone floating pill tab bar
│   │   └── SidebarNavigation.swift   # iPad adaptive NavigationSplitView sidebar
│   ├── Models/
│   │   ├── AppModel.swift            # Application item from repos / local
│   │   ├── SourceModel.swift         # AltStore / Scarlet repository model
│   │   ├── CertificateModel.swift    # P12 and mobileprovision certificate model
│   │   ├── DownloadItem.swift        # Background download queue task
│   │   ├── FileItem.swift            # Local IPA item in Documents
│   │   ├── InstalledAppModel.swift   # Installed app tracker model
│   │   ├── SigningOptions.swift      # User customizations before signing
│   │   ├── SigningLogEntry.swift     # Streaming console log entry
│   │   ├── IPAMetadata.swift         # Mach-O and Info.plist metadata
│   │   └── BackupPackage.swift       # Encrypted JSON backup model
│   ├── ViewModels/
│   │   ├── AppsViewModel.swift       # Search, filter, and categorizing apps
│   │   ├── SourcesViewModel.swift    # Repository fetching, QR scan, re-order
│   │   ├── FilesViewModel.swift      # Local IPA operations, multi-select, rename
│   │   ├── DownloadsViewModel.swift  # Queue operations (pause, resume, retry)
│   │   ├── CertificateManagerViewModel.swift # Import, parse, default switch
│   │   ├── SigningViewModel.swift    # Code signing execution and log streaming
│   │   ├── SignedAppsViewModel.swift # Expiry calculation and resigning triggers
│   │   └── SettingsViewModel.swift   # Storage usage, backup/restore, cache wipe
│   ├── Views/
│   │   ├── Apps/                     # AppsView, AppCardView, AppDetailView
│   │   ├── Sources/                  # SourcesView, SourceDetailView, AddSourceSheet, QRScannerView
│   │   ├── Files/                    # FilesView, FileRowView, MultiSelectToolbar, IPAInspectorView
│   │   ├── Downloads/                # DownloadsView, DownloadRowView, AddDownloadSheet
│   │   ├── Signing/                  # SigningFlowView, SigningOptionsView, DylibInjectionView, SigningConsoleView
│   │   ├── Certificates/             # CertificateManagerView, CertificateDetailView, ImportCertificateSheet
│   │   ├── Install/                  # InstallProgressSheet, InstallGuideView
│   │   ├── SignedApps/               # SignedAppsView, SignedAppCardView
│   │   ├── Settings/                 # SettingsView, AppearanceView, AccentColorPicker, AdvancedSettingsView, BackupRestoreView, LogConsoleView, OnboardingView, AboutView
│   │   └── Components/               # FloatingTabBar, ProgressRing, GlassCard, SkeletonLoader, EmptyStateView, ToastBanner
│   ├── Services/
│   │   ├── Signing/
│   │   │   ├── SigningService.swift  # High-level signing coordinator
│   │   │   ├── NativeSigner.swift    # Swift code directory, CodeResources, and sealing
│   │   │   ├── MachOHelper.swift     # Mach-O parser, DRM detection, and LC_LOAD_DYLIB injector
│   │   │   ├── ProvisioningParser.swift # CMS PKCS#7 mobileprovision parser
│   │   │   ├── P12Parser.swift       # SecPKCS12Import certificate validator
│   │   │   ├── IPAMetadataExtractor.swift # IPA inspection engine
│   │   │   ├── ZSignBridge.h         # Objective-C bridging header for zsign
│   │   │   ├── ZSignBridge.mm        # Objective-C++ wrapper
│   │   │   ├── zsign_wrapper.hpp     # C++ header for zsign engine
│   │   │   └── zsign_wrapper.cpp     # C++ implementation of signing pipeline
│   │   ├── Installation/
│   │   │   ├── LocalHTTPSServer.swift # Network.framework embedded server
│   │   │   ├── ManifestGenerator.swift # manifest.plist generator
│   │   │   ├── InstallationManager.swift # itms-services dispatcher
│   │   │   └── SelfSignedCertificateGenerator.swift # TLS parameters
│   │   ├── Downloads/
│   │   │   ├── DownloadManager.swift # URLSession download manager
│   │   │   └── BackgroundDownloadDelegate.swift # Delegate handling progress/speed
│   │   ├── Sources/
│   │   │   ├── SourceParserService.swift # URL fetching and dispatcher
│   │   │   ├── AltStoreSourceParser.swift # AltStore schema parser
│   │   │   └── ScarletSourceParser.swift # Scarlet schema parser
│   │   ├── Storage/
│   │   │   ├── KeychainService.swift # Hardware Keychain password manager
│   │   │   ├── FileStorageService.swift # Documents folder scanner
│   │   │   └── BackupRestoreService.swift # AES-GCM-256 backup encoder
│   │   ├── Biometrics/
│   │   │   └── BiometricAuthService.swift # LocalAuthentication wrapper
│   │   ├── Notifications/
│   │   │   ├── NotificationManager.swift # UNUserNotificationCenter scheduler
│   │   │   └── BackgroundRefreshTask.swift # BGTaskScheduler coordinator
│   │   └── Logging/
│   │       └── AppLogger.swift       # Diagnostic log collector
│   ├── Utilities/
│   │   ├── Extensions/               # Color, View, Date, Data, FileManager, Formatting
│   │   ├── Haptics/                  # HapticManager (UIImpactFeedbackGenerator)
│   │   ├── Zip/                      # ZipArchiveService (IPA unpacker & repacker)
│   │   └── Localization/             # LocalizedStrings (Type-safe key lookup)
│   └── Resources/
│       ├── Info.plist                # Background modes, permissions, UTIs
│       ├── SignHub.entitlements      # Keychain access groups, Wi-Fi info
│       ├── SignHub-Bridging-Header.h # Clang bridging header
│       ├── en.lproj/Localizable.strings # English translations
│       └── ar.lproj/Localizable.strings # Arabic translations
└── SignHubTests/
    ├── SigningServiceTests.swift     # Options and certificate status tests
    ├── SourceParserTests.swift       # AltStore and Scarlet parsing tests
    ├── ProvisioningParserTests.swift # Mobileprovision CMS extraction tests
    ├── ManifestGeneratorTests.swift  # Wireless OTA manifest generation tests
    └── MachOTests.swift              # Mach-O header and FairPlay DRM tests
```

---

## Design System & UI Components

SignHub adheres closely to Apple's Human Interface Guidelines (HIG):
- **Translucent Materials (`.ultraThinMaterial`)**: Card surfaces, floating navigation bars, and progress sheets adopt dynamic blur materials that sample underlying content.
- **Elevated Glassmorphic Cards (`.glassCard()`)**: 20pt corner continuous rectangles with dual-stop stroke gradients and soft drop shadows (`#000000` with 0.06 alpha).
- **Floating Pill Tab Bar**: Bottom floating capsule on iPhone with animated spring active indicators (`.spring(response: 0.35, dampingFraction: 0.75)`), tactile haptic feedback, and badge counts for active downloads and expiring certificates.
- **Adaptive Sidebar on iPad**: Switches automatically to `NavigationSplitView` on regular horizontal size classes for optimal iPad multitasking and Stage Manager experience.
- **Dynamic Theming**: Support for 7 accent colors (Sapphire Blue, Electric Violet, Deep Indigo, Sunset Coral, Cyber Teal, Neo Mint, and Ruby Crimson), each paired with custom linear gradients.
- **Accessibility**: Minimum 44x44pt tap targets, Dynamic Type support across all typography, and VoiceOver accessibility labels and hints.

---

## Subsystem Architecture

### 1. Code Signing Pipeline (zsign + Native Swift)

SignHub features a dual-layer code signing engine:
1. **Bridged `zsign` C++ Engine**: Bound via Objective-C++ (`ZSignBridge.mm`) and exposed to Swift through `SignHub-Bridging-Header.h`. This layer handles high-volume binary parsing, load command adjustments, and code directory hashing.
2. **Native Swift Signer (`NativeSigner.swift`)**:
   - Replaces `embedded.mobileprovision` with the user's provision profile.
   - Updates `Info.plist` key-value pairs (display name, bundle ID, version).
   - Injects `.dylib` dynamic libraries into the `Frameworks/` directory.
   - Strips or updates `PlugIns/` app extensions.
   - Generates an updated `_CodeSignature/CodeResources` XML property list containing SHA-1 and SHA-256 digests for all files.

### 2. Mach-O Dylib Injection

Dynamic tweak injection works directly on 64-bit Mach-O binaries (`MachOHelper.swift`):
- Reads the 32-byte `mach_header_64` header (`magic = 0xfeedfacf`, `cputype = arm64`).
- Scans existing load commands to avoid duplicate links.
- Constructs an `LC_LOAD_DYLIB` command:
  ```c
  struct dylib_command {
      uint32_t cmd;             // LC_LOAD_DYLIB (0x0C)
      uint32_t cmdsize;         // Aligned to 8-byte boundary
      struct dylib dylib;       // name offset, timestamp, current_version, compatibility_version
      char name[];              // "@executable_path/Frameworks/Tweak.dylib\0"
  };
  ```
- Injects the command into the header padding between the load commands and the first segment (`__TEXT`), incrementing `ncmds` and `sizeofcmds`.

### 3. Wireless Installation Engine

On iOS, third-party apps cannot invoke private installation daemons (`installd`) directly. SignHub uses the standard wireless enterprise mechanism:
1. An embedded HTTP/HTTPS server (`LocalHTTPSServer.swift`) starts on `127.0.0.1:8088` using `Network.framework` (`NWListener`).
2. `ManifestGenerator.swift` creates an OTA installation XML manifest (`manifest.plist`):
   ```xml
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "...">
   <plist version="1.0">
   <dict>
       <key>items</key>
       <array>
           <dict>
               <key>assets</key>
               <array>
                   <dict>
                       <key>kind</key>
                       <string>software-package</string>
                       <key>url</key>
                       <string>http://127.0.0.1:8088/package.ipa</string>
                   </dict>
               </array>
               <key>metadata</key>
               <dict>
                   <key>bundle-identifier</key>
                   <string>com.example.signedapp</string>
                   <key>bundle-version</key>
                   <string>1.0.0</string>
                   <key>kind</key>
                   <string>software</string>
                   <key>title</key>
                   <string>Signed App</string>
               </dict>
           </dict>
       </array>
   </dict>
   </plist>
   ```
3. `InstallationManager.swift` triggers the OS prompt:
   ```swift
   let url = URL(string: "itms-services://?action=download-manifest&url=http://127.0.0.1:8088/manifest.plist")!
   UIApplication.shared.open(url)
   ```
4. The iOS installation daemon connects to the local server, streams the package, and installs it onto the Home Screen.

### 4. Repository Normalization Engine

Community repositories are authored in different schema dialects:
- **AltStore format**: Uses top-level `apps` array, `bundleIdentifier`, `downloadURL`, `versionDate`.
- **Scarlet format**: Uses top-level `META` dictionary and `ITEMS` array with keys `down`, `dev`, `desc`, `icon`.

`SourceParserService.swift` normalizes both schemas into a unified, type-safe `SourceModel` and `[AppModel]` list.

### 5. Background Download Sessions

Downloads utilize a dedicated background session:
```swift
let config = URLSessionConfiguration.background(withIdentifier: "com.signhub.downloadsession")
config.isDiscretionary = false
config.sessionSendsLaunchEvents = true
```
The session survives app suspension and termination. Download speed is computed using delta bytes over time intervals, and completed files are automatically moved to the user's `Documents/IPAs` directory.

### 6. Certificate Expiry Tracking & Notifications

`NotificationManager.swift` schedules local alert reminders at four milestone intervals before certificate expiration:
- **7 Days Remaining**: Early reminder to plan a resign.
- **3 Days Remaining**: Notice that apps will soon stop launching.
- **24 Hours Remaining**: Urgent alert.
- **2 Hours Remaining**: Final warning.

---

## Known iOS Limitations & Constraints

When developing or operating sideloading utilities on modern iOS, several platform restrictions apply:

1. **Free Apple ID Account Limit (7-day rule)**:
   - Free developer accounts (personal Apple IDs) are limited to 3 active installed applications per device, and provisioning profiles expire after 7 days.
   - Paid Apple Developer accounts (\$99/yr) support up to 100 devices per device category and issue 365-day certificates with wildcard app IDs.
2. **Developer Mode Requirement (iOS 16+)**:
   - On iOS 16 and later, apps signed with developer profiles cannot launch until **Developer Mode** is toggled ON:
     `Settings > Privacy & Security > Developer Mode > Restart device`.
3. **Enterprise Certificates & PPQCheck**:
   - Enterprise (In-House) certificates require periodic online network verification via Apple's PPQ (Provisioning Profile Query) server. If Apple revokes the certificate, the app will show *"Unable to Verify App"*.
4. **FairPlay DRM Encrypted Binaries**:
   - IPAs downloaded directly from the official Apple App Store are encrypted with FairPlay DRM (`cryptid = 1` in `LC_ENCRYPTION_INFO_64`). These cannot be re-signed with third-party certificates without first decrypting the binary using a jailbroken device or specialized decryption tool. SignHub's IPA Inspector alerts the user if an IPA is FairPlay encrypted.
5. **Local Loopback (`itms-services`)**:
   - When the iOS installation daemon downloads the IPA from `127.0.0.1:8088`, SignHub must remain in the foreground for the few seconds it takes to accept the prompt and begin the transfer.

---

## Info.plist Keys & Entitlements

SignHub requires specific capabilities configured in `SignHub/Resources/Info.plist`:

| Key | Purpose |
|-----|---------|
| `UIBackgroundModes` | `fetch`, `processing` (Background certificate expiry monitoring) |
| `BGTaskSchedulerPermittedIdentifiers` | `com.signhub.refresh` |
| `NSFaceIDUsageDescription` | Biometric lock for certificates and private keys |
| `NSCameraUsageDescription` | Scanning repository QR codes |
| `NSPhotoLibraryUsageDescription` | Selecting custom application icons |
| `NSLocalNetworkUsageDescription` | Local HTTPS server for `itms-services` OTA installs |
| `UIFileSharingEnabled` | Access Documents library via iTunes / Finder |
| `LSSupportsOpeningDocumentsInPlace` | Open external IPAs in place |

Entitlements in `SignHub/Resources/SignHub.entitlements`:
- `keychain-access-groups`: `$(AppIdentifierPrefix)com.signhub.keychain`
- `com.apple.developer.networking.wifi-info`: `true`

---

## Step-by-Step Build & Run Guide

### Prerequisites
- macOS Sonoma (14.0+) or macOS Sequoia (15.0+)
- Xcode 15.0 or later
- An active Apple Developer Account (free or paid)
- A physical iPhone or iPad running iOS 16.0 or later (or iOS Simulator)

### Instructions

1. **Clone or Open the Project**:
   ```bash
   git clone https://github.com/yourusername/SignHub.git
   cd SignHub
   open SignHub/SignHub.xcodeproj
   ```

2. **Configure Code Signing**:
   - In Xcode's Project Navigator, select the root **SignHub** project.
   - Under **Signing & Capabilities**:
     - Check **Automatically manage signing**.
     - Select your **Development Team** in the dropdown.
     - Ensure the Bundle Identifier is set (e.g., `com.yourname.SignHub`).

3. **Verify Bridging Header**:
   - Ensure `Build Settings > Objective-C Bridging Header` points to:
     `SignHub/Resources/SignHub-Bridging-Header.h`

4. **Select Destination**:
   - Choose your physical iOS device or an iOS 16+ Simulator from the device bar.

5. **Build and Run**:
   - Press **Cmd + R** or click the **Play** button in Xcode.

6. **On Your iOS Device (First Run)**:
   - If deploying to a physical device for the first time:
     - Open **Settings > General > VPN & Device Management**.
     - Under **Developer App**, select your Apple ID and tap **Trust**.
     - If prompted, enable **Developer Mode** in **Settings > Privacy & Security > Developer Mode** and reboot.

---

## Unit Testing Suite

SignHub includes a unit test target (`SignHubTests`) testing core signing logic, schema parsing, and binary inspection:

To run all unit tests:
```bash
# In Xcode, press:
Cmd + U
```

### Test Coverage Highlights
- **`SourceParserTests.swift`**: Validates JSON deserialization against live AltStore v1 and Scarlet schemas.
- **`ProvisioningParserTests.swift`**: Tests CMS ASN.1 container peeling, extracting embedded XML plists, team IDs, and provisioned UDIDs.
- **`ManifestGeneratorTests.swift`**: Verifies generation of valid OTA `manifest.plist` conforming to Apple's wireless distribution schema.
- **`MachOTests.swift`**: Tests 64-bit architecture detection and FairPlay DRM (`cryptid != 0`) flag parsing.
- **`SigningServiceTests.swift`**: Tests certificate expiry countdowns, status badges, and default options.
