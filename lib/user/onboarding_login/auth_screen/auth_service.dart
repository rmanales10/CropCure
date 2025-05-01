import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cropcure/user/onboarding_login/auth_screen/signin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get user => _auth.currentUser;

  // Register method
  Future<String> registerUser(
    String email,
    String fullname,
    String password,
  ) async {
    try {
      // Register the user
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Fetch IP Address using a public API
      String ipAddress = await _getIpAddress();

      // Get the current timestamp (signup time)
      DateTime signupDate = DateTime.now();

      // Log the user details in Firestore under 'users' collection
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'password': password,
        'fullname': fullname,
        'created_at': signupDate,
        'ip_address': ipAddress,
        'status': 'online', // User is online at the time of registration
      });

      // Log the registration activity
      await _logActivity(userCredential.user!.uid, 'User registered', email,
          ipAddress, signupDate, 'online');

      await sendEmailVerification();
      return 'Registration successful! Please check your email for verification.';
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'An error occurred during registration.';
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    User? user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
      await _logActivity(user.uid, 'Email verification sent', user.email ?? '',
          '', DateTime.now(), 'online');
    }
  }

  // Sign-in method with email and password
  Future<String> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      User? user = userCredential.user;

      if (user != null) {
        // Fetch IP Address using a public API
        String ipAddress = await _getIpAddress();

        // Get current timestamp
        DateTime currentTime = DateTime.now();

        // Check if the email is verified
        if (!user.emailVerified) {
          return 'Please verify your email before logging in.';
        }

        // Log the user activity (sign-in)
        await _logActivity(user.uid, 'User signed in', email, ipAddress,
            currentTime, 'online');

        // Update the user's status in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'status': 'online',
        }, SetOptions(merge: true));

        return 'Sign in successful!';
      } else {
        return 'No user found.';
      }
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'An error occurred during sign-in.';
    }
  }

  // Check if the user is verified
  bool isEmailVerified() {
    User? user = _auth.currentUser;
    return user != null && user.emailVerified;
  }

  // Log user activity (including IP address, date, time, and status)
  Future<void> _logActivity(String userId, String action, String email,
      String ipAddress, DateTime timestamp, String status) async {
    try {
      await _firestore.collection('activity_logs').doc(user!.uid).set({
        'user_id': userId,
        'action': action,
        'email': email,
        'ip_address': ipAddress,
        'timestamp': timestamp,
        'status': status,
      }, SetOptions(merge: true));
    } catch (e) {
      log('Error logging activity: $e');
    }
  }

  // Get user's IP address (you can use a third-party service or API)
  Future<String> _getIpAddress() async {
    try {
      // Make a request to an external service that provides IP address
      final response =
          await http.get(Uri.parse('https://api.ipify.org?format=json'));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        return data['ip']; // Return the IP address
      } else {
        return 'Unable to fetch IP'; // Handle errors
      }
    } catch (e) {
      log('Error fetching IP address: $e');
      return 'Unknown IP'; // Fallback in case of an error
    }
  }

  // Detect when the user signs out (change status to offline)
  Future<void> signOut() async {
    User? user = _auth.currentUser;
    if (user != null) {
      // Log the sign-out activity
      await _logActivity(user.uid, 'User signed out', user.email ?? '', '',
          DateTime.now(), 'offline');

      // Update the user status to offline in Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'status': 'offline',
      }, SetOptions(merge: true));

      // Perform sign out
      await _auth.signOut();
      Get.offAll(() => const LoginPage());
      Get.snackbar('Success', 'User logged out successfully');
    }
  }
}
