import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cropcure/services/sms_service.dart';
import 'package:cropcure/config/sms_config.dart';
import 'package:cropcure/user/onboarding_login/auth_screen/auth_service.dart';

class OTPVerificationPage extends StatefulWidget {
  final String phoneNumber;
  final String email;
  final String fullName;
  final String password;

  const OTPVerificationPage({
    super.key,
    required this.phoneNumber,
    required this.email,
    required this.fullName,
    required this.password,
  });

  @override
  State<OTPVerificationPage> createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage> {
  late final List<TextEditingController> _otpControllers;
  late final List<FocusNode> _focusNodes;

  bool _isLoading = false;
  bool _isResending = false;
  String? _storedOTP;
  int _resendCount = 0;
  int _timerSeconds =
      SMSConfig.otpValidityMinutes * 60; // Convert minutes to seconds
  bool _timerActive = true;

  final AuthService _authService = Get.find<AuthService>();

  @override
  void initState() {
    super.initState();
    _otpControllers = List.generate(
      SMSConfig.otpLength,
      (index) => TextEditingController(),
    );
    _focusNodes = List.generate(SMSConfig.otpLength, (index) => FocusNode());
    _sendOTP();
    _startTimer();
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _timerActive) {
        setState(() {
          _timerSeconds--;
        });
        if (_timerSeconds > 0) {
          _startTimer();
        } else {
          _timerActive = false;
        }
      }
    });
  }

  Future<void> _sendOTP() async {
    setState(() {
      _isLoading = true;
    });

    final result = await SMSService.sendOTP(widget.phoneNumber);

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      _storedOTP = result['otp_code'];
      Get.snackbar(
        'Success',
        'OTP sent to ${widget.phoneNumber}',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Error',
        result['message'],
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _resendOTP() async {
    if (_resendCount >= SMSConfig.maxResendAttempts) {
      Get.snackbar(
        'Error',
        'Maximum resend attempts reached. Please try again later.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isResending = true;
    });

    await _sendOTP();

    setState(() {
      _isResending = false;
      _resendCount++;
      _timerSeconds = SMSConfig.otpValidityMinutes * 60;
      _timerActive = true;
    });

    _startTimer();
  }

  void _verifyOTP() async {
    String enteredOTP =
        _otpControllers.map((controller) => controller.text).join();

    if (enteredOTP.length != SMSConfig.otpLength) {
      Get.snackbar(
        'Error',
        'Please enter complete OTP code',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (enteredOTP == _storedOTP) {
      // OTP is correct, proceed with registration
      setState(() {
        _isLoading = true;
      });

      String result = await _authService.registerUserWithSMS(
        widget.email,
        widget.fullName,
        widget.password,
        widget.phoneNumber,
      );

      setState(() {
        _isLoading = false;
      });

      if (result.contains('successful')) {
        Get.snackbar(
          'Success',
          'Account created successfully! You can now sign in.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        Get.offAllNamed('/signin');
      } else {
        Get.snackbar(
          'Error',
          result,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } else {
      Get.snackbar(
        'Error',
        'Invalid OTP code. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(children: [_buildHeader(), _buildForm()]),
      ),
    );
  }

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
            Image.asset("assets/images/3.png", height: 100),
          ],
        ),
      ),
    );
  }

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
                "Verify Phone Number",
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 15, 129, 19),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                "We sent a verification code to\n${widget.phoneNumber}",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 30),
            _buildOTPInput(),
            const SizedBox(height: 20),
            _buildVerifyButton(),
            const SizedBox(height: 20),
            _buildResendSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildOTPInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(SMSConfig.otpLength, (index) {
        return SizedBox(
          width: 45,
          height: 55,
          child: TextFormField(
            controller: _otpControllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color.fromARGB(255, 15, 129, 19),
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color.fromARGB(255, 15, 129, 19),
                  width: 2,
                ),
              ),
            ),
            onChanged: (value) {
              if (value.isNotEmpty) {
                if (index < SMSConfig.otpLength - 1) {
                  _focusNodes[index + 1].requestFocus();
                } else {
                  _focusNodes[index].unfocus();
                }
              } else {
                if (index > 0) {
                  _focusNodes[index - 1].requestFocus();
                }
              }
            },
          ),
        );
      }),
    );
  }

  Widget _buildVerifyButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _verifyOTP,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 15, 129, 19),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child:
            _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                  "Verify OTP",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
      ),
    );
  }

  Widget _buildResendSection() {
    return Center(
      child: Column(
        children: [
          if (_timerActive)
            Text(
              "Resend code in ${_formatTime(_timerSeconds)}",
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            )
          else
            TextButton(
              onPressed: _isResending ? null : _resendOTP,
              child:
                  _isResending
                      ? const CircularProgressIndicator()
                      : const Text(
                        "Resend OTP",
                        style: TextStyle(
                          color: Color.fromARGB(255, 15, 129, 19),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
          if (_resendCount > 0)
            Text(
              "Resend attempts: $_resendCount/${SMSConfig.maxResendAttempts}",
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
