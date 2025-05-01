import 'package:cropcure/user/home/bottom_navigation.dart';
import 'package:cropcure/user/onboarding_login/auth_screen/auth_service.dart';
import 'package:cropcure/user/onboarding_login/auth_screen/signup.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = Get.put(AuthService());

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Logo
            Stack(
              children: [
                // Image Section
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: Container(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                      image: DecorationImage(
                        image: AssetImage("assets/images/2.jpg"),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                // Logo Positioned at Top-Right
                Positioned(
                  top: 10,
                  right: 0,
                  child: Image.asset("assets/images/3.png", height: 100),
                ),
              ],
            ),
            // Form Section with Proper BorderRadius
            Container(
              color: Colors.white,
              padding: EdgeInsets.only(
                top: 30,
                left: 30,
                right: 30,
                bottom: 100,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      "Login to your account",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 15, 129, 19),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Username Field
                  const Text(
                    "Email",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  TextFormField(
                    controller: _emailController,
                    cursorColor: const Color.fromARGB(255, 15, 129, 19),
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: "",
                      hintStyle: const TextStyle(color: Colors.black),
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: Color.fromARGB(255, 15, 129, 19),
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: Color.fromARGB(255, 15, 129, 19),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Password Field
                  const Text(
                    "Password",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    cursorColor: const Color.fromARGB(255, 15, 129, 19),
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: "",
                      hintStyle: const TextStyle(color: Colors.black),
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: Color.fromARGB(255, 15, 129, 19),
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: Color.fromARGB(255, 15, 129, 19),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 20,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.black,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),

                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/forgot');
                      },
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(
                          color: Color.fromARGB(255, 15, 129, 19),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Error message
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ),

                  // Login Button
                  GestureDetector(
                    onTap:
                        _isLoading
                            ? null
                            : () async {
                              setState(() {
                                _isLoading = true;
                                _errorMessage = '';
                              });
                              String email = _emailController.text;
                              String password = _passwordController.text;

                              String result = await _authService
                                  .signInWithEmailPassword(email, password);

                              if (result == 'Sign in successful!') {
                                Get.offAll(() => BottomNavigation());
                                Get.snackbar(
                                  'Success',
                                  'User Logged Successfully',
                                );
                              } else {
                                setState(() {
                                  _errorMessage = result;
                                });
                              }

                              _isLoading = false;
                            },
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 15, 129, 19),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child:
                          _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : const Center(
                                child: Text(
                                  "Login",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Sign-up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account?",
                        style: TextStyle(fontSize: 14, color: Colors.black),
                      ),
                      TextButton(
                        onPressed: () => Get.to(() => CreateAccountPage()),
                        child: const Text(
                          "Sign Up",
                          style: TextStyle(
                            color: Color.fromARGB(255, 15, 129, 19),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
