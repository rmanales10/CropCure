import 'dart:convert';
import 'dart:developer';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:cropcure/user/home/bottom_navigation.dart';
import 'package:cropcure/user/home/home_controller.dart';
import 'package:cropcure/user/plant_classification/plant_controller.dart';
import 'package:cropcure/user/plant_classification/plant_recognizer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
  bool _hasRecognitionCompleted = false; // Track if recognition has completed
  bool _isRecognitionInProgress =
      false; // Track if recognition is currently in progress
  String _currentPlantName = '';
  final RxString _currentDiseaseName = ''.obs; // Made reactive
  bool _hasDiseaseStored = false;
  String _base64Image = '';
  RxBool isclicked = false.obs; // Loading state for Get Treatment button
  RxBool isDoneLoading = false.obs; // Loading state for Done button
  final _plantController = Get.put(PlantController());

  // Helper function to check if plant is healthy
  bool _isPlantHealthy(String disease) {
    if (disease.isEmpty) return false;
    final diseaseLower = disease.toLowerCase().trim();
    return diseaseLower == 'no disease detected' ||
        diseaseLower == 'healthy plant' ||
        diseaseLower == 'healthy' ||
        diseaseLower.contains('healthy') ||
        diseaseLower.contains('no disease');
  }

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
    if (_recognitionTimer != null || _isRecognitionInProgress) return;

    log('Starting plant recognition...');

    // Start the first recognition attempt immediately
    _performRecognition();

    // Set up the periodic timer for every 3 seconds (only if recognition is not in progress)
    _recognitionTimer = Timer.periodic(const Duration(seconds: 3), (
      timer,
    ) async {
      // Wait for current recognition to complete before starting next one
      if (_isRecognitionInProgress) {
        log('Previous recognition still in progress, skipping...');
        return;
      }

      if (_controller == null ||
          !_controller!.value.isInitialized ||
          !_isRecognizing.value ||
          _hasPlantDetected) {
        timer.cancel();
        _stopRecognition();
        return;
      }

      // Perform recognition
      await _performRecognition();
    });
  }

  Future<void> _performRecognition() async {
    // Check if recognition should continue
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        !_isRecognizing.value ||
        _hasPlantDetected ||
        _isRecognitionInProgress) {
      return;
    }

    // Mark recognition as in progress
    _isRecognitionInProgress = true;

    try {
      log('Taking picture for plant recognition...');
      final XFile file = await _controller!.takePicture();
      final bytes = await file.readAsBytes();
      final image = base64Encode(bytes);

      log('Recognizing plant from image...');
      // Try to recognize the plant and wait for the response
      await _plantRecognizer.recognizePlant(image);

      // Only update and display if we haven't detected a plant yet
      if (!_hasPlantDetected && mounted) {
        final hasPlant = _plantRecognizer.hasPlantDetected.value;
        final plantName = _plantRecognizer.plantName.value;

        log('Recognition result - Plant detected: $hasPlant, Name: $plantName');

        setState(() {
          _hasPlantDetected = hasPlant;
          _currentPlantName = plantName;
          _base64Image = image;
          _hasRecognitionCompleted = true; // Mark recognition as completed
        });

        // If a plant is detected, stop immediately and start disease detection
        if (_hasPlantDetected &&
            _currentPlantName.isNotEmpty &&
            _currentPlantName.toLowerCase() != "no plant detected" &&
            _currentPlantName.toLowerCase() != "unknown plant") {
          log(
            'Plant detected: $_currentPlantName. Starting disease detection...',
          );
          _recognitionTimer?.cancel(); // Stop the timer immediately
          _isRecognizing.value = false;
          _stopRecognition();
          await Future.delayed(const Duration(milliseconds: 500));
          _startDiseaseDetection();
        } else {
          // No plant detected - stop recognition after showing the message
          _recognitionTimer?.cancel();
          _isRecognizing.value = false;
          _stopRecognition();
        }
      }
    } catch (e) {
      log('Error during recognition: $e');
      // Mark recognition as completed even on error
      if (mounted && !_hasPlantDetected) {
        setState(() {
          _hasRecognitionCompleted = true;
          _hasPlantDetected = false;
          _currentPlantName = '';
        });
        // Stop recognition on error
        _recognitionTimer?.cancel();
        _isRecognizing.value = false;
        _stopRecognition();
      }
      // Error logged, no need to show snackbar during continuous recognition
    } finally {
      // Mark recognition as completed (no longer in progress)
      _isRecognitionInProgress = false;
    }
  }

  void _stopRecognition() {
    _recognitionTimer?.cancel();
    _recognitionTimer = null;
    _isRecognizing.value = false;
    _isRecognitionInProgress = false; // Reset recognition in progress flag
  }

  void _startDiseaseDetection() async {
    if (_isDetectingDisease.value || _hasDiseaseStored) {
      log('Disease detection already in progress or completed');
      return;
    }

    log('Starting disease detection for plant: $_currentPlantName');
    _isDetectingDisease.value = true;

    try {
      if (_controller != null && _controller!.value.isInitialized) {
        // Wait for 2 seconds before taking the picture for disease detection
        await Future.delayed(const Duration(seconds: 2));

        log('Taking picture for disease detection...');
        final XFile file = await _controller!.takePicture();
        final bytes = await file.readAsBytes();
        final image = base64Encode(bytes);

        log('Classifying plant disease...');
        // Call disease classification
        await _plantRecognizer.classifyPlantDisease(image);

        final diseaseName = _plantRecognizer.diseaseName.value;
        final diseaseDetected = _plantRecognizer.hasDiseaseDetected.value;

        log(
          'Disease detection result - Detected: $diseaseDetected, Name: $diseaseName',
        );

        // Update local disease variable and store the final image
        if (mounted) {
          setState(() {
            _currentDiseaseName.value = diseaseName;
            _isDetectingDisease.value = false;
            _base64Image = image;
            _hasDiseaseStored = true;
          });
        }
      }
    } catch (e) {
      log('Error during disease detection: $e');
      if (mounted) {
        setState(() {
          _isDetectingDisease.value = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to detect disease: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
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
    _isRecognitionInProgress = false; // Reset recognition in progress flag
  }

  // Add a method to start new detection
  void startNewDetection() {
    setState(() {
      _hasPlantDetected = false;
      _hasRecognitionCompleted = false; // Reset recognition completion status
      _isRecognitionInProgress = false; // Reset recognition in progress flag
      _currentPlantName = '';
      _currentDiseaseName.value = '';
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
                                        : _hasRecognitionCompleted
                                        ? Row(
                                          children: [
                                            const Icon(
                                              Icons.cancel,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'No plant detected',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
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
                          Obx(() {
                            if (_isDetectingDisease.value) {
                              return Column(
                                children: [
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.green,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Analyzing for diseases...',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            } else if (_currentDiseaseName.value.isNotEmpty) {
                              return Column(
                                children: [
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color:
                                          _isPlantHealthy(
                                                _currentDiseaseName.value,
                                              )
                                              ? Colors.green.withOpacity(0.2)
                                              : Colors.red.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _isPlantHealthy(
                                                _currentDiseaseName.value,
                                              )
                                              ? Icons.check_circle
                                              : Icons.warning,
                                          color:
                                              _isPlantHealthy(
                                                    _currentDiseaseName.value,
                                                  )
                                                  ? Colors.green[700]
                                                  : Colors.red[700],
                                          size: 24,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Condition',
                                                style: TextStyle(
                                                  color:
                                                      _isPlantHealthy(
                                                            _currentDiseaseName
                                                                .value,
                                                          )
                                                          ? Colors.green[700]
                                                          : Colors.red[700],
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                _currentDiseaseName.value,
                                                style: TextStyle(
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
                              );
                            }
                            return const SizedBox.shrink();
                          }),
                        ],
                      ),
                    ),
                  ),
                  if ((_hasPlantDetected &&
                          _currentDiseaseName.value.isNotEmpty) ||
                      (_hasRecognitionCompleted && !_hasPlantDetected))
                    Positioned(
                      bottom: 30,
                      left: 40,
                      right: 40,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Re-scan Button
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _hasPlantDetected = false;
                                    _hasRecognitionCompleted =
                                        false; // Reset recognition completion status
                                    _isRecognitionInProgress =
                                        false; // Reset recognition in progress flag
                                    _currentPlantName = '';
                                    _currentDiseaseName.value = '';
                                    _base64Image = '';
                                    _hasDiseaseStored = false;
                                    isclicked.value = false;
                                  });
                                  _resetDetection();
                                  _isRecognizing.value = true;
                                },
                                borderRadius: BorderRadius.circular(30),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[600],
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.refresh_rounded,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Re-scan',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Done Button for healthy plants
                          if (_hasPlantDetected &&
                              _currentDiseaseName.value.isNotEmpty &&
                              _isPlantHealthy(_currentDiseaseName.value))
                            GestureDetector(
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
                                        color: Colors.greenAccent.withOpacity(
                                          0.3,
                                        ),
                                        blurRadius: 12,
                                        offset: Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(30),
                                      onTap: () async {
                                        if (!isDoneLoading.value) {
                                          isDoneLoading.value = true;
                                          await _saveHealthyPlantAndNavigate();
                                          isDoneLoading.value = false;
                                        }
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 18,
                                        ),
                                        child: Center(
                                          child: Obx(
                                            () =>
                                                isDoneLoading.value
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
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        SizedBox(width: 12),
                                                        Text(
                                                          'Done',
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
                          // Get Treatment Button for diseased plants
                          if (_hasPlantDetected &&
                              _currentDiseaseName.value.isNotEmpty &&
                              !_isPlantHealthy(_currentDiseaseName.value))
                            GestureDetector(
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
                                        color: Colors.greenAccent.withOpacity(
                                          0.3,
                                        ),
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
                                        isclicked.value = !isclicked.value;
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
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
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
                        ],
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

  Future<void> _saveHealthyPlantAndNavigate() async {
    try {
      // Get general care tips for healthy plant
      await _plantRecognizer.getPlantTreatment(
        _currentPlantName,
        _currentDiseaseName.value,
      );

      // Save healthy plant to history
      await _plantController.addPlant(
        _currentPlantName,
        _currentDiseaseName.value,
        _plantRecognizer.treatmentRecommendation.value,
        _base64Image,
      );

      // Refresh home data before navigating
      try {
        final homeController = Get.find<HomeController>();
        await homeController.fetchPlants();
      } catch (e) {
        log('HomeController not found, will refresh on navigation: $e');
      }

      // Navigate to home with bottom navigation
      if (mounted) {
        Get.offAll(() => const BottomNavigation());
      }
    } catch (e) {
      log('Error saving healthy plant: $e');
      // Reset loading state on error
      if (mounted) {
        isDoneLoading.value = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving plant: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _getPlantTreatment() async {
    try {
      await _plantRecognizer.getPlantTreatment(
        _currentPlantName,
        _currentDiseaseName.value,
      );
      await _plantController.addPlant(
        _currentPlantName,
        _currentDiseaseName.value,
        _plantRecognizer.treatmentRecommendation.value,
        _base64Image,
      );

      if (mounted) {
        isclicked.value = !isclicked.value;
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
                                _isPlantHealthy(_currentDiseaseName.value)
                                    ? Icons.check_circle
                                    : Icons.warning,
                                size: 18,
                                color:
                                    _isPlantHealthy(_currentDiseaseName.value)
                                        ? Colors.green[700]
                                        : Colors.red[700],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _currentDiseaseName.value,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        _isPlantHealthy(
                                              _currentDiseaseName.value,
                                            )
                                            ? Colors.green[800]
                                            : Colors.red[800],
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
                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          // Close dialog first
                          Navigator.of(context).pop();

                          // Refresh home data before navigating
                          try {
                            final homeController = Get.find<HomeController>();
                            await homeController.fetchPlants();
                          } catch (e) {
                            // Controller might not exist yet, that's okay
                            print(
                              'HomeController not found, will refresh on navigation: $e',
                            );
                          }

                          // Navigate to home with bottom navigation
                          Get.offAll(() => const BottomNavigation());
                        },
                        icon: const Icon(Icons.done),
                        label: const Text('Done'),
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
              ),
            );
          },
        );
      }
    } catch (e) {
      log('Error getting plant treatment: $e');
      // Reset loading state on error
      if (mounted) {
        isclicked.value = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting treatment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
