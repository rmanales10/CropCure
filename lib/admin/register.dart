import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RegistrationForm extends StatefulWidget {
  const RegistrationForm({super.key});

  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _roleController = TextEditingController(); // for admin role
  bool _isLoading = false;

  // Function to handle registration
  Future<void> _registerAdmin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get email and password from controllers
      final email = _emailController.text;
      final password = _passwordController.text;
      final name = _nameController.text;
      final role = _roleController.text;

      if (email.isEmpty || password.isEmpty || name.isEmpty || role.isEmpty) {
        _showErrorDialog('Please fill in all fields.');
        return;
      }

      // Firebase Authentication registration
      final UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // Store user information in Firestore
      final user = userCredential.user;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('admins')
            .doc(user.uid)
            .set({
          'name': name,
          'email': email,
          'role': role,
          'uid': user.uid,
        });

        _showSuccessDialog();
      }
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Success dialog
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Success'),
          content: const Text('Admin registered successfully!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Registration')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Register as Admin",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              // Name Field
              _buildInputField(
                controller: _nameController,
                hintText: "Full Name",
                icon: Icons.person,
                isPassword: false,
              ),
              const SizedBox(height: 20),
              // Email Field
              _buildInputField(
                controller: _emailController,
                hintText: "Email",
                icon: Icons.email,
                isPassword: false,
              ),
              const SizedBox(height: 20),
              // Password Field
              _buildInputField(
                controller: _passwordController,
                hintText: "Password",
                icon: Icons.lock,
                isPassword: true,
              ),
              const SizedBox(height: 20),
              // Role Field (Optional or predefined to 'Admin')
              _buildInputField(
                controller: _roleController,
                hintText: "Role (Admin)",
                icon: Icons.work,
                isPassword: false,
              ),
              const SizedBox(height: 30),
              // Register Button
              _isLoading
                  ? const CircularProgressIndicator()
                  : GestureDetector(
                      onTap: _registerAdmin,
                      child: Container(
                        height: 50,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            "Register",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // Input field widget
  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required bool isPassword,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, color: Colors.black),
        filled: true,
        fillColor: Colors.grey.shade200,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    );
  }
}
