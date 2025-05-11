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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, const Color(0xFFF5F5F5)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Header with Logout
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Profile",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: _auth.signOut,
                          icon: const Icon(
                            Icons.logout_rounded,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Profile Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Profile Avatar with Edit Icon
                        Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Obx(() {
                                _controller.fetchUserInfo();
                                try {
                                  Uint8List? imageBytess = base64Decode(
                                    _controller.userInfo['base64image'],
                                  );
                                  return ClipOval(
                                    child: Image.memory(
                                      imageBytess,
                                      height: 120,
                                      width: 120,
                                      fit: BoxFit.cover,
                                      gaplessPlayback: true,
                                    ),
                                  );
                                } catch (e) {
                                  return ClipOval(
                                    child: Image.asset(
                                      'assets/images/2.jpg',
                                      height: 120,
                                      width: 120,
                                      fit: BoxFit.cover,
                                    ),
                                  );
                                }
                              }),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: pickImageAndProcess,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    color: Color(0xFF0F8113),
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Obx(
                          () => buildInputField(
                            'Full Name',
                            _nameController,
                            enable: isEdit.value,
                          ),
                        ),
                        const SizedBox(height: 20),
                        buildInputField('Email', _emailController),
                        const SizedBox(height: 24),

                        // Save Button
                        GestureDetector(
                          onTap: () async {
                            isEdit.value = !isEdit.value;
                            if (!isEdit.value) {
                              await _controller.editName(_nameController.text);
                            }
                          },
                          child: Obx(
                            () => Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  colors:
                                      isEdit.value
                                          ? [
                                            const Color(0xFF092E5E),
                                            const Color(0xFF0A3B7A),
                                          ]
                                          : [
                                            const Color(0xFF0F8113),
                                            const Color(0xFF0B9D0F),
                                          ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isEdit.value
                                            ? const Color(0xFF092E5E)
                                            : const Color(0xFF0F8113))
                                        .withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  isEdit.value
                                      ? 'Save Changes'
                                      : "Edit Profile",
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
            color: Color(0xFF0F8113),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF0F8113).withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: TextFormField(
            enabled: enable,
            controller: controller,
            cursorColor: const Color(0xFF0F8113),
            style: const TextStyle(color: Colors.black87, fontSize: 15),
            decoration: InputDecoration(
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
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
