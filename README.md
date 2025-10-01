# AlgoPlayground

AlgoPlayground is a Flutter Web application featuring four mini-games designed to teach concepts from discrete mathematics. The project targets Flutter 3.x and Dart 3.x and focuses on a clean, testable architecture using Riverpod and GoRouter.

## Getting Started

1. Enable Flutter web support:
   ```bash
   flutter config --enable-web
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the development server (Chrome):
   ```bash
   flutter run -d chrome
   ```

## Building for the Web

```bash
flutter build web
```

## Data Persistence

Profile information and game scores are stored using `shared_preferences` in the browser's local storage. To reset the saved data, clear the application's site data from the browser or run the in-app reset option available in the scores screen menu.

## Project Structure

```
lib/
  main.dart
  app_router.dart
  core/
    models/
    services/
    utils/
    widgets/
  data/
    repositories/
  features/
    onboarding/
    dashboard/
    games/
      maze_runner/
      tower_logic/
      matching_pairs/
      puzzle_solver/
```

## Testing

Run the provided unit and widget tests with:

```bash
flutter test
```

The tests cover BFS correctness, logic gate evaluation, function constraints, puzzle solvability, and UI validation/navigation flows.
