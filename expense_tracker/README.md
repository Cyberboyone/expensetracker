# Expense Tracker (Flutter)

A fully offline expense tracker. No login, no backend — all data is stored
on-device using `shared_preferences`.

## Features
- Add, edit, and delete expenses (swipe left to delete, with undo)
- Categories with icons and colors
- Running total spent + category breakdown pie chart
- **Monthly budgets** — overall and per-category, with a progress bar that
  turns amber/red as you approach or exceed the limit
- **Search & filter** — search by title/note, filter by category and by
  date range (this month / last month / custom range)
- **CSV export** — export the currently filtered expenses and share/save
  via the OS share sheet
- **Backup & restore** — export all data (expenses + budgets) as a single
  JSON file, and restore from one later (useful since storage is local-only
  and would otherwise be lost on uninstall)

## Setup

This zip contains only the Dart source (`lib/`) and `pubspec.yaml` — no
`android/` or `ios/` folders. That's normal; those are regenerated locally
and shouldn't be hand-edited/shipped in a zip like this. **Because this
update adds packages with native code** (`path_provider`, `share_plus`,
`file_picker`), you need to generate those platform folders before running:

1. Unzip, then from inside the `expense_tracker` folder:
   ```
   flutter create . --project-name expense_tracker --org com.yourname
   ```
   (This scaffolds `android/`, `ios/`, etc. around your existing `lib/` —
   it won't touch your Dart files.)
2. Install dependencies:
   ```
   flutter pub get
   ```
3. Run on a connected device or emulator:
   ```
   flutter run
   ```

If you'd already run `flutter create .` on a previous version of this
project, just run `flutter pub get` again — no need to redo step 1.

## Project structure
```
lib/
  main.dart                          # App entry point, theme
  models/
    expense.dart                     # Expense model + JSON (de)serialization
    budget.dart                      # Budget model (overall + per-category)
    expense_filter.dart              # Search/filter criteria + matching logic
  services/
    storage_service.dart             # SharedPreferences persistence (expenses + budget)
    export_service.dart              # CSV export, JSON backup/restore
  screens/
    home_screen.dart                 # Total, budget card, chart, search/filter, list
    add_edit_expense_screen.dart     # Add/edit form
    budget_screen.dart               # Set overall + per-category budgets
  widgets/
    expense_tile.dart                # Dismissible list item
    category_style.dart              # Icon/color per category
    budget_progress_card.dart        # Budget progress bar with warning states
    filter_sheet.dart                # Bottom sheet for category/date filters
```

## Notes
- Currency is shown as ₦ (naira) by default — search for `NumberFormat.currency`
  across the `screens/` and `widgets/` files if you'd like a different symbol.
- Storage is JSON blobs under two SharedPreferences keys (`expenses_v1`,
  `budget_v1`) — simple and fine for personal use. If the list grows very
  large or you want real querying later, swapping in `sqflite` is a natural
  next step — `StorageService`'s interface is written so that swap wouldn't
  touch the UI code.
- Backup/restore is the safety net for local-only storage — encourage
  users to back up periodically, especially before uninstalling or
  switching phones.
- Not yet wired in: an ads SDK. That's the natural next step for
  monetization — happy to add AdMob or Unity LevelPlay placements
  (banner on the home list, interstitial on save) whenever you're ready.
