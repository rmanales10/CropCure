# CropCure 🌱

**An AI-Powered Plant Disease Detection and Treatment Application**

CropCure is a comprehensive Flutter-based mobile application that helps users identify plant diseases, receive AI-powered treatment recommendations, and manage their plant health. The app features real-time image analysis using Google's Gemini AI, seamless user authentication, and an intuitive interface for tracking plant health over time.

---

## 📋 Table of Contents

- [Features](#features)
- [Technology Stack](#technology-stack)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Installation & Setup](#installation--setup)
- [Configuration](#configuration)
- [Running the Application](#running-the-application)
- [Architecture](#architecture)
- [Key Components](#key-components)
- [API Integration](#api-integration)
- [Firebase Setup](#firebase-setup)
- [Screenshots](#screenshots)
- [Contributing](#contributing)
- [License](#license)

---

## ✨ Features

### 🎯 Core Features

- **Plant Disease Detection**
  - Real-time camera-based plant scanning
  - AI-powered disease identification using Google Gemini
  - Automatic plant species recognition
  - Instant health status assessment

- **Treatment Recommendations**
  - Personalized treatment plans based on detected diseases
  - Step-by-step care instructions
  - Preventive measures and monitoring tips
  - Integration with AI chatbot for detailed guidance

- **Scan History Management**
  - Complete scan history with timestamps
  - Date range filtering capabilities
  - Paginated display for large datasets
  - Detailed view of each scan with treatment information
  - Visual indicators for healthy vs. diseased plants

- **AI Chatbot Assistant**
  - Interactive chatbot powered by Gemini AI
  - Answers questions about plant care, treatments, and tutorials
  - Persistent conversation history
  - Context-aware responses

- **User Authentication & Profile**
  - Email-based registration and login
  - SMS OTP verification for phone numbers
  - Secure password management
  - User profile with avatar support
  - Forgot password functionality

- **Daily Plant Care Reminders**
  - Personalized daily care tips
  - Watering and maintenance reminders
  - Plant-specific recommendations

- **Admin Dashboard (Web)**
  - Comprehensive analytics and statistics
  - User management
  - Plant scan data visualization
  - PDF report generation
  - Disease trend analysis

---

## 🛠 Technology Stack

### Frontend
- **Flutter** `^3.7.2` - Cross-platform mobile framework
- **Dart** - Programming language
- **GetX** `^4.7.2` - State management and dependency injection
- **fl_chart** `^1.0.0` - Data visualization

### Backend & Services
- **Firebase Core** `^3.13.0` - Backend infrastructure
- **Cloud Firestore** `^5.6.7` - NoSQL database
- **Firebase Auth** `^5.5.3` - Authentication service

### AI & Machine Learning
- **Google Generative AI** `^0.4.7` - Gemini AI integration
  - Gemini 2.5 Flash Lite (for image analysis)
  - Gemini 2.5 Flash (for text generation)

### Media & Utilities
- **Camera** `^0.11.1` - Camera access for plant scanning
- **Image Picker** `^0.8.9` - Image selection from gallery
- **Permission Handler** `^12.0.0+1` - Runtime permissions
- **Path Provider** `^2.1.5` - File system paths

### Communication
- **Mailer** `^6.0.1` - Email service (SMTP)
- **HTTP** - SMS API integration (Semaphore)

### Document Generation
- **PDF** `^3.11.1` - PDF generation
- **Printing** `^5.13.4` - PDF printing capabilities

### Additional
- **intl** `^0.20.2` - Internationalization and date formatting
- **Cupertino Icons** `^1.0.8` - iOS-style icons

---

## 📁 Project Structure

```
CropCure/
├── lib/
│   ├── admin/                    # Admin dashboard and features
│   │   ├── admin_dashboard_screen.dart
│   │   ├── admin_login.dart
│   │   ├── controller.dart
│   │   ├── pdf_service.dart
│   │   ├── register.dart
│   │   ├── views/                # Admin views
│   │   └── widgets/              # Admin widgets
│   │
│   ├── config/                   # Configuration files
│   │   ├── gemini_config.dart    # Gemini AI configuration
│   │   └── sms_config.dart       # SMS service configuration
│   │
│   ├── services/                 # External service integrations
│   │   ├── email_service.dart    # Email service (SMTP)
│   │   └── sms_service.dart       # SMS service (Semaphore)
│   │
│   ├── user/                     # User-facing features
│   │   ├── chatbot/              # AI chatbot
│   │   │   ├── chatbot_screen.dart
│   │   │   └── chatbot_controller.dart
│   │   │
│   │   ├── gemini/               # Gemini AI service
│   │   │   └── ai_service.dart
│   │   │
│   │   ├── home/                 # Home screen and navigation
│   │   │   ├── home.dart
│   │   │   ├── home_controller.dart
│   │   │   └── daily_reminder_controller.dart
│   │   │
│   │   ├── onboarding_login/      # Authentication screens
│   │   │   └── auth_screen/
│   │   │       ├── signin.dart
│   │   │       ├── signup.dart
│   │   │       └── otp_verification.dart
│   │   │
│   │   ├── plant_classification/  # Plant scanning features
│   │   │   ├── plant_camera_screen.dart
│   │   │   ├── plant_recognizer.dart
│   │   │   └── plant_controller.dart
│   │   │
│   │   └── profile/              # User profile
│   │       ├── profile.dart
│   │       └── profile_controller.dart
│   │
│   ├── firebase_options.dart      # Firebase configuration
│   └── main.dart                  # Application entry point
│
├── assets/                        # Static assets
│   ├── images/                    # Image assets
│   ├── icon/                      # App icons
│   └── background.png
│
├── android/                       # Android-specific files
├── ios/                           # iOS-specific files
├── web/                           # Web-specific files
├── pubspec.yaml                   # Dependencies and configuration
└── README.md                      # This file
```

---

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK** (version 3.7.2 or higher)
  - Download from [flutter.dev](https://flutter.dev/docs/get-started/install)
  - Verify installation: `flutter doctor`

- **Dart SDK** (included with Flutter)

- **Development IDE**
  - **VS Code** with Flutter extension (recommended)
  - **Android Studio** with Flutter plugin

- **Platform-specific requirements:**
  - **Android**: Android SDK (API level 23 or higher)
  - **iOS**: Xcode (for macOS only)
  - **Web**: Chrome browser for testing

- **Firebase Account**
  - Create at [firebase.google.com](https://firebase.google.com/)

- **API Keys** (see Configuration section)
  - Google Gemini API key
  - Semaphore SMS API key (for SMS verification)
  - Gmail SMTP credentials (for email service)

---

## 🚀 Installation & Setup

### 1. Clone the Repository

```bash
git clone <repository-url>
cd CropCure
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure Firebase

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Add your app to Firebase (Android/iOS/Web)
3. Download configuration files:
   - `google-services.json` → Place in `android/app/`
   - `GoogleService-Info.plist` → Place in `ios/Runner/`
4. Run FlutterFire CLI to generate `firebase_options.dart`:
   ```bash
   flutterfire configure
   ```

### 4. Configure API Keys

#### Google Gemini API Key

1. Get your API key from [Google AI Studio](https://ai.google.dev/gemini-api/docs/api-key)
2. Update `lib/config/gemini_config.dart`:
   ```dart
   static const String _fallbackApiKey = 'YOUR_API_KEY_HERE';
   ```
3. Alternatively, store the API key in Firestore:
   - Collection: `ai`
   - Document: `ai`
   - Field: `apiKey`

#### SMS Configuration (Semaphore)

1. Sign up at [Semaphore.co](https://semaphore.co)
2. Get your API key from account settings
3. Update `lib/config/sms_config.dart`:
   ```dart
   static const String semaphoreApiKey = 'YOUR_SEMAPHORE_API_KEY';
   ```

#### Email Service Configuration

1. Update `lib/services/email_service.dart` with your Gmail credentials:
   ```dart
   static const String _smtpUsername = 'your_email@gmail.com';
   static const String _smtpPassword = 'your_app_password';
   ```
   > **Note**: Use App Password for Gmail (enable 2FA first)

### 5. Run the Application

```bash
# Run on connected device/emulator
flutter run

# Run on specific platform
flutter run -d chrome          # Web
flutter run -d android         # Android
flutter run -d ios             # iOS
```

---

## ⚙️ Configuration

### Gemini AI Configuration

The app uses Google Gemini AI with different models for different tasks:

- **Image Analysis**: `gemini-2.5-flash-lite` (optimized for image recognition)
- **Text Generation**: `gemini-2.5-flash-lite` (for treatment recommendations)
- **General Tasks**: `gemini-2.5-flash` (for complex analysis)

**Rate Limiting**: The app implements cooldown periods to respect free tier limits:
- Image requests: 1 second cooldown
- Text requests: 2 seconds cooldown
- General requests: 2 seconds cooldown

Configuration is centralized in `lib/config/gemini_config.dart`.

### SMS Configuration

- **Provider**: Semaphore API
- **Sender Name**: ABESO
- **OTP Length**: 6 digits
- **OTP Validity**: 5 minutes
- **Max Resend Attempts**: 3

See `SMS_SETUP.md` for detailed SMS setup instructions.

### Email Configuration

- **Provider**: Gmail SMTP
- **Port**: 587 (TLS)
- **Use Case**: Welcome emails after account creation

---

## 🏃 Running the Application

### Mobile App (User Interface)

```bash
flutter run
```

The mobile app will launch with the following routes:
- `/` - Loading/Welcome screen
- `/signin` - Login page
- `/signup` - Registration page
- `/otp-verification` - OTP verification
- `/home` - Main home screen
- `/profile` - User profile

### Admin Dashboard (Web)

The admin dashboard runs automatically when the app is launched on web:

```bash
flutter run -d chrome
```

Admin credentials:
- Username: `admin`
- Password: `admin`

> **Note**: Change these credentials in production!

---

## 🏗 Architecture

### State Management

The app uses **GetX** for state management:
- Reactive state variables (`RxString`, `RxBool`, `RxList`)
- Controller-based architecture
- Dependency injection using `Get.put()` and `Get.find()`

### Design Pattern

- **MVC Pattern**: Models (Firestore), Views (UI), Controllers (GetX Controllers)
- **Service Layer**: Separate services for AI, SMS, Email
- **Repository Pattern**: Firestore as the data repository

### Key Controllers

- `HomeController` - Manages plant scan history and statistics
- `PlantRecognizer` - Handles AI-based plant and disease recognition
- `ChatbotController` - Manages chatbot conversations
- `ProfileController` - Handles user profile data
- `DailyReminderController` - Manages daily care reminders

---

## 🔑 Key Components

### Plant Recognition System

The plant recognition system (`PlantRecognizer`) performs three main tasks:

1. **Plant Identification**
   - Analyzes captured image
   - Identifies plant species
   - Returns plant name

2. **Disease Detection**
   - Examines plant for diseases/pests
   - Detects health issues
   - Classifies disease type

3. **Treatment Generation**
   - Generates personalized treatment plans
   - Provides care instructions
   - Suggests preventive measures

### AI Chatbot

The chatbot (`ChatbotController`) provides:
- Natural language interaction
- Context-aware responses
- Persistent conversation history
- Real-time streaming responses

### Scan History System

Features:
- Automatic saving of all scans to Firestore
- Date-based filtering
- Pagination (5 items per page)
- Detailed view with treatment information
- Health status indicators

### Authentication Flow

1. User registration with email and phone
2. SMS OTP verification
3. Email verification (optional)
4. Welcome email sent automatically
5. Secure login with Firebase Auth

---

## 🌐 API Integration

### Google Gemini AI API

**Endpoint**: Google Generative AI SDK

**Models Used**:
- `gemini-2.5-flash-lite` - Image and text processing
- `gemini-2.5-flash` - Complex analysis tasks

**Rate Limits** (Free Tier):
- Image requests: 15 per minute, 1,000 per day
- Text requests: 15 per minute, 1,000 per day
- General requests: 10 per minute, 250 per day

### Semaphore SMS API

**Endpoint**: `https://api.semaphore.co/api/v4/messages`

**Features**:
- OTP generation and delivery
- Philippine phone number support
- Automatic formatting (63 country code)

### Firebase Services

- **Firestore**: Plant scan data, user profiles, chatbot history
- **Firebase Auth**: User authentication and session management
- **Firebase Storage**: (Optional) Image storage

---

## 🔥 Firebase Setup

### Firestore Collections

1. **users**
   - User profile information
   - Avatar images (base64 encoded)

2. **plants**
   - Plant scan records
   - Fields: `userId`, `name`, `disease`, `treatment`, `timestamp`, `image`

3. **plant**
   - Detailed plant information
   - AI-generated treatment data

4. **ai** (Configuration)
   - Document: `ai`
   - Field: `apiKey` (Gemini API key)

5. **chatbot** (Optional)
   - Chatbot conversation history per user

### Security Rules

Ensure proper Firestore security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Plants can only be read/written by the owner
    match /plants/{plantId} {
      allow read, write: if request.auth != null && 
        resource.data.userId == request.auth.uid;
    }
  }
}
```

---

## 📱 Features in Detail

### Plant Disease Detection Workflow

1. **Image Capture**
   - User opens camera screen
   - Captures photo of plant leaf/affected area
   - Image converted to base64

2. **Plant Recognition**
   - AI analyzes image for plant species
   - Returns plant name

3. **Disease Detection**
   - AI examines image for diseases/pests
   - Detects health issues and abnormalities
   - Classifies disease type or confirms healthy status

4. **Treatment Generation**
   - AI generates personalized treatment plan
   - Provides step-by-step care instructions
   - Suggests preventive measures

5. **Data Storage**
   - Scan data saved to Firestore
   - Associated with user account
   - Timestamped for history tracking

### AI Chatbot Features

- **Natural Language Processing**: Understands user questions about plant care
- **Context Awareness**: Maintains conversation context
- **Real-time Responses**: Streaming responses for better UX
- **History Management**: Saves and loads conversation history
- **Clear Chat**: Option to reset conversation

### Admin Dashboard Capabilities

- **User Statistics**: Total users, active users
- **Scan Analytics**: Total scans, disease trends
- **Data Visualization**: Charts and graphs
- **Report Generation**: PDF export functionality
- **User Management**: View and manage user accounts

---

## 🧪 Testing

### Running Tests

```bash
flutter test
```

### Manual Testing Checklist

- [ ] User registration with email and phone
- [ ] SMS OTP verification
- [ ] Login functionality
- [ ] Plant scanning with camera
- [ ] Disease detection accuracy
- [ ] Treatment recommendation display
- [ ] Scan history viewing
- [ ] Date filtering in history
- [ ] AI chatbot interaction
- [ ] Profile management
- [ ] Admin dashboard access (web)
- [ ] PDF report generation

---

## 🐛 Troubleshooting

### Common Issues

1. **Firebase Connection Error**
   - Verify `google-services.json` is in correct location
   - Check Firebase configuration in `firebase_options.dart`
   - Ensure internet connectivity

2. **Gemini API Rate Limit**
   - Wait for cooldown period
   - Check API key validity
   - Verify Firestore API key configuration

3. **SMS Not Sending**
   - Verify Semaphore API key
   - Check SMS credits balance
   - Validate phone number format

4. **Camera Not Working**
   - Grant camera permissions
   - Check device camera availability
   - Restart app if needed

5. **Build Errors**
   - Run `flutter clean`
   - Run `flutter pub get`
   - Verify Flutter SDK version

---

## 📝 Development Notes

### Code Style

- Follow Flutter/Dart style guide
- Use meaningful variable names
- Add comments for complex logic
- Maintain consistent indentation

### Git Workflow

1. Create feature branch
2. Make changes
3. Test thoroughly
4. Commit with descriptive messages
5. Push and create pull request

### Environment Variables

For sensitive data, consider using:
- `.env` file (with `flutter_dotenv`)
- Environment variables
- Secure storage solutions

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is part of a capstone project. All rights reserved.

---

## 👥 Authors

- **Development Team** - CropCure Capstone Project
- **Institution** - [Your Institution Name]

---

## 🙏 Acknowledgments

- Google Gemini AI for plant disease detection capabilities
- Firebase for backend infrastructure
- Semaphore for SMS services
- Flutter team for the amazing framework
- Open-source community for various packages

---

## 📞 Support

For issues and questions:
- Create an issue in the repository
- Contact the development team
- Refer to documentation files (SMS_SETUP.md, etc.)

---

## 🔮 Future Enhancements

- [ ] Offline mode support
- [ ] Plant disease database expansion
- [ ] Multi-language support
- [ ] Social sharing features
- [ ] Expert consultation integration
- [ ] Plant care calendar
- [ ] Community forum
- [ ] Plant health tracking graphs
- [ ] Push notifications
- [ ] Advanced analytics dashboard

---

**Made with ❤️ for plant lovers everywhere** 🌱
