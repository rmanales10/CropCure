import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'auth_service.dart'; // Import the AuthService

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isAgreed = false;
  final AuthService _authService = Get.put(AuthService());

  // Controllers for text inputs
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _fullname = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(children: [_buildHeader(), _buildForm()]),
      ),
    );
  }

  // Header Section with back button and logo
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 15, 129, 19),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 20.0, left: 20, right: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            Image.asset(
              "assets/images/3.png", // Logo image
              height: 100,
            ),
          ],
        ),
      ),
    );
  }

  // Form Section for user input
  Widget _buildForm() {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                "Create new account",
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 15, 129, 19),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildTextField("Full Name", hintText: "", controller: _fullname),
            const SizedBox(height: 10),
            _buildTextField(
              "Email",
              hintText: "",
              controller: _emailController,
            ),
            const SizedBox(height: 10),
            _buildPasswordField(
              "Password",
              isPasswordVisible: _isPasswordVisible,
              controller: _passwordController,
            ),
            const SizedBox(height: 10),
            _buildPasswordField(
              "Confirm Password",
              isPasswordVisible: _isConfirmPasswordVisible,
              controller: _confirmPasswordController,
            ),
            const SizedBox(height: 10),
            _buildTermsCheckbox(),
            const SizedBox(height: 10),
            _buildSignUpButton(),
          ],
        ),
      ),
    );
  }

  // Reusable TextField widget
  Widget _buildTextField(
    String label, {
    required String hintText,
    TextEditingController? controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
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
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 15,
              horizontal: 20,
            ),
          ),
        ),
      ],
    );
  }

  // Reusable Password Field widget
  Widget _buildPasswordField(
    String label, {
    required bool isPasswordVisible,
    TextEditingController? controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          obscureText: !isPasswordVisible,
          decoration: InputDecoration(
            hintText: '',
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
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 15,
              horizontal: 20,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.black,
              ),
              onPressed: () {
                setState(() {
                  if (label == "Password") {
                    _isPasswordVisible = !_isPasswordVisible;
                  } else {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  }
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  // Terms and Privacy Checkbox widget
  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Checkbox(
          value: _isAgreed,
          activeColor: const Color.fromARGB(255, 15, 129, 19),
          onChanged: (value) {
            setState(() {
              _isAgreed = value!;
            });
          },
        ),
        const Text("I agree with the "),
        GestureDetector(
          onTap: () {
            _showPrivacyPolicyDialog();
          },
          child: const Text(
            "Privacy Policy and Terms",
            style: TextStyle(
              color: Color.fromARGB(255, 15, 129, 19),
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  // Sign-up Button widget
  Widget _buildSignUpButton() {
    return GestureDetector(
      onTap: () async {
        if (_isAgreed) {
          if (_confirmPasswordController.text == _passwordController.text) {
            String result = await _authService.registerUser(
              _emailController.text,
              _fullname.text,
              _confirmPasswordController.text,
            );

            if (result.contains('successful')) {
              Get.snackbar('Success', 'Verification email sent!');
              Navigator.pushNamed(context, '/signin');
            } else {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(result)));
            }
          } else {
            Get.snackbar('Error', 'Contfirm password must be the same');
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please agree to the terms and conditions'),
            ),
          );
        }
      },
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 15, 129, 19),
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Center(
          child: Text(
            "Create Account",
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // Show Privacy Policy Dialog
  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return SingleChildScrollView(
          child: AlertDialog(
            title: const Text("Privacy Policy and Terms"),
            content: const Text(
              "By creating an account, you agree to the collection, processing, and storage of your personal data as outlined in the Data Privacy Act of 2012. "
              "The following rights are provided to safeguard your privacy:\n\n"
              "1. The Right to Be Informed\n"
              "You have the right to be informed about the collection, processing, and storage of your personal data. This includes the purpose of data collection, the types of personal data being collected, the recipients or categories of recipients who may have access to your data, and the period for which your data will be stored. Consent will be obtained when necessary.\n\n"
              "2. The Right to Access\n"
              "You have the right to obtain a copy of your personal data held by the organization, along with additional details about how it is being used or processed. Organizations must respond to these requests within 30 days and provide information in a clear and understandable format.\n\n"
              "3. The Right to Object\n"
              "You can object to the processing of your personal data if it is based on consent or legitimate business interest.\n\n"
              "4. The Right to Erasure or Blocking\n"
              "You have the right to withdraw or request the removal of your personal data when your rights are violated.\n\n"
              "5. The Right to Damages\n"
              "You can claim compensation for damages caused by unlawfully obtained or unauthorized use of your personal data.\n\n"
              "The Data Privacy Act ensures compliance with international data protection standards."
              "\n\nFor more details, please read our full privacy policy.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("Close"),
              ),
            ],
          ),
        );
      },
    );
  }
}
