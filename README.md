# Budget Checklist (Flutter)

A Flutter rewrite of `budgetgui.py`, with a warm, Claude-inspired look
(terracotta accent, sage greens, warm paper background) instead of the
original navy/blue Tkinter theme.

[![Android build](https://github.com/Darenn71/budget-checklist/actions/workflows/android.yml/badge.svg)](https://github.com/Darenn71/budget-checklist/actions/workflows/android.yml)

## Download

**[⬇ Download the latest APK](https://github.com/Darenn71/budget-checklist/releases/latest/download/budget-checklist.apk)**

Built automatically on GitHub from the latest code. Website:
https://darenn71.github.io/budget-checklist/ · All builds are on the
[Releases page](https://github.com/Darenn71/budget-checklist/releases).

## What's included

- **Dashboard** — bank balance (editable), outstanding bills, money left,
  owed-to-me, future balance, plus the current billing-cycle range.
- **Bills Checklist** — add/edit/delete, tick to mark paid, sort by name /
  due date / amount, overdue highlighting, unpaid/paid sections.
- **Money Owed** — add/edit/delete, tick to mark received.
- **Menu / Settings**
  - **Pay Day / Reset Date** — a configurable day-of-month (1–31). When a
    new billing cycle starts (i.e. this date is reached), **all bills are
    automatically reset to unpaid**. Money owed is **never** auto-reset.
  - Save, Export Dataset (`.budget.json`), Export Bills CSV, Import Dataset.
  - Manual "Untick All Bills" and manual "Reset Money Owed" actions.
- Local autosave to `budget_data.json` in the app's documents directory,
  using the same JSON shape as the original app (plus `pay_day` and
  `last_reset_cycle_start` fields), so old exports can be imported directly.

## What's different from the original

- **Excel (.xlsx) import was dropped** to keep this rewrite focused — the
  app now reads/writes its own JSON dataset (and exports bills to CSV). If
  you want Excel import added back (via the `excel` package), that's a
  straightforward follow-up.
- The fixed "25th–24th" cycle is now a **configurable pay day** (Menu →
  Pay Day / Reset Date). The cycle always runs from that day-of-month to
  the day before it next month, clamped for short months (e.g. pay day 31
  in February → 28th/29th).
- "Untick All" is now two separate actions: **Untick All Bills** (manual,
  in addition to the automatic pay-day reset) and **Reset Money Owed**
  (always manual).

## Building

1. Install Flutter (stable channel, 3.24+).
2. From this folder:
   ```bash
   flutter pub get
   flutter run            # run on a connected device/emulator
   # or
   flutter build apk      # release APK for Android
   ```

## Notes on dependencies

- `file_picker` is used for both export (save dialog) and import (open
  dialog). On Android, exports are written via the `bytes:` parameter of
  `saveFile`, which works with file_picker 11.x.
- **If you're on Android Gradle Plugin (AGP) 9.x** (Flutter 3.44+ defaults
  to this), you need **file_picker 11.0.2 or later** — earlier versions'
  bundled Android module doesn't support AGP 9 and will fail with a
  `:file_picker:checkDebugAarMetadata` / "compileSdk 36" error regardless
  of your own app's `compileSdk`. This project already pins
  `file_picker: ^11.0.2`. Note the v11 API is static
  (`FilePicker.saveFile(...)`, `FilePicker.pickFiles(...)`) rather than
  `FilePicker.platform.xxx()` used in v8.
- `google_fonts` pulls in "Inter" for the UI typeface — remove it and fall
  back to the system font if you'd rather not fetch fonts at build time.

## Project layout

```
lib/
  models.dart            BillItem / OwedItem (+ JSON, matches old format)
  budget_logic.dart       cycle bounds, overdue logic, sorting, money parsing
  storage.dart            local persistence, export payloads, CSV
  app_state.dart          ChangeNotifier: state, totals, auto-reset logic
  theme.dart              Claude-inspired colours, ThemeData, BigButton
  screens/
    dashboard_screen.dart
    bills_screen.dart
    owed_screen.dart
    edit_bill_screen.dart
    edit_owed_screen.dart
    menu_screen.dart
  widgets/
    stat_card.dart
    bill_card.dart
    owed_card.dart
```
