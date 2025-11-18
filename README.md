# ימי סיירות - איו״ש (Sairot Shifts)

A Flutter-based web application for managing instructor shifts and scheduling for events. This application helps organize and assign instructors to specific days during events, with features for managing instructor availability, preferences, and automated shift assignment.

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Technology Stack](#technology-stack)
- [Project Structure](#project-structure)
- [Setup & Installation](#setup--installation)
- [Configuration](#configuration)
- [Firebase Setup](#firebase-setup)
- [Development](#development)
- [Deployment](#deployment)
- [Best Practices](#best-practices)
- [Security](#security)
- [Contributing](#contributing)

## 🎯 Overview

This application is designed to manage shift scheduling for instructors during events (ימי סיירות). It provides:

- Event creation and management
- Instructor management with availability constraints
- Automated shift assignment algorithm
- Calendar-based shift visualization
- Reports and exports
- Multi-platform support (Web, Android, iOS)

## ✨ Features

### Core Functionality
- **Event Management**: Create and manage multiple events with custom date ranges
- **Instructor Management**: Add, edit, and remove instructors with their preferences
- **Shift Assignment**: Automated algorithm for assigning instructors to shifts based on:
  - Maximum days per instructor
  - Days off preferences
  - Instructor availability
- **Calendar View**: Visual calendar interface for viewing and managing shifts
- **Reports**: Generate reports and export data (CSV, PDF)
- **Admin Controls**: Role-based access with admin functionality

### User Interface
- RTL (Right-to-Left) support for Hebrew interface
- Responsive design for web and mobile
- Calendar-based date selection
- Real-time updates using Firebase

## 🛠 Technology Stack

- **Framework**: Flutter (Dart)
- **Backend**: Firebase (Firestore, Hosting)
- **State Management**: GetX
- **Key Packages**:
  - `cloud_firestore`: Database operations
  - `firebase_core`: Firebase initialization
  - `table_calendar`: Calendar UI
  - `get`: State management and routing
  - `intl`: Internationalization and date formatting
  - `csv`: CSV export functionality
  - `file_saver`: File download capabilities
  - `screenshot`: Screenshot functionality for reports

## 📁 Project Structure

```
shifts/
├── lib/
│   ├── main.dart                 # Main application entry point
│   ├── utils.dart                # Instructor model and utilities
│   ├── exchange.dart             # Data exchange controller
│   ├── create_new_event.dart     # Event creation UI
│   ├── db_create_new_event.dart  # Event database operations
│   ├── run_shifts_builder_algo.dart  # Shift assignment algorithm
│   ├── shifts_table_view.dart    # Shift table visualization
│   ├── reports.dart              # Reporting functionality
│   └── ...                       # Other UI components
├── web/                          # Web-specific files
│   ├── index.html                # Web entry point
│   └── manifest.json             # PWA manifest
├── android/                      # Android platform files
├── ios/                          # iOS platform files
├── functions/                    # Firebase Cloud Functions
├── firebase.json                 # Firebase configuration (DO NOT COMMIT)
├── firestore.rules               # Firestore security rules
└── pubspec.yaml                  # Flutter dependencies
```

## 🚀 Setup & Installation

### Prerequisites

- Flutter SDK (>=2.17.5 <3.0.0)
- Dart SDK
- Firebase CLI
- Node.js (for Firebase Functions)

### Installation Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/haggaibb/sairot_shifts.git
   cd sairot_shifts
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Install Firebase Functions dependencies**
   ```bash
   cd functions
   npm install
   cd ..
   ```

4. **Configure Firebase** (See [Firebase Setup](#firebase-setup) section)

5. **Run the application**
   ```bash
   flutter run -d chrome  # For web
   flutter run            # For mobile (connect device/emulator)
   ```

## ⚙️ Configuration

### Environment Setup

Before running the application, you need to configure Firebase. **Important**: Never commit sensitive configuration files to version control.

### Required Configuration Files (Not in Repository)

The following files are excluded from version control and must be set up locally:

- `firebase.json` - Firebase project configuration
- `lib/firebase_options.dart` - Firebase platform-specific options
- `android/app/google-services.json` - Android Firebase configuration
- `ios/Runner/GoogleService-Info.plist` - iOS Firebase configuration
- `android/local.properties` - Android local build properties

## 🔥 Firebase Setup

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or use existing project
3. Enable Firestore Database
4. Enable Firebase Hosting (for web deployment)

### 2. Configure Firebase for Flutter

1. **Install FlutterFire CLI**
   ```bash
   dart pub global activate flutterfire_cli
   ```

2. **Configure Firebase**
   ```bash
   flutterfire configure
   ```
   This will generate `lib/firebase_options.dart` automatically.

3. **Download platform-specific configs**
   - Android: Download `google-services.json` from Firebase Console and place in `android/app/`
   - iOS: Download `GoogleService-Info.plist` and place in `ios/Runner/`

### 3. Firestore Security Rules

Update `firestore.rules` with appropriate security rules. The current rules are set to expire - **update them before production deployment**.

### 4. Firestore Indexes

The application may require composite indexes. Check `firestore.indexes.json` and deploy indexes:
```bash
firebase deploy --only firestore:indexes
```

## 💻 Development

### Running in Development Mode

```bash
# Web development
flutter run -d chrome --web-port=8080

# Mobile development
flutter run
```

### Building for Production

```bash
# Web build
flutter build web

# Android build
flutter build apk --release
# or
flutter build appbundle --release

# iOS build (macOS only)
flutter build ios --release
```

### Code Structure Best Practices

1. **State Management**: Uses GetX for state management
   - Controllers in `main.dart` (Controller class)
   - Reactive variables using `.obs` and `RxList`

2. **Data Models**: 
   - `Instructor` class in `utils.dart`
   - Firestore document structure follows consistent patterns

3. **Firestore Collections**:
   - `Events/{eventName}` - Event metadata
   - `Events/{eventName}/instructors` - Instructors for event
   - `Events/{eventName}/days` - Daily shift assignments
   - `System/config` - System-wide configuration

4. **Key Functions**:
   - `loadEventMetadata()` - Loads current event configuration
   - `runShiftsBuilderAlgo()` - Automated shift assignment
   - `dbCreateNewEvent()` - Creates new event in Firestore

## 🚢 Deployment

### Web Deployment to Firebase Hosting

1. **Build the web app**
   ```bash
   flutter build web
   ```

2. **Deploy to Firebase**
   ```bash
   firebase deploy --only hosting
   ```

   Or use the provided script:
   ```bash
   ./deploy.sh
   ```

### Mobile Deployment

- **Android**: Build APK or App Bundle and upload to Google Play Console
- **iOS**: Build and upload via Xcode or App Store Connect

## 📝 Best Practices

### Code Organization

1. **Separation of Concerns**:
   - UI components in separate files
   - Business logic in controllers
   - Database operations in dedicated files (e.g., `db_create_new_event.dart`)

2. **Naming Conventions**:
   - Use descriptive variable names
   - Follow Dart naming conventions (camelCase for variables, PascalCase for classes)
   - Use meaningful file names

3. **Error Handling**:
   - Always handle async operations with try-catch
   - Provide user feedback for errors
   - Log errors appropriately

### Firebase Best Practices

1. **Security Rules**:
   - Never allow public read/write access in production
   - Implement proper authentication
   - Use field-level security rules

2. **Data Structure**:
   - Keep documents small and focused
   - Use subcollections for related data
   - Index frequently queried fields

3. **Performance**:
   - Use pagination for large datasets
   - Implement proper indexing
   - Cache data when appropriate

### Git Workflow

1. **Branching Strategy**:
   - `main` branch for production-ready code
   - Feature branches for new features
   - Never commit sensitive data

2. **Commit Messages**:
   - Use clear, descriptive commit messages
   - Reference issue numbers when applicable

3. **Pull Requests**:
   - Review code before merging
   - Test thoroughly before merging to main

## 🔒 Security

### Sensitive Data Protection

**CRITICAL**: The following files contain sensitive information and are excluded from version control:

- `firebase.json` - Contains Firebase project configuration
- `lib/firebase_options.dart` - Contains Firebase API keys
- `android/app/google-services.json` - Android Firebase config
- `ios/Runner/GoogleService-Info.plist` - iOS Firebase config
- Any files containing API keys, passwords, or tokens

### Security Checklist

- [ ] Never commit `.gitignore` listed files
- [ ] Use environment variables for sensitive data when possible
- [ ] Regularly rotate API keys and credentials
- [ ] Review Firestore security rules regularly
- [ ] Implement proper authentication
- [ ] Use HTTPS for all network communications
- [ ] Keep dependencies updated for security patches

### Firestore Security Rules

**Current Status**: Rules are set to expire. **Update before production!**

Example secure rules structure:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Implement proper authentication and authorization
    match /Events/{eventId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                     request.auth.uid in resource.data.admin_ids;
    }
  }
}
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Follow Dart/Flutter style guidelines
- Write meaningful commit messages
- Test your changes thoroughly
- Update documentation as needed
- Ensure no sensitive data is committed

## 📄 License

This project is proprietary software developed by AtalefTech.

## 📞 Support

For issues, questions, or contributions, please open an issue on the GitHub repository.

## 🔄 Version History

- **v1.0.8** - Current version
  - Fixed Firestore query field name mismatch (`maxDays` → `max_days`)
  - Updated app name to "ימי סיירות - איו״ש"
  - Improved documentation

---

**Note**: This project uses Firebase for backend services. Ensure proper Firebase configuration before running the application. Never commit sensitive configuration files to version control.
