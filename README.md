# 🎓 AlumniConnect

<div align="center">

A modern cross-platform alumni networking platform built with **Flutter**, **Firebase**, and **Supabase**.

Connect • Collaborate • Grow

</div>

---

## 📖 Overview

AlumniConnect is a mobile application designed to bridge the gap between alumni, students, and faculty members by providing a centralized platform for networking, communication, career opportunities, and institutional engagement.

Instead of relying on fragmented communication channels like WhatsApp groups, emails, and social media, AlumniConnect creates a dedicated ecosystem exclusively for educational institutions.

---

## ✨ Features

### 👤 User Management
- Secure Authentication
- Profile Setup
- Role-Based Access
- Alumni & Staff Verification
- Profile Management

### 💬 Real-Time Chat
- One-to-One Messaging
- Image Sharing
- PDF Sharing
- Read Receipts
- Unread Message Count
- Real-Time Updates

### 🎓 Alumni Directory
- Search Alumni
- Professional Profiles
- Graduation Year
- Company Information
- Contact Details

### 👨‍🏫 Staff Directory
- Faculty Profiles
- Department Information
- Easy Communication

### 💼 Job Portal
- Job Listings
- Save Jobs
- Career Opportunities
- Alumni Referrals

### 📅 Events
- Upcoming Events
- Event Details
- RSVP Support
- Institution Announcements

### 🔔 Notifications
- Push Notifications
- Chat Notifications
- Event Alerts
- Job Updates

### 🌙 UI Features
- Light Theme
- Dark Theme
- Responsive Design
- Modern Material UI

---

# 🛠 Tech Stack

## Frontend

- Flutter
- Dart
- Provider

## Backend

- Firebase Authentication
- Cloud Firestore
- Firebase Cloud Messaging (FCM)

## Storage

- Supabase Storage

## Packages

- provider
- firebase_auth
- cloud_firestore
- firebase_messaging
- supabase_flutter
- image_picker
- image_cropper
- file_picker
- flutter_local_notifications
- table_calendar
- shimmer

---

# 🏗 Architecture

```
Flutter App
     │
     ▼
 Provider State Management
     │
     ▼
Service Layer
     │
 ┌────┴───────────────┐
 │                    │
 ▼                    ▼
Firebase          Supabase
 │                    │
 ▼                    ▼
Authentication     File Storage
Cloud Firestore
FCM
```

---

# 📂 Project Structure

```
lib/
│
├── auth/
├── models/
├── providers/
├── screens/
│   ├── login
│   ├── register
│   ├── home
│   ├── chat
│   ├── jobs
│   ├── events
│   ├── profile
│   └── settings
│
├── services/
├── widgets/
├── utils/
└── main.dart
```

---

# 🚀 Getting Started

## Prerequisites

- Flutter SDK
- Dart SDK
- Android Studio / VS Code
- Firebase Project
- Supabase Project

---

## Installation

Clone the repository

```bash
git clone https://github.com/yourusername/alumniconnect.git
```

Move into the project

```bash
cd alumniconnect
```

Install dependencies

```bash
flutter pub get
```

Run the project

```bash
flutter run
```

---

# 🔥 Firebase Configuration

Create a Firebase project and enable:

- Authentication
- Cloud Firestore
- Firebase Cloud Messaging

Download

- google-services.json
- GoogleService-Info.plist

Place them inside the Android and iOS folders respectively.

---

# ☁ Supabase Configuration

Create a Supabase project.

Create a storage bucket:

```
alumni-files
```

Update your credentials inside the project:

```dart
const supabaseUrl = "YOUR_SUPABASE_URL";
const supabaseAnonKey = "YOUR_SUPABASE_ANON_KEY";
```

---

# 📱 Screens

- Splash Screen
- Login
- Register
- Profile Setup
- Home
- Alumni Directory
- Staff Directory
- Chat
- Jobs
- Events
- Notifications
- Settings

---

# 🔐 Security

- Firebase Authentication
- Role-Based Access Control
- Firestore Security Rules
- Secure File Storage
- Verified Staff Accounts

---

# 🎯 Future Improvements

- AI Job Recommendation
- AI Alumni Matching
- Group Chat
- Video Calling
- Mentorship Portal
- Internship Portal
- Alumni Donations
- QR Event Check-in
- Web Dashboard
- Admin Analytics

---

# 📊 Performance

- ⚡ Cross Platform
- ⚡ Real-Time Database
- ⚡ Optimized State Management
- ⚡ Cloud Storage
- ⚡ Push Notifications
- ⚡ Responsive UI

---

# 🤝 Contributing

Contributions are welcome.

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push the branch
5. Open a Pull Request

---

# 📄 License

This project is developed for educational and research purposes.

---

# 👨‍💻 Author

**Alagu Aadithan A**

Bachelor of Computer Applications

Flutter Developer | Mobile App Developer

---

## ⭐ Show your support

If you like this project, don't forget to give it a ⭐ on GitHub!
