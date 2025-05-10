import 'package:cropcure/admin/activitylog.dart';
import 'package:cropcure/admin/login.dart';
import 'package:cropcure/user/home/home.dart';
import 'package:cropcure/user/onboarding_login/auth_screen/signin.dart';
import 'package:cropcure/user/onboarding_login/auth_screen/signup.dart';
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
 

  runApp(kIsWeb ? ActivityLogApp() : const MyApp());
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
        '/forgot': (context) => const ForgotPasswordPage(),
        '/profile': (context) => const ProfilePage(),
        // '/disease': (context) => const PlantDiseasePage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}

class ActivityLogApp extends StatelessWidget {
  const ActivityLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Crop Cure',
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const MyLogin(),
        '/activity': (context) => ActivityLogScreen(),
      },
    );
  }
}
