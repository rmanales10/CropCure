import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:cropcure/user/onboarding_login/auth_screen/auth_service.dart';
import 'package:cropcure/user/profile/profile_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _controller = Get.put(ProfileController());
  final _auth = Get.put(AuthService());
  final isEdit = false.obs;
  String? base64Image;
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    initProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 50),
              // Back button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Spacer(),
                  GestureDetector(
                    onTap: _auth.signOut,
                    child: const Icon(Icons.logout, color: Colors.black),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                "Profile Settings",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Your Profile",
                style: TextStyle(color: Colors.black, fontSize: 16),
              ),
              const SizedBox(height: 30),

              // Profile Avatar with Edit Icon
              Stack(
                children: [
                  Obx(() {
                    _controller.fetchUserInfo();
                    try {
                      Uint8List? imageBytess = base64Decode(
                        _controller.userInfo['base64image'],
                      );
                      return ClipOval(
                        child: Image.memory(
                          imageBytess,
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                        ),
                      );
                    } catch (e) {
                      return ClipOval(
                        child: Image.asset(
                          'assets/images/2.jpg',
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                        ),
                      );
                    }
                  }),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: pickImageAndProcess,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: const Color.fromARGB(255, 15, 129, 19),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: const Icon(
                          Icons.edit,
                          color: Color.fromARGB(255, 15, 129, 19),
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Obx(
                () => buildInputField(
                  'Full Name',
                  _nameController,
                  enable: isEdit.value,
                ),
              ),
              const SizedBox(height: 16),
              buildInputField('Email', _emailController),
              const SizedBox(height: 16),

              // Save Button
              GestureDetector(
                onTap: () async {
                  isEdit.value = !isEdit.value;
                  if (!isEdit.value) {
                    await _controller.editName(_nameController.text);
                  }
                },
                child: Obx(
                  () => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        color:
                            isEdit.value
                                ? const Color.fromARGB(255, 9, 46, 94)
                                : const Color.fromARGB(255, 15, 129, 19),
                      ),
                      child: Center(
                        child: Text(
                          isEdit.value ? 'Done' : "Edit",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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

  // Reusable Input Field Widget
  Widget buildInputField(
    String label,
    TextEditingController controller, {
    bool enable = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color.fromARGB(255, 15, 129, 19),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color.fromARGB(255, 15, 129, 19),
              width: 2,
            ),
          ),
          child: TextFormField(
            enabled: enable,
            controller: controller,
            cursorColor: Colors.black,
            style: const TextStyle(color: Colors.black),
            decoration: const InputDecoration(
              hintStyle: TextStyle(color: Colors.black),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> initProfile() async {
    await _controller.fetchUserInfo();
    setState(() {
      _nameController.text = _controller.userInfo['fullname'];
      _emailController.text = _controller.userInfo['email'];
    });
  }

  Future<void> pickImageAndProcess() async {
    final ImagePicker picker = ImagePicker();

    try {
      // Pick an image from gallery
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile != null) {
        // Check if the platform is Web
        if (kIsWeb) {
          // Web: Use 'readAsBytes' to process the picked image
          final Uint8List webImageBytes = await pickedFile.readAsBytes();

          setState(() {
            _imageBytes = webImageBytes;
            base64Image = base64Encode(
              webImageBytes,
            ); // Store base64 image if needed
          });

          log("Image selected on Web: ${webImageBytes.lengthInBytes} bytes");
        } else {
          // Native (Android/iOS): Use File to get image bytes
          final File nativeImageFile = File(pickedFile.path);

          // Ensure that the file exists
          if (await nativeImageFile.exists()) {
            final Uint8List nativeImageBytes =
                await nativeImageFile.readAsBytes();

            setState(() {
              _imageBytes = nativeImageBytes;
              base64Image = base64Encode(nativeImageBytes);
            });
            await _controller.storeImage(base64Image!);
            log("Image selected on Native: ${nativeImageFile.path}");
          } else {
            log("File does not exist: ${pickedFile.path}");
          }
        }
      } else {
        log("No image selected.");
      }
    } catch (e) {
      log("Error picking image: $e");
    }
  }
}
