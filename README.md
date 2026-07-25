# Stockpile — Inventory Management System UI

A responsive, minimalistic Flutter UI for an inventory management system, built with a persistent left sidebar and seven dynamically-switched screens.

## Getting started

```bash
flutter pub get
flutter run -d chrome   # or: flutter run -d macos / windows / linux
```

Requires Flutter 3.19+ (uses `WidgetStateProperty`, `Color.withValues`, Material 3).

## Project structure

```
lib/
  main.dart                     # App entry point
  theme/
    app_theme.dart              # Colors, spacing, radii, type scale, ThemeData
  models/
    models.dart                 # Data classes (Product, Transaction, Supplier, ...)
    mock_data.dart               # Static mock data feeding every screen
  widgets/                       # Shared, reusable UI pieces
    sidebar.dart                 # Persistent left navigation
    top_header_bar.dart          # Search + notifications + avatar (Dashboard)
    section_card.dart            # White surface card + ScreenHeader
    stat_card.dart                # Dashboard stat tiles
    status_badge.dart            # Color-coded status pills
    buttons.dart                  # Primary / secondary buttons
  screens/
    main_layout_screen.dart      # Sidebar + Expanded content shell, handles routing
    dashboard_screen.dart
    inventory_screen.dart
    inbound_screen.dart
    outbound_screen.dart
    suppliers_screen.dart
    reports_screen.dart
    settings_screen.dart
```

## Design tokens

| Token | Value |
|---|---|
| Background | `#F8F9FA` |
| Text primary | `#212529` |
| Primary (blue) | `#2563EB` |
| Success (green) | `#16A34A` |
| Warning (amber) | `#D97706` |
| Danger (red) | `#DC2626` |
| Font | Inter (via `google_fonts`), Roboto Mono for SKUs |

## Responsiveness

- Sidebar collapses into a `Drawer` (with an `AppBar` menu button) below 900px width.
- Dashboard stat grid and stock-movement/quick-actions split reflow from row → wrapped/stacked layout below 900px.
- Suppliers and Reports grids step down from 3 → 2 → 1 columns based on available width.
- All tables scroll horizontally on narrow viewports rather than clipping.

## Notes

- All data is static mock data in `lib/models/mock_data.dart` — swap in real API calls / state management (Provider, Riverpod, Bloc) by replacing `MockData` references.
- Chart on the Dashboard uses `fl_chart`'s `LineChart` with a 7D/30D/90D toggle driving three canned datasets; wire up to real time-series data as needed.
- This environment could not run `flutter analyze` / `flutter build` (no Flutter SDK available, sandboxed network), so the code was validated via careful manual review — brace/paren balance, import correctness, constructor signatures, and Material icon names were all checked. Run `flutter analyze` locally after `flutter pub get` to catch anything environment-specific.
