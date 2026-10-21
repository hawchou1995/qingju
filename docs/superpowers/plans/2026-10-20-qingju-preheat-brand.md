# 青橘预热加载页品牌修复 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the Flutter preheat page's Linux.do/FluxDO mark and `FluxDO` title with the existing Qingju SVG mark and `SiteIdentity.name`.

**Architecture:** Keep `PreheatGate`'s loading/retry/skip lifecycle unchanged. Rewrite `PreheatLogo` as a small `jovial_svg` asset widget with a finite fade/scale entrance, and have the loading screen use the site's canonical name. Do not alter native Android/iOS splash resources or launcher icons.

**Tech Stack:** Flutter/Dart, `jovial_svg` (already present in `pubspec.yaml`), `flutter_test`.

## Global Constraints

- Do not add dependencies.
- Preserve preheat behavior, skip button, version text, retry, and app-icon setting behavior.
- The preheat page brand mark comes from `assets/logo.svg`; the title comes from `SiteIdentity.name`.
- Scope is the Flutter preheat page only; no Android/iOS native splash or launcher-icon changes.
- The friend-test build uses app version `0.2.30+2026102101`; its Android asset name is `qingju-0.2.30-android-arm64-debug.apk`.

---

### Task 1: Add regression tests for the splash mark and title

**Files:**
- Create: `test/widgets/preheat_logo_test.dart`
- Read: `lib/widgets/preheat_gate.dart`
- Read: `lib/config/site_identity.dart`

**Interfaces:**
- Consumes `PreheatLogo({Key? key, double size})` after the implementation step removes the old icon-style argument.
- `PreheatLogo` must render one `ScalableImageWidget` sourced from `assets/logo.svg`.
- `_PreheatLoading` must display `SiteIdentity.name`, with no hard-coded `FluxDO` title.

- [x] **Step 1: Create the failing regression tests**

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jovial_svg/jovial_svg.dart';
import 'package:fluxdo/providers/app_icon_provider.dart';
import 'package:fluxdo/widgets/preheat_logo.dart';

void main() {
  testWidgets('preheat logo renders the Qingju SVG asset', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PreheatLogo(style: AppIconStyle.classic, size: 108),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));
    expect(
      find.byWidgetPredicate((widget) => widget is ScalableImageWidget),
      findsWidgets,
    );
  });

  test('preheat title uses the canonical site name', () async {
    final source = await File('lib/widgets/preheat_gate.dart').readAsString();
    expect(source, contains('SiteIdentity.name'));
    expect(source, isNot(contains("'FluxDO'")));
  });
}
```

- [x] **Step 2: Run the tests and confirm the old implementation fails**

Run: `flutter test --no-pub test/widgets/preheat_logo_test.dart`
Expected: the logo assertion fails because the current `PreheatLogo` renders `CustomPaint`, and the title contract fails because the loading widget contains the literal `FluxDO`.

---

### Task 2: Replace the old preheat mark and title

**Files:**
- Modify: `lib/widgets/preheat_logo.dart`
- Modify: `lib/widgets/preheat_gate.dart`
- Modify: `test/widgets/preheat_logo_test.dart`

**Interfaces:**
- `PreheatLogo({Key? key, double size = 108})` renders the existing Qingju SVG and its finite entrance animation.
- `_PreheatLoading` continues to own spinner, skip, and version presentation; it uses `SiteIdentity.name` for the heading.

- [x] **Step 1: Rewrite `PreheatLogo` using the existing SVG renderer**

Use `ScalableImageSource.fromSvg(DefaultAssetBundle.of(context), 'assets/logo.svg', warnF: (_) {})` and `ScalableImageWidget.fromSISource(si: source)`. Animate progress from opacity 0 to 1 and scale 0.88 to 1.0 over 600 ms with `Curves.easeOutCubic`; keep `size` as the only visual parameter. Remove the obsolete Linux.do/FluxDO geometry painter and icon-style dependency from `lib/widgets/preheat_logo.dart`.
- [x] **Step 2: Remove old splash icon preference plumbing and use the canonical name**

In `lib/widgets/preheat_gate.dart`, remove the `shared_preferences` import, `_iconStyle`, `_readIconStyle()`, and its `initState()` call because the splash logo no longer follows launcher-icon preference. Retain `app_icons` because the preheat failure view uses `Symbols`. Keep the launcher icon preference itself untouched in `AppIconProvider`. Construct `PreheatLogo(size: 108)` and replace the literal title with `SiteIdentity.name`, adding the `site_identity.dart` import.

- [x] **Step 3: Update the logo test to the final constructor**

Change the test widget to `const MaterialApp(home: PreheatLogo(size: 108))` and remove the `app_icon_provider.dart` import. Keep the title source-contract assertion.

- [x] **Step 4: Run the focused regression tests**

Run: `flutter test --no-pub test/widgets/preheat_logo_test.dart`
Expected: both tests pass; the widget tree contains the ScalableImageWidget base type (the package exposes async and sync subclasses), and the preheat gate references `SiteIdentity.name`, not a literal `FluxDO` title.

---

### Task 3: Run checks and review the final diff

**Files:**
- Check: `lib/widgets/preheat_logo.dart`
- Check: `lib/widgets/preheat_gate.dart`
- Check: `test/widgets/preheat_logo_test.dart`

- [x] **Step 1: Run focused static analysis**

Run: `dart analyze lib/widgets/preheat_logo.dart lib/widgets/preheat_gate.dart test/widgets/preheat_logo_test.dart`
Expected: `No issues found!`.

- [x] **Step 2: Check formatting and whitespace**

Run: `dart format --output=none --set-exit-if-changed lib/widgets/preheat_logo.dart lib/widgets/preheat_gate.dart test/widgets/preheat_logo_test.dart`
Expected: exit code 0 and no files changed.

Run: `git diff --check`
Expected: no whitespace errors.

- [x] **Step 3: Confirm only scoped implementation files changed**

Run: `git status --short`
Expected: only the two preheat Dart files, focused test, `pubspec.yaml`, release workflow, and plan document are changed; pre-existing `.workflow/` remains untouched.

### Task 4: Build and verify the versioned friend-test release

**Files:**
- Modify: `pubspec.yaml` (`0.2.30+2026102101`)
- Modify: `.github/workflows/qingju-release.yml` (default tag and release notes)
- Verify: GitHub release assets and checksums
- Local deliverable: `deliverables/qingju-android-0.2.30/`

- [x] **Step 1: Confirm release inputs**

Verify the tag `qingju-v0.2.30` does not already exist, `pubspec.yaml` is `0.2.30+2026102101`, and the release workflow derives filenames from the pushed tag.

- [ ] **Step 2: Commit and push the scoped fix and release metadata**

Stage only `lib/widgets/preheat_gate.dart`, `lib/widgets/preheat_logo.dart`, `test/widgets/preheat_logo_test.dart`, `pubspec.yaml`, `.github/workflows/qingju-release.yml`, and this plan. Commit as `fix: replace legacy Qingju preheat branding`; push branch `qingju` and tag `qingju-v0.2.30`.

- [ ] **Step 3: Wait for the five-platform release workflow**

Run: `gh run list --repo hawchou1995/qingju --workflow qingju-release.yml --limit 3 --json databaseId,headSha,status,conclusion,url`
Expected: run for the new commit completes with Android, iOS, macOS, Windows, Linux and publish jobs successful. If only Linux fails on transient package download, rerun that failed job after the run finishes; do not rebuild successful platform jobs.

- [ ] **Step 4: Download and verify the Android asset**

Download `qingju-0.2.30-android-arm64-debug.apk`, `BUILD-android.txt` and `SHA256SUMS-android.txt` from release `qingju-v0.2.30` into `deliverables/qingju-android-0.2.30/`. Verify APK SHA-256 against the matching checksum line and verify `BUILD-android.txt` commit equals the release tag commit.

- [ ] **Step 5: Open the local folder for handoff**

Run `explorer.exe E:\PI\项目\fluxdo\deliverables\qingju-android-0.2.30` and confirm the APK exists. The package is ARM64 debug-signed; a fresh install may be needed if the previous debug package has a different signing key.
