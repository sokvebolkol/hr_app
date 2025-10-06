# Chokchey HR App 📱

A comprehensive Human Resources mobile application built with Flutter, designed to streamline HR processes and enhance employee engagement.

## 🎯 Overview

Chokchey HR App is a modern, feature-rich mobile application that provides employees and HR administrators with essential tools for managing workplace operations, from attendance tracking to leave requests and notifications.

## ✨ Features

### 👥 **For Employees**
- 🔐 Secure login with User ID authentication
- 📊 Personal dashboard with key metrics
- 📝 Leave request management
- 📱 Push notifications for important updates
- 🌍 Multi-language support (English/Khmer)
- 📸 Profile management with photo upload
- 📍 Location-based features

### 👨‍💼 **For Managers/Approvers**
- ✅ Request approval workflows
- 📈 Team overview and analytics
- 🔔 Real-time notification management
- 📊 Reporting capabilities

### 🏢 **For CEO/Administrators**
- 📋 Company-wide dashboard
- 📊 Advanced analytics and insights
- 👥 User management
- 🔧 System configuration

## 🛠️ Tech Stack

- **Framework:** Flutter (Dart)
- **Architecture:** MVVM (Model-View-ViewModel)
- **State Management:** Provider
- **Backend Services:** RESTful API
- **Push Notifications:** Firebase Cloud Messaging (FCM)
- **Local Storage:** SharedPreferences, Secure Storage
- **Maps:** Google Maps integration
- **Localization:** Multi-language support

## 📁 Project Structure (MVVM)

```
lib/
├── constants/             # App-wide constants (colors, strings, etc.)
│   ├── constant.dart      # Main constants file
│   └── app_constants.dart # Additional app constants
├── localization/          # Localization files and logic
│   ├── language.dart      # Language models
│   └── language_logic.dart # Language switching logic
├── models/                # Data classes and entities
│   ├── user.dart          # User model
│   └── notification_model.dart # Notification model
├── repositories/          # Data repositories (API + local storage)
│   └── user_repository.dart
├── services/              # Business logic and API services
│   ├── global_service.dart # Global app services
│   ├── firebase_notification_service.dart # FCM service
│   └── api_service.dart   # API communication
├── themes/                # App themes and styling
│   └── app_theme.dart
├── utils/                 # Helper functions and utilities
│   └── date_utils.dart
├── viewModels/            # State management classes
│   └── user_viewmodel.dart
├── views/                 # UI Screens and Widgets
│   ├── auth/              # Authentication screens
│   │   ├── login-screen.dart
│   │   └── forgot-password.dart
│   ├── dashboard/         # Dashboard screens
│   │   ├── requester_dashboard.dart
│   │   ├── approver_dashboard_screen.dart
│   │   └── ceo_dashboard_screen.dart
│   └── widgets/           # Reusable UI components
└── main.dart              # App entry point
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio / VS Code
- iOS development setup (for iOS builds)
- Firebase account and project setup

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/sokvebolkol/hr_app.git
   cd chokchey_hr_app
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration:**
   - Add your `google-services.json` (Android) to `android/app/`
   - Add your `GoogleService-Info.plist` (iOS) to `ios/Runner/`

4. **Configure environment:**
   - Update API endpoints in `services/global_service.dart`
   - Configure app constants in `constants/constant.dart`

5. **Run the app:**
   ```bash
   # Debug mode
   flutter run

   # Release mode
   flutter run --release
   ```

## 📱 Building for Production

### Android APK/Bundle

```bash
# Build APK
flutter build apk --release

# Build App Bundle (recommended for Play Store)
flutter build appbundle --release
```

### iOS IPA

```bash
# Build for iOS
flutter build ios --release
```

## 🔧 Build Issue Resolution

If you encounter the error: `"Gradle build failed to produce an .apk file"`, follow these steps:

### Step 1: Check APK Location
```bash
find . -name "*.apk" -type f
```

### Step 2: Create Expected Directory
```bash
mkdir -p build/app/outputs/flutter-apk/
```

### Step 3: Copy APK to Expected Location
```bash
cp android/app/build/outputs/apk/release/app-release.apk \
   build/app/outputs/flutter-apk/app-release.apk
```

### Step 4: Clean and Rebuild
```bash
flutter clean
cd android && ./gradlew clean && cd ..
flutter pub get
flutter build apk --release
```

## 🔥 Firebase Configuration

### Android Setup
1. Download `google-services.json` from Firebase Console
2. Place in `android/app/` directory
3. Ensure Firebase dependencies are in `android/app/build.gradle.kts`

### iOS Setup
1. Download `GoogleService-Info.plist` from Firebase Console
2. Add to Xcode project in `ios/Runner/`
3. Configure APNs certificates in Firebase Console
4. Update `ios/Runner/AppDelegate.swift` for notification handling

### FCM Token Handling
The app automatically:
- Requests notification permissions
- Retrieves FCM tokens
- Associates tokens with user accounts
- Handles token refresh

## 🌐 Localization

The app supports multiple languages:
- **English (EN)** - Default
- **Khmer (KH)** - Cambodian

### Adding New Languages
1. Create language files in `localization/`
2. Update `LanguageLogic` class
3. Add language switching UI components

## 🔒 Security Features

- Secure user authentication
- Token-based API communication
- Encrypted local storage
- Secure file handling
- Permission-based access control

## 🧪 Testing

```bash
# Run unit tests
flutter test

# Run widget tests
flutter test test/widget_test.dart

# Run integration tests
flutter drive --target=test_driver/app.dart
```

## 📊 Performance Optimization

- **Tree-shaking** enabled for icon fonts
- **Code splitting** for better load times
- **Image optimization** for faster loading
- **Lazy loading** for large lists
- **Memory management** best practices

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📋 Development Guidelines

### Code Style
- Follow Dart/Flutter conventions
- Use meaningful variable names
- Add comments for complex logic
- Maintain consistent formatting

### Git Workflow
- Use descriptive commit messages
- Keep commits atomic and focused
- Use branch naming convention: `feature/`, `bugfix/`, `hotfix/`

### Testing Requirements
- Write unit tests for business logic
- Add widget tests for UI components
- Ensure integration tests pass

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase team for backend services
- Contributors and testers
- Open source community

---

## 📈 Version History

- **v1.0.0** - Initial release with core HR features
- **v1.1.0** - Added push notifications and multi-language support
- **v1.2.0** - Enhanced dashboard and reporting features

---

**Made with ❤️ by Chokchey Development Team**