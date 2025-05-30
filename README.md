# 🚌 School Bus Tracking App

<p align="center">
  <img src="images/app_logo.png" alt="School Bus Tracker Logo" width="150">
</p>

A comprehensive, cross-platform mobile application built with Flutter and Firebase, designed to connect parents and school bus drivers for safe, efficient, and worry-free student transportation. This app offers real-time bus tracking, attendance management, secure communication, payment processing, and a robust password reset system, ensuring a seamless experience for all stakeholders.

## 📋 Table of Contents

- [Overview](#overview)
- [Key Features](#key-features)
- [Screenshots](#screenshots)
- [Technology Stack](#technology-stack)
- [Architecture](#architecture)
- [Installation](#installation)
- [Firebase Setup](#firebase-setup)
- [Google Maps Integration](#google-maps-integration)
- [Usage Guide](#usage-guide)
- [Database Structure](#database-structure)
- [Security Rules](#security-rules)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## 🌟 Overview

The School Bus Tracking App addresses the challenges of managing daily school transportation by providing a unified platform for parents, students, and bus drivers. With real-time location tracking, attendance management, secure communication, payment processing, and a user-friendly password reset system, the app enhances safety, improves communication, and streamlines the transportation experience. Built with Flutter for cross-platform compatibility and Firebase for backend services, this app ensures a robust, scalable, and secure solution.

## 🔑 Key Features

### Authentication & User Management
- **Multi-role Login System**: Separate interfaces for parents and bus drivers
- **User Registration**: Email-based signup with role selection (Parent or Bus Driver)
- **Password Recovery**: Secure password reset via email with advanced debugging capabilities
- **User Profiles**: Management of personal information (name, email, phone, etc.)
- **Authentication Security**: Firebase Authentication with email verification
- **Session Management**: Auto-login, secure logout, and session timeout for inactivity

### Parent Features
#### Bus Tracking
- **Real-time Bus Location**: Track school buses on Google Maps with live updates
- **Multiple Bus Selection**: Choose from available active buses to track
- **Bus Stop Information**: View designated bus stops on the map with ETA
- **Location History**: Access recent bus movements for the current day

#### Attendance Management
- **Mark Absences**: Schedule student absences in advance using a calendar interface
- **Calendar Interface**: Visual calendar for selecting absence dates with `table_calendar`
- **Absence Reasons**: Document reasons for student absences with validation
- **Attendance Records**: View historical absence data with filtering options

#### Communication
- **Driver Information**: View bus driver contact details (name, phone)
- **Notification Center**: Receive real-time alerts from drivers
- **Emergency Contact**: Quick access to emergency numbers with one-tap calling
- **Direct Messaging**: Contact bus drivers via SMS or phone calls using `url_launcher`

#### Payment System
- **Bus Fee Payment**: Secure credit card processing for monthly fees
- **Payment History**: Track payment records with timestamps and statuses
- **Monthly Billing**: Manage recurring transportation fees with reminders

### Bus Driver Features
#### Location Sharing
- **Real-time Location Broadcasting**: Share current location with parents using Geolocator
- **Route Tracking**: Follow optimized bus routes with Google Maps integration
- **Bus Stop Navigation**: View upcoming stops on the route with navigation prompts
- **Location Controls**: Start/stop location sharing with toggle controls

#### Student & Parent Management
- **Student Roster**: View list of students assigned to the route
- **Attendance Tracking**: See which students are absent in real-time
- **Parent Contact Information**: Access parent details (name, phone, email)
- **Contact Options**: Call or message parents directly via `url_launcher`

#### Notifications & Alerts
- **Send Announcements**: Broadcast messages to all parents on the route
- **Emergency Alerts**: Send urgent notifications with priority
- **Predefined Templates**: Use templates for common messages (delays, early arrivals, etc.)
- **Targeted Messages**: Send messages to specific parents with Firebase Cloud Messaging

### Technical Features
- **Offline Support**: Basic functionality when offline (viewing cached data)
- **Location Permissions**: Proper handling of device location access with user consent
- **Firebase Integration**: Real-time database, authentication, and cloud functions
- **Google Maps API**: Accurate mapping and location services for tracking
- **Cross-platform**: Works on both iOS and Android with a single codebase
- **Secure Data Storage**: Protected user information with Firestore security rules
- **Push Notifications**: Real-time alerts and messages via Firebase Cloud Messaging
- **Responsive Design**: Optimized for various device sizes and orientations

### Administrative Features
- **User Data Management**: Store and access user information securely
- **Firestore Database**: Structured data storage with real-time updates
- **Analytics**: Track app usage and feature adoption via Firebase Analytics

## 📱 Screenshots

<p align="center">
  <img src="screenshots/login_screen.png" width="200" alt="Login Screen">
  <img src="screenshots/parent_tracking.png" width="200" alt="Parent Tracking Screen">
  <img src="screenshots/driver_location.png" width="200" alt="Driver Location Screen">
  <img src="screenshots/attendance.png" width="200" alt="Attendance Management">
  <img src="screenshots/forgot_password.png" width="200" alt="Forgot Password Screen">
</p>

## 🛠 Technology Stack

### Frontend
- **Flutter**: UI framework for cross-platform development
- **Dart**: Programming language for Flutter
- **Google Maps Flutter**: Maps integration for real-time tracking
- **table_calendar**: Calendar widget for attendance management
- **url_launcher**: For handling phone calls and SMS
- **intl**: For date and time formatting

### Backend
- **Firebase Authentication**: User management and secure authentication
- **Cloud Firestore**: NoSQL database for real-time data storage
- **Firebase Cloud Messaging**: For push notifications and alerts
- **Firebase Security Rules**: Data access control and security

### APIs
- **Google Maps API**: For location tracking, mapping, and route optimization
- **Geolocator**: For accessing device location services

## 🏗 Architecture

The app follows a feature-based architecture with Firebase as the backend:
lib/
├── authentication/     # Authentication flows (login, signup, password reset)
│   ├── login_page.dart
│   ├── signup_page.dart
│   └── forgot_password_screen.dart
├── models/            # Data models
│   ├── user.dart
│   ├── student.dart
│   ├── absence.dart
│   └── payment.dart
├── screens/           # UI screens
│   ├── parent/        # Parent-specific screens
│   │   ├── tracking_page.dart
│   │   ├── absent_dates.dart
│   │   └── payment_page.dart
│   ├── driver/        # Driver-specific screens
│   │   ├── location_sharing.dart
│   │   └── student_parent_info.dart
│   └── common/        # Shared screens
│       ├── notifications.dart
│       └── emergency_contacts.dart
├── services/          # Firebase and API services
│   ├── auth_service.dart
│   ├── location_service.dart
│   └── notification_service.dart
├── utils/             # Helper utilities
│   ├── constants.dart
│   └── validators.dart
└── widgets/           # Reusable UI components
├── custom_button.dart
├── loading_indicator.dart
└── error_message.dart

text

Copy

## 📥 Installation

### Prerequisites
- Flutter SDK (v3.10.0 or higher)
- Dart SDK (v3.3.0 or higher)
- Android Studio or VS Code
- Firebase account
- Google Maps API key

### Setup Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/school-bus-tracking-app.git
   cd school-bus-tracking-app
Install dependencies
bash

Copy
flutter pub get
Configure Firebase and Google Maps
Follow the and sections below.
Run the app
bash

Copy
flutter run
🔥 Firebase Setup
Create a Firebase Project
Go to Firebase Console.
Click "Add project" and follow the setup wizard.
Configure Firebase Authentication
In Firebase Console, go to "Authentication" > "Sign-in method".
Enable Email/Password authentication.
Set Up Firestore Database
Go to "Firestore Database" and create a database.
Start in production mode and choose a location closest to your users.
Add Firebase to Your App
In Firebase Console, go to "Project settings".
Add an Android app (package name: com.example.tt1):
Download google-services.json and place it in android/app/.
Add an iOS app if needed:
Download GoogleService-Info.plist and place it in ios/Runner/.
Enable Firebase Cloud Messaging
In Firebase Console, go to "Cloud Messaging" and enable it.
Add your app’s server key to your app for push notifications (if needed).
🗺 Google Maps Integration
Get a Google Maps API Key
Go to Google Cloud Console.
Create a new project or select an existing one.
Enable Google Maps API and Places API.
Create credentials to get your API key.
Add API Key to Android
Open android/app/src/main/AndroidManifest.xml.
Add the following inside the <application> tag:
xml

Copy
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY_HERE"/>
Add API Key to iOS
Open ios/Runner/AppDelegate.swift.
Update it to include:
swift

Copy
import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_API_KEY_HERE")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
📱 Usage Guide
For Parents
Login / Registration
Sign up with your email and select the "Parent" role.
Complete your profile with your child’s information.
Track Your Child’s Bus
From the home screen, tap "Track Buses".
Select your child’s bus from the list of active buses.
View real-time location and estimated arrival time on Google Maps.
Mark Absences
Navigate to "Absent Dates".
Use the calendar to select dates when your child will be absent.
Add a reason for the absence (optional).
View and manage upcoming absences.
Communication
Access "Notifications & Emergency" to view driver alerts.
Use emergency contacts for immediate assistance.
Send messages or call bus drivers directly.
Payment Management
View payment history and upcoming payment details.
Process monthly bus fees securely.
For Bus Drivers
Login / Registration
Sign up with your email and select the "Bus Driver" role.
Complete your profile with contact details and bus information.
Share Location
From the driver home screen, tap "Location".
Tap "Share" to start broadcasting your location to parents.
View bus stops on your route with navigation.
Student Management
Access "Students & Parents" to view your student roster.
Check which students are marked absent in real-time.
View parent contact information for communication.
Send Notifications
Use "Alerts & Emergency" to:
Send broadcast messages to all parents.
Use templates for common notifications (e.g., delays).
Target specific parents with individual messages.
Send emergency alerts when needed.
🗄 Database Structure
The app uses the following Firestore collections:

users
Document ID: User's Firebase Auth UID
Fields:
json

Copy
{
  "fullName": "Parent Name",
  "email": "parent@gmail.com",
  "phone": "+1-555-123-4567",
  "role": "Parent",
  "createdAt": "2025-05-11T10:00:00Z"
}
students
Document ID: Auto-generated (e.g., student_1)
Fields:
json

Copy
{
  "name": "Child Name",
  "parentId": "8JtifILZcvQpXxnsNqlKn0HOpga2",
  "classroom": "Grade 5",
  "address": "123 Main St"
}
drivers
Document ID: Driver's Firebase Auth UID
Fields:
json

Copy
{
  "name": "Driver Name",
  "phone": "+1-555-987-6543",
  "bus": "Bus #1",
  "rating": 4.8,
  "latitude": 37.7749,
  "longitude": -122.4194,
  "lastUpdated": "2025-05-11T10:00:00Z"
}
shared_locations
Document ID: Auto-generated
Fields:
json

Copy
{
  "driverId": "driver_uid",
  "link": "https://maps.google.com/?q=lat,lng",
  "isActive": true,
  "busName": "Bus #1",
  "timestamp": "2025-05-11T10:00:00Z"
}
absences
Document ID: Auto-generated (e.g., absence_1)
Fields:
json

Copy
{
  "date": "2025-05-11T00:00:00Z",
  "studentId": "student_1",
  "studentName": "Child Name",
  "parentId": "8JtifILZcvQpXxnsNqlKn0HOpga2",
  "reason": "Sick",
  "createdAt": "2025-05-11T10:00:00Z"
}
notifications
Document ID: Auto-generated
Fields:
json

Copy
{
  "message": "Bus delayed by 10 minutes",
  "time": "10:00 AM",
  "date": "2025-05-11",
  "sender": "driver_uid",
  "senderType": "Driver",
  "senderName": "Driver Name",
  "recipient": "parent_uid",
  "recipientId": "8JtifILZcvQpXxnsNqlKn0HOpga2",
  "isRead": false,
  "timestamp": "2025-05-11T10:00:00Z"
}
payments
Document ID: Auto-generated
Fields:
json

Copy
{
  "userId": "parent_uid",
  "cardholderName": "Parent Name",
  "amount": 120.00,
  "timestamp": "2025-05-11T10:00:00Z",
  "status": "completed"
}
🔒 Security Rules
Security is a priority in this application. The Firestore security rules ensure proper access control:

plaintext

Copy
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /drivers/{driverId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == driverId;
    }
    match /shared_locations/{driverId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == driverId;
    }
    match /bus_stops/{stopId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == "admin_user_id";
    }
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    match /notifications/{notificationId} {
      allow read: if request.auth != null &&
                  (resource.data.recipientId == request.auth.uid || resource.data.senderType == 'Driver');
      allow write: if request.auth != null &&
                   request.auth.uid == resource.data.sender;
    }
    match /payments/{paymentId} {
      allow read: if request.auth != null && request.auth.uid == resource.data.userId;
      allow write: if request.auth != null && request.auth.uid == paymentId;
    }
    match /students/{studentId} {
      allow read: if request.auth != null &&
                  (request.auth.uid == resource.data.parentId ||
                   exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
                   get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'Bus Driver');
      allow write: if request.auth != null && request.auth.uid == "admin_user_id";
    }
    match /absences/{absenceId} {
      allow read: if request.auth != null &&
                  (request.auth.uid == resource.data.parentId ||
                   exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
                   get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'Bus Driver');
      allow create: if request.auth != null &&
                    request.auth.uid == request.resource.data.parentId;
      allow update, delete: if request.auth != null &&
                            request.auth.uid == resource.data.parentId;
    }
  }
}
Security Features
Authentication Security:
Email verification required for new users.
Secure password reset process with retry logic.
Session timeouts for inactive users.
Data Access Control:
Parents can only access their own children’s data.
Drivers can only access their assigned routes/students.
Firestore security rules enforce these restrictions.
Location Data Protection:
Location sharing requires explicit driver action.
Location history is limited to the current day and is not stored permanently.
⚠️ Troubleshooting
Common Issues
Password Reset Emails Not Received
Check Spam/Junk Folders: Emails might be flagged as spam.
Verify Email: Ensure the email is registered in Firebase Authentication.
Debug Logs: Long-press the "Send Reset Link" button in the Forgot Password screen to view debug info.
Firebase Email Settings: Check Firebase Console > Authentication > Email Templates for correct sender settings.
Email Provider: Add noreply@your-firebase-project.firebaseapp.com to your email provider’s safe senders list.
Location Tracking Not Working
Ensure location permissions are granted in device settings.
Check if GPS is enabled on the device.
Verify that the driver has started sharing their location.
For Android: Disable battery optimization for the app to allow background location updates.
Firebase Permission Denied Errors
Verify Firestore security rules match the provided rules above.
Ensure parentId in students and absences matches the user’s UID.
Check user roles in the users collection (e.g., "role": "Parent").
Google Maps Not Displaying
Verify the Google Maps API key is correctly added to AndroidManifest.xml (Android) and AppDelegate.swift (iOS).
Ensure the Maps SDK for Android/iOS is enabled in Google Cloud Console.
Check for billing issues with your Google Cloud account.
Push Notifications Not Received
Ensure Firebase Cloud Messaging is enabled in Firebase Console.
Verify the device token is registered for notifications.
Check notification permissions in device settings.
🤝 Contributing
Contributions are welcome! Here’s how you can contribute:

Fork the Repository
Create a Feature Branch
bash

Copy
git checkout -b feature/amazing-feature
Commit Your Changes
bash

Copy
git commit -m 'Add some amazing feature'
Push to the Branch
bash

Copy
git push origin feature/amazing-feature
Open a Pull Request
Please ensure your code follows the project’s style guidelines, includes tests, and adheres to the Contributor Covenant Code of Conduct.

📄 License
This project is licensed under the MIT License - see the  file for details.

Dependency Licenses
Flutter & Dart: Licensed under the BSD 3-Clause License.
Firebase (Google): Subject to Google’s Terms of Service and Privacy Policy.
Google Maps API: Subject to Google’s Terms of Service and Privacy Policy.
table_calendar: Licensed under the Apache 2.0 License.
url_launcher: Licensed under the BSD 3-Clause License.
intl: Licensed under the BSD 3-Clause License.
All dependencies are compatible with the MIT License, ensuring the project can be distributed under MIT. Ensure compliance with Google’s terms for Firebase and Google Maps API usage, including proper attribution and billing setup.


  Developed with ❤️ for safe student transportation