# Open POS

**A free, 100% offline point-of-sale app. Your sales data never leaves your device.**

No subscription. No account. No internet connection needed. Ring up sales, manage tables and track your takings on an Android or iOS phone or tablet, with everything stored on that device.

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platforms: Android | iOS](https://img.shields.io/badge/platforms-Android%20%7C%20iOS-informational.svg)](#get-open-pos)
[![100% offline](https://img.shields.io/badge/network-100%25%20offline-success.svg)](#privacy-you-can-check-yourself)
[![Built with Flutter](https://img.shields.io/badge/built%20with-Flutter-02569B.svg)](#build-from-source)

---

## Get Open POS

<a href="https://play.google.com/store/apps/details?id=com.brandbuilder.openpos&referrer=utm_source%3Dgithub%26utm_medium%3Dreadme"><img alt="Get it on Google Play" src="https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png" height="80"></a> <a href="https://apps.apple.com/app/open-pos-offline/id6761003751?ct=github_readme"><img alt="Download on the App Store" src="https://toolbox.marketingtools.apple.com/api/badges/download-on-the-app-store/black/en-us?size=250x83" height="54"></a>

**Android:** install Open POS from [Google Play](https://play.google.com/store/apps/details?id=com.brandbuilder.openpos&referrer=utm_source%3Dgithub%26utm_medium%3Dreadme).

**iPhone and iPad:** install it from the [App Store](https://apps.apple.com/app/open-pos-offline/id6761003751?ct=github_readme).

The current store versions date from May 2026. The features below describe the upcoming release, which also fixes known issues in refunds, stock and printing. The next release also ships as a direct APK here, in a build you can verify yourself. Click **Watch → Custom → Releases** at the top of this page to be notified.

You can also [build Android or iOS from source](#build-from-source).

<sub>Google Play and the Google Play logo are trademarks of Google LLC. Apple and the Apple logo are trademarks of Apple Inc., registered in the U.S. and other countries. App Store is a service mark of Apple Inc.</sub>

<!-- HOLD: restore at first release (replace the section above)
**[Download the latest release](https://github.com/onepiece92/openPOS/releases/latest)**

| Platform | How to install |
| --- | --- |
| **Android** (phone or tablet) | Download the `.apk` from the latest release, open it, and allow "Install unknown apps" when Android asks. |
| **iOS** (iPhone or iPad) | No public build yet. [Build from source](#build-from-source). |
HOLD -->

<!-- HOLD: pending notarisation decision
### macOS

Download the macOS build from the latest release, unzip it, and drag the app into your **Applications** folder.

<details>
<summary><strong>macOS says the app "can't be opened" or "Apple could not verify" it</strong></summary>

The macOS build is not yet notarised by Apple, so Gatekeeper blocks the first launch. On macOS 15 and later:

1. Try to open the app once from **Applications**, then close the warning.
2. Open **System Settings → Privacy & Security**.
3. Scroll down to the message about the app and click **Open Anyway**.
4. Confirm with your password or Touch ID, then click **Open**.

You only need to do this once. Printing is not available in the Mac app.

</details>
HOLD -->

<!-- HOLD: restore when docs/screenshots/*.png exist on main
## Screenshots

| Selling | Tables |
| --- | --- |
| ![Sell screen with product grid and cart](docs/screenshots/sell.png) | ![Table management for cafes and restaurants](docs/screenshots/tables.png) |
| **Reports** | **Receipt** |
| ![Reports dashboard with revenue and profit](docs/screenshots/reports.png) | ![Receipt preview](docs/screenshots/receipt.png) |
HOLD -->

---

## Why Open POS

- **Your data stays with you.** The app's own code makes no network calls: no accounts, no cloud, no analytics. Sales, customers and stock live in a database on your device and nowhere else.
- **Free, for good.** No subscription, no per-device fee, no premium tier. MIT licensed.
- **Works with no internet.** A dropped connection never stops a sale, because the app never needed one.
- **Made for small shops and cafes.** Tables, held tickets and simple reports, without the setup of a big system.

---

## Features

### Selling
- Product grid or list, with search, category filter and favourites
- Cart with whole-order discounts (amount or percent)
- Cash payment with tendered amount and change, or card
- Held tickets: park an order and resume it later
- Table management for restaurants and cafes
<!-- HOLD: pending fix confirmation
- Loyalty point redemption at checkout
HOLD -->

### Products
- Categories and a SKU/barcode field
<!-- HOLD: not in the May 2026 Play build; restore at next release
- Secondary units (for example, sell by the piece or by the dozen)
HOLD -->
- Bundle and composite products
<!-- HOLD: pending fix confirmation
- Stock tracking with adjustments
- Low-stock badges
HOLD -->

### Customers
- Customer records, attached to sales
<!-- HOLD: pending fix confirmation
- Loyalty points with a configurable earn rate
HOLD -->

### Orders and receipts
- Order history and voids
- PDF receipts
- Share receipts by SMS or email through your device's own apps, or copy them as text
<!-- HOLD: pending fix confirmation
- Refunds, with optional restock
HOLD -->

### Money and reports
- Tax rates, with tax switched on or off per product
- Expense tracking
- Reports dashboard: revenue, expenses, net profit, average order value, with charts
- Audit log of important actions

### Your data
- CSV import and export
<!-- HOLD: pending backup/restore fix confirmation
- Backup and restore as a single `.zip` file
- Automatic snapshots
HOLD -->

### Setup
- Guided onboarding with defaults for 33 countries
- 24 currencies
- Light and dark theme
<!-- HOLD: pending notarisation decision (desktop = macOS only)
- Keyboard shortcuts on desktop
HOLD -->

<!-- HOLD: pending ESC/POS blank-print fix confirmation (restore as its own section)
## Supported printers

| Type | Notes |
| --- | --- |
| Bluetooth LE thermal printers | ESC/POS compatible |
| Bluetooth Classic thermal printers | ESC/POS compatible |
| Star printers | Over Bluetooth |
| System printers | Through the system print dialog (PDF) |

Paper widths: **58 mm** and **80 mm**. Auto-print can be turned on so each completed sale prints without an extra tap.

Network (Wi-Fi/LAN) printers are not supported, because the app has no network access.
HOLD -->

---

## Privacy you can check yourself

Open POS does not ask you to trust a privacy policy. The app's own code makes no network calls and has never included analytics or cloud services. Starting with the next release, the Android build also goes a step further: the operating system itself blocks it from the network, so you don't have to take our word for it.

**Android (next release onwards).** The release build removes the `INTERNET` and `ACCESS_NETWORK_STATE` permissions (see [`android/app/src/release/AndroidManifest.xml`](android/app/src/release/AndroidManifest.xml)). Without `INTERNET`, Android does not let an app open network connections. You can check a release build yourself:

```sh
# Android SDK build-tools
aapt dump permissions open-pos.apk
# or
apkanalyzer manifest permissions open-pos.apk
```

`android.permission.INTERNET` will not be in the list. The current Google Play version predates this change. Debug builds made with `flutter run` keep `INTERNET` because Flutter's hot reload needs it; the release build does not.

<!-- HOLD: pending notarisation decision
**macOS.** The app runs in Apple's App Sandbox with no network entitlement (`com.apple.security.network.client` is absent; see [`macos/Runner/Release.entitlements`](macos/Runner/Release.entitlements)). Check the installed app:

```sh
codesign -d --entitlements - "/Applications/Open POS.app"
```
HOLD -->

**What this means in practice:** no analytics, no crash reporting, no cloud backup, no update checks, no account. Receipts you share by SMS or email go through your device's own Messages or Mail app, which you control.

---

## Build from source

You need [Flutter](https://docs.flutter.dev/get-started/install) **3.22 or newer** (Dart SDK 3.3 or newer).

```sh
git clone https://github.com/onepiece92/openPOS.git
cd openPOS
flutter pub get
flutter run
```

Release builds:

```sh
flutter build apk --release      # Android
flutter build ios --release      # iOS (needs a Mac with Xcode and your own signing)
```

---

## Need cloud sync and multi-device?

Open POS is deliberately single-device and offline, and it will stay that way. It will also stay free. If your business needs sync across several devices, online ordering or a back office in the cloud, the same team makes [RebuzzPOS](https://rebuzzpos.com), an online POS with 40+ additional features. It is a separate product; nothing in Open POS depends on it or connects to it.

---

## Contributing

Bug reports, feature ideas and pull requests are welcome. Please [open an issue](https://github.com/onepiece92/openPOS/issues) first for larger changes.

One firm rule: Open POS is offline by design. Pull requests that add network calls, analytics, cloud SDKs or the `INTERNET` permission will not be merged.

## License

[MIT](LICENSE). Copyright (c) 2026 Open POS contributors.
