import 'package:cropcure/admin/admin_dashboard_screen.dart';
import 'package:cropcure/admin/admin_login.dart';
import 'package:cropcure/user/home/home.dart';
import 'package:cropcure/user/onboarding_login/auth_screen/signin.dart';
import 'package:cropcure/user/onboarding_login/auth_screen/signup.dart';
import 'package:cropcure/user/onboarding_login/auth_screen/otp_verification.dart';
import 'package:cropcure/user/onboarding_login/forgot_password_page.dart';
import 'package:cropcure/user/onboarding_login/page1.dart';
import 'package:cropcure/user/onboarding_login/page2.dart';
import 'package:cropcure/user/profile/profile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(kIsWeb ? AdminDashboardApp() : const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Crop Cure',
      debugShowCheckedModeBanner: false,

      initialRoute: '/',
      routes: {
        '/': (context) => const LoadingPage(),
        '/welcome': (context) => const WelcomePage(),
        '/signin': (context) => const LoginPage(),
        '/signup': (context) => const CreateAccountPage(),
        '/otp-verification':
            (context) => const OTPVerificationPage(
              phoneNumber: '',
              email: '',
              fullName: '',
              password: '',
            ),
        '/forgot': (context) => const ForgotPasswordPage(),
        '/profile': (context) => const ProfilePage(),
        // '/disease': (context) => const PlantDiseasePage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}

class AdminDashboardApp extends StatelessWidget {
  const AdminDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'CropCure Admin Dashboard',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => const AdminLogin()),
        GetPage(name: '/dashboard', page: () => const AdminDashboardScreen()),
      ],
    );
  }
}
