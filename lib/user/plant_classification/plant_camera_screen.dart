import 'dart:convert';
import 'dart:developer';
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
  bool _hasDiseaseStored = false;
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

        // Try to recognize the plant and wait for the response
        await _plantRecognizer.recognizePlant(image);

        // Only update and display if we haven't detected a plant yet
        if (!_hasPlantDetected) {
          setState(() {
            _hasPlantDetected = _plantRecognizer.hasPlantDetected.value;
            _currentPlantName = _plantRecognizer.plantName.value;
            _base64Image = image;
          });

          // If a plant is detected, stop immediately and start disease detection
          if (_hasPlantDetected &&
              _currentPlantName.toLowerCase() != "no plant detected") {
            timer.cancel(); // Stop the timer immediately
            _isRecognizing.value = false;
            _stopRecognition();
            _startDiseaseDetection();
          }
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
    if (_isDetectingDisease.value || _hasDiseaseStored) return;

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
          _hasDiseaseStored = true;
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
    _hasDiseaseStored = false;
  }

  // Add a method to start new detection
  void startNewDetection() {
    setState(() {
      _hasPlantDetected = false;
      _currentPlantName = '';
      _currentDiseaseName = '';
      _base64Image = '';
      _hasDiseaseStored = false;
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
                      child: GestureDetector(
                        onTapDown: (_) => _animationController.forward(),
                        onTapUp: (_) => _animationController.reverse(),
                        onTapCancel: () => _animationController.reverse(),
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green[700]!,
                                  Colors.greenAccent[400]!,
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.greenAccent.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(30),
                                onTap: () {
                                  _getPlantTreatment();
                                  isclicked.value = true;
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  child: Center(
                                    child: Obx(
                                      () =>
                                          isclicked.value
                                              ? SizedBox(
                                                height: 28,
                                                width: 28,
                                                child: CircularProgressIndicator(
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
                                                  strokeWidth: 3,
                                                ),
                                              )
                                              : Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.healing,
                                                    color: Colors.white,
                                                    size: 28,
                                                  ),
                                                  SizedBox(width: 12),
                                                  Text(
                                                    'Get Treatment',
                                                    style: TextStyle(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      letterSpacing: 1.1,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
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

  Future<void> _getPlantTreatment() async {
    await _plantRecognizer.getPlantTreatment(
      _currentPlantName,
      _currentDiseaseName,
    );

    if (mounted) {
      isclicked.value = false;
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            elevation: 8,
            child: Container(
              padding: const EdgeInsets.all(25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with icon and title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.medical_services_outlined,
                          color: Colors.green[700],
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Text(
                          'Treatment Plan',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[800],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[100],
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Plant and Disease Info
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.local_florist,
                              size: 18,
                              color: Colors.green[700],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _currentPlantName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.green[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              _currentDiseaseName.toLowerCase() ==
                                      'no disease detected'
                                  ? Icons.check_circle
                                  : Icons.warning,
                              size: 18,
                              color:
                                  _currentDiseaseName.toLowerCase() ==
                                          'no disease detected'
                                      ? Colors.green[700]
                                      : Colors.orange[700],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _currentDiseaseName,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      _currentDiseaseName.toLowerCase() ==
                                              'no disease detected'
                                          ? Colors.green[800]
                                          : Colors.orange[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Treatment Content
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    constraints: BoxConstraints(
                      maxHeight: 200, // Adjust as needed for your dialog size
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        _plantRecognizer.treatmentRecommendation.value,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: Colors.green[900],
                        ),
                        // Remove maxLines and overflow for full display
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            startNewDetection();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Another'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.save),
                          label: const Text('Save'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
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
