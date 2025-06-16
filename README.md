# chokchey_hr_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


##  Project Structure (MVVM)
lib/
├── constants/             # App-wide constants (colors, strings, etc.)
│   └── app_constants.dart
├── localization/          # Localization files and logic
│   └── app_localizations.dart
├── models/                # Data classes
│   └── user.dart
├── repositories/          # Data repositories (combine API/local storage)
│   └── user_repository.dart
├── services/              # API calls or local storage helpers
│   └── api_service.dart
├── themes/                # App themes and styles
│   └── app_theme.dart
├── utils/                 # Helper functions and extensions
│   └── date_utils.dart
├── viewModels/            # State management (ChangeNotifier, Riverpod, etc.)
│   └── user_viewmodel.dart
├── views/                 # UI Screens & Widgets
│   └── user_profile_screen.dart
├── widgets/               # Reusable widgets (buttons, cards, etc.)
│   └── custom_button.dart
└── main.dart              # App entry point

## Create folder structure
# Navigate to your Flutter project's lib directory
cd lib

# Create folders for organized code structure
mkdir constants        # For app-wide constants (colors, strings, etc.)
mkdir localization     # For localization/i18n files and logic
mkdir models           # For data model classes
mkdir repositories     # For data repositories to access APIs or DB
mkdir services         # For API calls and local storage services
mkdir themes           # For app theme and style files
mkdir utils            # For utility/helper functions
mkdir viewModels       # For state management classes (ChangeNotifier, etc.)
mkdir views            # For UI screens and widgets
mkdir widgets          # For reusable UI components
