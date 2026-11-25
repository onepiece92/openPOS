# Open POS

**A free, 100% offline point-of-sale app. Your sales data never leaves your device.**

No subscription. No account. No internet connection needed. Ring up sales, manage tables and track your takings on an Android phone or tablet, with everything stored on that device.

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platforms: Android | iOS](https://img.shields.io/badge/platforms-Android%20%7C%20iOS-informational.svg)](#get-open-pos)
[![No internet permission](https://img.shields.io/badge/network-no%20internet%20permission-success.svg)](#privacy-you-can-check-yourself)
[![Built with Flutter](https://img.shields.io/badge/built%20with-Flutter-02569B.svg)](#build-from-source)

---

## Get Open POS

**The first Android release is coming soon.** Click **Watch → Custom → Releases** at the top of this page to be notified when it is published.

Until then, you can [build it from source](#build-from-source).

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

- **Your data stays with you.** The Android release build has no network access at all. Sales, customers and stock live in a database on your device and nowhere else.
- **Free, for good.** No subscription, no per-device fee, no premium tier. MIT licensed.
- **Works with no internet.** A dropped connection never stops a sale, because the app never needed one.
- **Made for small shops and cafes.** Tables, held tickets and simple reports, without the setup of a big system.

---

## Features

### Selling
- Product grid or list, with search, category filter and favourites
- Cart with per-line and whole-order discounts
- Cash payment with tendered amount and change, or card
- Held tickets: park an order and resume it later
- Table management for restaurants and cafes
<!-- HOLD: pending fix confirmation
- Loyalty point redemption at checkout
HOLD -->

### Products
- Categories, SKU/barcode field and product photos
- Secondary units (for example, sell by the piece or by the dozen)
- Bundle and composite products
<!-- HOLD: pending fix confirmation
- Stock tracking with adjustments
- Low-stock alerts
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
- Tax rates and tax groups, with per-product taxes
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

Open POS does not ask you to trust a privacy policy. The Android release build is configured so the operating system blocks it from the network.

**Android.** The release build removes the `INTERNET` and `ACCESS_NETWORK_STATE` permissions (see [`android/app/src/release/AndroidManifest.xml`](android/app/src/release/AndroidManifest.xml)). Without `INTERNET`, Android does not let an app open network connections. You can check a release build yourself:

```sh
# Android SDK build-tools
aapt dump permissions open-pos.apk
# or
apkanalyzer manifest permissions open-pos.apk
```

`android.permission.INTERNET` will not be in the list. Debug builds made with `flutter run` keep `INTERNET` because Flutter's hot reload needs it; the release build does not.

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
