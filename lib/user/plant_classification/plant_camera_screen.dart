import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:cropcure/user/gemini/ai_service.dart';
import 'package:cropcure/user/home/bottom_navigation.dart';
import 'package:cropcure/user/plant_classification/plant_recognizer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

// Add the following dependencies to your pubspec.yaml:
// camera: ^0.10.0+4
// path_provider: ^2.0.11
// Also, make sure to run `flutter pub get` after adding them.

class PlantCameraScreen extends StatefulWidget {
  final void Function(String base64Image)? onImageCaptured;
  const PlantCameraScreen({super.key, this.onImageCaptured});

  @override
  State<PlantCameraScreen> createState() => _PlantCameraScreenState();
}

class _PlantCameraScreenState extends State<PlantCameraScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  final _plantRecognizer = Get.put(PlantRecognizer());
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  Timer? _recognitionTimer;
  final RxBool _isRecognizing = false.obs;
  final RxBool _isDetectingDisease = false.obs;
  bool _hasPlantDetected = false;
  String _currentPlantName = '';
  String _currentDiseaseName = '';
  String _base64Image = '';
  final _aiService = Get.put(AiService());
  RxBool isclicked = false.obs;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Start recognition when camera is initialized
    ever(_isRecognizing, (bool isRecognizing) {
      if (isRecognizing) {
        _startRecognition();
      } else {
        _stopRecognition();
      }
    });

    // Listen to plant detection results
    ever(_plantRecognizer.hasPlantDetected, (bool hasPlant) {
      if (hasPlant) {
        print('Plant detected: ${_plantRecognizer.plantName.value}');
      }
    });

    // Listen to disease detection results
    ever(_plantRecognizer.diseaseName, (String diseaseName) {
      if (diseaseName.isNotEmpty) {
        print('Disease detected: $diseaseName');
        _isDetectingDisease.value = false;
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _animationController.dispose();
    _stopRecognition();
    _resetDetection();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _controller = CameraController(_cameras![0], ResolutionPreset.medium);
        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
          // Start recognition immediately after camera initialization
          _isRecognizing.value = true;
        }
      }
    } catch (e) {
      print('Error initializing camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to initialize camera. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startRecognition() {
    if (_recognitionTimer != null) return;

    // Start with an initial delay of 0
    Future.delayed(Duration.zero, () async {
      if (_controller == null ||
          !_controller!.value.isInitialized ||
          !_isRecognizing.value) {
        return;
      }

      try {
        final XFile file = await _controller!.takePicture();
        final bytes = await file.readAsBytes();
        final image = base64Encode(bytes);

        // Try to recognize the plant
        await _plantRecognizer.recognizePlant(image);

        // Update local variables with recognition results
        setState(() {
          _hasPlantDetected = _plantRecognizer.hasPlantDetected.value;
          _currentPlantName = _plantRecognizer.plantName.value;
          _base64Image = image;
        });

        // If plant is detected, stop recognition and start disease detection
        if (_hasPlantDetected) {
          _isRecognizing.value = false;
          _stopRecognition();
          _startDiseaseDetection();
        }
      } catch (e) {
        print('Error during recognition: $e');
      }
    });

    // Set up the periodic timer for every 2 seconds
    _recognitionTimer = Timer.periodic(const Duration(seconds: 2), (
      timer,
    ) async {
      if (_controller == null ||
          !_controller!.value.isInitialized ||
          !_isRecognizing.value) {
        return;
      }

      try {
        final XFile file = await _controller!.takePicture();
        final bytes = await file.readAsBytes();
        final image = base64Encode(bytes);

        // Try to recognize the plant
        await _plantRecognizer.recognizePlant(image);

        // Update local variables with recognition results
        setState(() {
          _hasPlantDetected = _plantRecognizer.hasPlantDetected.value;
          _currentPlantName = _plantRecognizer.plantName.value;
          _base64Image = image;
        });

        // If plant is detected, stop recognition and start disease detection
        if (_hasPlantDetected) {
          _isRecognizing.value = false;
          _stopRecognition();
          _startDiseaseDetection();
        }
      } catch (e) {
        print('Error during recognition: $e');
      }
    });
  }

  void _stopRecognition() {
    _recognitionTimer?.cancel();
    _recognitionTimer = null;
    _isRecognizing.value = false;
  }

  void _startDiseaseDetection() async {
    if (_isDetectingDisease.value) return;

    _isDetectingDisease.value = true;

    try {
      if (_controller != null && _controller!.value.isInitialized) {
        // Wait for 2 seconds before taking the picture for disease detection
        await Future.delayed(const Duration(seconds: 2));

        final XFile file = await _controller!.takePicture();
        final bytes = await file.readAsBytes();
        final image = base64Encode(bytes);

        // Call disease classification
        await _plantRecognizer.classifyPlantDisease(image);

        // Update local disease variable and store the final image
        setState(() {
          _currentDiseaseName = _plantRecognizer.diseaseName.value;
          _isDetectingDisease.value = false;
          _base64Image = image;
        });
      }
    } catch (e) {
      print('Error during disease detection: $e');
      if (mounted) {
        setState(() {
          _isDetectingDisease.value = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to detect disease. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _resetDetection() {
    _plantRecognizer.plantName.value = '';
    _plantRecognizer.diseaseName.value = '';
    _plantRecognizer.hasPlantDetected.value = false;
    _plantRecognizer.hasDiseaseDetected.value = false;
    _isDetectingDisease.value = false;
  }

  // Add a method to start new detection
  void startNewDetection() {
    setState(() {
      _hasPlantDetected = false;
      _currentPlantName = '';
      _currentDiseaseName = '';
      _base64Image = '';
    });
    _isRecognizing.value = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body:
          _isCameraInitialized
              ? Stack(
                children: [
                  Positioned.fill(child: CameraPreview(_controller!)),
                  // Gradient overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.3),
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black.withOpacity(0.5),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Corner brackets overlay
                  Center(
                    child: SizedBox(
                      width: 250,
                      height: 250,
                      child: CustomPaint(painter: CornerBracketPainter()),
                    ),
                  ),
                  // Results display
                  Positioned(
                    top: 50,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.local_florist,
                                color: Colors.green,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child:
                                    _hasPlantDetected
                                        ? Text(
                                          'Plant: $_currentPlantName',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                        : Row(
                                          children: [
                                            SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.green),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'Recognizing...',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                              ),
                            ],
                          ),
                          if (_isDetectingDisease.value) ...[
                            const SizedBox(height: 10),
                            const Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.green,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Analyzing for diseases...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ] else if (_currentDiseaseName.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color:
                                    _currentDiseaseName.toLowerCase() ==
                                            'no disease detected'
                                        ? Colors.green.withOpacity(0.2)
                                        : Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _currentDiseaseName.toLowerCase() ==
                                            'no disease detected'
                                        ? Icons.check_circle
                                        : Icons.warning,
                                    color:
                                        _currentDiseaseName.toLowerCase() ==
                                                'no disease detected'
                                            ? Colors.green
                                            : Colors.orange,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _currentDiseaseName.toLowerCase() ==
                                                  'no disease detected'
                                              ? 'Plant is Healthy'
                                              : 'Disease Detected',
                                          style: TextStyle(
                                            color:
                                                _currentDiseaseName
                                                            .toLowerCase() ==
                                                        'no disease detected'
                                                    ? Colors.green
                                                    : Colors.orange,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (_currentDiseaseName.toLowerCase() !=
                                            'no disease detected')
                                          Text(
                                            _currentDiseaseName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (_hasPlantDetected && _currentDiseaseName.isNotEmpty)
                    Positioned(
                      bottom: 30,
                      left: 40,
                      right: 40,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          isclicked.value = true;
                          try {
                            await _aiService.response(
                              label: _currentPlantName,
                              disease: _currentDiseaseName,
                              image: _base64Image,
                            );

                            // Show snackbar first
                            Get.snackbar(
                              'Success',
                              'Treatment is being fetched',
                            );

                            // Wait a bit before navigating back
                            await Future.delayed(
                              const Duration(milliseconds: 500),
                            );
                            Get.off(() => BottomNavigation());
                          } catch (e) {
                            isclicked.value = false;
                            Get.snackbar(
                              'Error',
                              'Failed to fetch treatment. Please try again.',
                            );
                          }
                        },
                        icon: const Icon(Icons.healing, color: Colors.white),
                        label:
                            isclicked.value == true
                                ? CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                )
                                : Text(
                                  'Get Treatment',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 6,
                          shadowColor: Colors.greenAccent,
                        ),
                      ),
                    ),
                ],
              )
              : const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                ),
              ),
    );
  }
}

class CornerBracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke;

    const double bracketLength = 32;
    const double inset = 6; // gap from the edge

    // Top-left
    canvas.drawLine(
      Offset(inset, inset),
      Offset(inset + bracketLength, inset),
      paint,
    );
    canvas.drawLine(
      Offset(inset, inset),
      Offset(inset, inset + bracketLength),
      paint,
    );

    // Top-right
    canvas.drawLine(
      Offset(size.width - inset, inset),
      Offset(size.width - inset - bracketLength, inset),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - inset, inset),
      Offset(size.width - inset, inset + bracketLength),
      paint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(inset, size.height - inset),
      Offset(inset + bracketLength, size.height - inset),
      paint,
    );
    canvas.drawLine(
      Offset(inset, size.height - inset),
      Offset(inset, size.height - inset - bracketLength),
      paint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(size.width - inset, size.height - inset),
      Offset(size.width - inset - bracketLength, size.height - inset),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - inset, size.height - inset),
      Offset(size.width - inset, size.height - inset - bracketLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
