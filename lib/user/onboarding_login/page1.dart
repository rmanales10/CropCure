import 'dart:async';
import 'package:cropcure/user/home/bottom_navigation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Schedule navigation to the next page after 3 seconds
    Timer(const Duration(seconds: 3), () {
      final FirebaseAuth auth = FirebaseAuth.instance;
      if (auth.currentUser != null) {
        // User is already aukathenticated, navigate to homepage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BottomNavigation()),
        );
      } else {
        // User is not authenticated, navigate to sign-in page
        Navigator.pushNamed(context, '/welcome');
      }
    });

    return Scaffold(
      backgroundColor: Colors.white, // Background color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Centered image
            Container(
              width: 150, // Set the width of the image
              height: 150, // Set the height of the image
              decoration: BoxDecoration(
                image: const DecorationImage(
                  image: AssetImage(
                    "assets/images/3.png",
                  ), // Path to your image
                  fit: BoxFit.contain,
                ),
                borderRadius: BorderRadius.circular(75), // Rounded shape
              ),
            ),
            const SizedBox(height: 20), // Spacing between image and loader
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
            const SizedBox(height: 10),
            // Loading text
            const Text(
              "Loading...",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
