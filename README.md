# AI Todo - Flutter Frontend

A modern, AI-powered todo application built with Flutter. Features intelligent task management, natural language processing, and smart notifications.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## 📱 Screenshots

### Authentication
<table>
  <tr>
    <td><img width="429" height="874" alt="image" src="https://github.com/user-attachments/assets/de63fc8d-4631-4d8d-9e2a-5503d8a4da73" />
</td>
    <td><img width="429" height="874" alt="image" src="https://github.com/user-attachments/assets/3fbfd540-e722-4ecc-a52b-2fbd20ec7277" />
</td>
  </tr>
  <tr>
    <td align="center"><b>Login Screen</b></td>
    <td align="center"><b>Register Screen</b></td>
  </tr>
</table>

### Dashboard & Tasks
<table>
  <tr>
    <td><img width="376" height="817" alt="image" src="https://github.com/user-attachments/assets/ac2d6555-5512-40b0-befb-41f6b1e4c069" />
</td>
    <td><img width="376" height="817" alt="image" src="https://github.com/user-attachments/assets/a98014e0-b17f-4b1a-a162-ea89eb4679b7" />
</td>
    <td><img width="376" height="817" alt="image" src="https://github.com/user-attachments/assets/02ec929d-9918-4720-b959-5e5c3986b04e" />
</td>
  </tr>
  <tr>
    <td align="center"><b>Dashboard View</b></td>
    <td align="center"><b>Task Details</b></td>
    <td align="center"><b>Create Task</b></td>
  </tr>
</table>

### AI Assistant
<table>
  <tr>
    <td><img width="376" height="817" alt="image" src="https://github.com/user-attachments/assets/5b3908fc-64e9-46f7-8b46-385152cf03a1" />
</td>
    <td><img width="376" height="817" alt="image" src="https://github.com/user-attachments/assets/4a2a90e1-019b-4d62-bbfe-898f1e5e80bb" />
</td>
    <td><img width="376" height="817" alt="image" src="https://github.com/user-attachments/assets/f0261b57-28f3-4dcd-8ff4-b9716dc96b74" />
</td>
  </tr>
  <tr>
    <td align="center"><b>AI Assistant</b></td>
    <td align="center"><b>Daily Summary</b></td>
    <td align="center"><b>AI Task Creation</b></td>
  </tr>
</table>

### Notifications & Schedule
<table>
  <tr>
    <td><img width="385" height="776" alt="image" src="https://github.com/user-attachments/assets/81d98b19-1da7-49fb-bffd-08c9605082fe" />
</td>
  </tr>
  <tr>
    <td align="center"><b>Schedule Blocks</b></td>
  </tr>
</table>

## ✨ Features

### 🎯 Core Features
- **Task Management** - Create, edit, complete, and delete tasks
- **Smart Dashboard** - Day-by-day task view with swipe navigation
- **Task Types**
  - One-time tasks (specific date/time)
  - Daily recurring tasks
  - Weekly recurring tasks (select weekdays)
  - Schedule blocks (school, work hours)
- **Time Conflict Detection** - Warns about overlapping schedules
- **Priority Levels** - Low, Medium, High, Critical

### 🤖 AI-Powered Features
- **Natural Language Processing** - "Remind me to call mom tomorrow at 5pm"
- **Daily Summary** - Get intelligent overview of your day
- **Task Breakdown** - AI converts projects into actionable tasks
- **Smart Prioritization** - AI suggests optimal task order
- **Productivity Analysis** - Pattern detection and insights
- **Conflict Detection** - AI warns about scheduling issues

### 🔔 Smart Notifications
- **Local Notifications** - Cross-platform (Android, iOS, Web)
- **Time-based Reminders** - Get notified at task time
- **Recurring Reminders** - Daily and weekly notifications
- **Background Sync** - Notifications work even when app is closed
- **Platform-Adaptive** - Native notifications on each platform

### 🎨 User Experience
- **Material Design 3** - Modern, beautiful UI
- **Dark/Light Theme Support**
- **Responsive Layout** - Works on phones and tablets
- **Smooth Animations** - Delightful interactions
- **Pull-to-Refresh** - Easy data synchronization
- **Offline-First** - Works without internet (with sync)

## 🏗️ Architecture

```
lib/
├── main.dart                    # App entry point
├── app.dart                     # Root app widget
│
├── screens/                     # UI Screens
│   ├── login_screen.dart        # Authentication
│   ├── register_screen.dart     # User registration
│   ├── dashboard_screen.dart    # Main task dashboard
│   ├── todo_editor_screen.dart  # Create/Edit tasks
│   ├── ai_screen.dart           # AI assistant
│   └── schedule_screen.dart     # Schedule blocks
│
├── services/                    # Business Logic
│   ├── auth_service.dart        # Authentication API
│   ├── todo_service.dart        # Task CRUD operations
│   ├── ai_service.dart          # AI API integration
│   ├── notification_service.dart # Push notifications
│   └── schedule_validator.dart  # Conflict detection
│
├── widgets/                     # Reusable Components
│   ├── todo_card.dart           # Task display card
│   ├── auth_scaffold.dart       # Auth page template
│   ├── centered_text_field.dart # Form input
│   └── animated_submit_button.dart
│
└── utils/                       # Helpers
    └── date_helper.dart         # Date manipulation
```

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Network & Storage
  http: ^1.5.0
  shared_preferences: ^2.1.0
  
  # Notifications
  flutter_local_notifications: ^19.4.2
  timezone: ^0.10.1
  permission_handler: ^11.2.0
  
  # UI & Formatting
  intl: ^0.20.2
  cupertino_icons: ^1.0.8
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.x or higher
- Dart 3.x or higher
- Android Studio / VS Code
- iOS development setup (for iOS builds)

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/ai-todo-frontend.git
cd ai-todo-frontend
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Configure backend URL**

Edit `lib/services/auth_service.dart` and update the base URL:
```dart
static const String baseUrl = 'http://YOUR_BACKEND_URL:3000';
```

Update in all service files:
- `lib/services/auth_service.dart`
- `lib/services/todo_service.dart`
- `lib/services/ai_service.dart`

4. **Run the app**
```bash
# Run on connected device/emulator
flutter run

# Run on specific device
flutter devices
flutter run -d device_id

# Run on Chrome (for web testing)
flutter run -d chrome
```

## 📱 Platform-Specific Setup

### Android

1. **Update `android/app/build.gradle`**
```gradle
android {
    compileSdkVersion 34
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}
```

2. **Update `android/app/src/main/AndroidManifest.xml`**
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE"/>
```

3. **Build APK**
```bash
flutter build apk --release
```

### iOS

1. **Update `ios/Podfile`**
```ruby
platform :ios, '13.0'
```

2. **Update `ios/Runner/Info.plist`**
```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

3. **Install pods**
```bash
cd ios
pod install
cd ..
```

4. **Build IPA**
```bash
flutter build ios --release
```

### Web

1. **Build for web**
```bash
flutter build web --release
```

2. **Deploy** the `build/web` folder to your hosting service

**Note:** Web notifications require HTTPS (except localhost)

## 🔧 Configuration

### Notification Setup

Notifications are configured in `lib/main.dart`:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notifications
  await NotificationService.initialize();
  await NotificationService.requestPermissions();
  
  runApp(MyApp());
}
```

### Theme Customization

Edit `lib/app.dart` to customize colors:

```dart
theme: ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.deepPurple, // Change this
  ),
)
```

## 🧪 Testing

### Run tests
```bash
flutter test
```

### Test on real device
```bash
# Android
flutter run --release

# iOS
flutter run --release
```

### Check for issues
```bash
flutter doctor
flutter analyze
```

## 📊 Performance

- **App Size**: ~15 MB (release APK)
- **Startup Time**: <2 seconds
- **Memory Usage**: ~50-80 MB
- **Network Calls**: Optimized with caching
- **Notification Latency**: <1 second

## 🐛 Troubleshooting

### Common Issues

**"Unable to connect to backend"**
- Check backend is running (`npm run dev`)
- Verify `baseUrl` in service files
- For Android emulator, use `10.0.2.2` instead of `localhost`

**"Notifications not working"**
- Check permissions granted in device settings
- Android 13+: Ensure POST_NOTIFICATIONS permission
- iOS: Check notification settings in iOS Settings app

**"Build failed"**
```bash
flutter clean
flutter pub get
flutter run
```

## 📝 Best Practices

- **State Management**: Using StatefulWidget with proper lifecycle
- **Error Handling**: All API calls wrapped in try-catch
- **Loading States**: User feedback during async operations
- **Input Validation**: Client-side + server-side validation
- **Security**: JWT tokens stored in SharedPreferences
- **Performance**: Lazy loading, pagination, caching

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author
**NIraj Paradava**
## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Material Design team for design guidelines
- Community contributors

## 📞 Support

For issues and questions:
- Open an issue on GitHub
- Email: nirajparadva2004@gmail.com

---

**Built with ❤️ using Flutter**
