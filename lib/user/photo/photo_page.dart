import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cropcure/user/gemini/ai_service.dart';
import 'package:cropcure/user/home/bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show rootBundle; // Added for loading text file
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:developer' as devtools;

class PhotoPage extends StatefulWidget {
  final String plantName;
  const PhotoPage({super.key, required this.plantName});

  @override
  State<PhotoPage> createState() => _PhotoPageState();
}

class _PhotoPageState extends State<PhotoPage> {
  final AiService _response = Get.put(AiService());
  File? filePath;
  String base64Image = ""; // Add this line
  String label = "";
  double confidence = 0.0;
  final isClick = false.obs;
  late tfl.Interpreter _interpreter;
  List<String> _labels = [];

  Future<void> _loadLabels() async {
    try {
      final String labelData = await rootBundle.loadString(
        'assets/tflite/plant_labels.txt',
      );
      setState(() {
        _labels =
            labelData
                .split('\n')
                .where((line) => line.trim().isNotEmpty)
                .toList();
      });
      devtools.log('Labels loaded successfully: ${_labels.length} labels');
    } catch (e) {
      devtools.log('Error loading labels: $e');
    }
  }

  Future<void> _tfLiteInit() async {
    try {
      _interpreter = await tfl.Interpreter.fromAsset(
        'assets/tflite/plant_disease_model.tflite',
      );
      devtools.log('TFLite model loaded successfully');
    } catch (e) {
      devtools.log('Failed to load model: $e');
    }
  }

  Future<void> runModelOnImage(File imageFile) async {
    try {
      var imageBytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) {
        devtools.log('Failed to decode image');
        return;
      }

      img.Image resizedImage = img.copyResize(image, width: 224, height: 224);

      // Convert the image to a Float32List
      // Convert the image to a Float32List
      Float32List inputArray = Float32List(1 * 224 * 224 * 3);
      int pixelIndex = 0;
      for (int y = 0; y < resizedImage.height; y++) {
        for (int x = 0; x < resizedImage.width; x++) {
          img.Pixel pixel = resizedImage.getPixel(x, y);
          // Extract RGB components from the Pixel object
          inputArray[pixelIndex++] = pixel.r / 255.0; // Red
          inputArray[pixelIndex++] = pixel.g / 255.0; // Green
          inputArray[pixelIndex++] = pixel.b / 255.0; // Blue
        }
      }

      // Run inference
      var outputShape = [1, _labels.length];
      var outputBuffer = List.filled(
        1 * _labels.length,
        0.0,
      ).reshape(outputShape);
      _interpreter.run(inputArray.reshape([1, 224, 224, 3]), outputBuffer);

      // Process the output
      var results = outputBuffer[0];
      int maxIndex = 0;
      double maxValue = results[0];
      for (int i = 1; i < results.length; i++) {
        if (results[i] > maxValue) {
          maxIndex = i;
          maxValue = results[i];
        }
      }

      // Update the UI
      setState(() {
        confidence = maxValue * 100;
        label = _getLabelFromIndex(maxIndex);
      });
    } catch (e) {
      devtools.log('Error running model: $e');
    }
  }

  String _getLabelFromIndex(int index) {
    if (index >= 0 && index < _labels.length) {
      return _labels[index];
    }
    return 'Unknown';
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);

      if (image == null) return;

      setState(() {
        filePath = File(image.path);
      });

      await runModelOnImage(filePath!);

      // Convert the image to Base64 and store it in base64Image
      base64Image = await convertImageToBase64(filePath!);
      devtools.log('Base64 Image: $base64Image');
    } catch (e) {
      devtools.log('Error picking image: $e');
    }
  }

  Future<String> convertImageToBase64(File image) async {
    try {
      List<int> imageBytes = await image.readAsBytes();
      return base64Encode(imageBytes);
    } catch (e) {
      devtools.log('Error converting image to base64: $e');
      return '';
    }
  }

  @override
  void initState() {
    super.initState();
    _tfLiteInit();
    _loadLabels(); // Load labels during initialization
  }

  @override
  void dispose() {
    _interpreter.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Plant Disease Detection")),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              filePath != null
                  ? Image.file(
                    filePath!,
                    height: 300,
                    width: 300,
                    fit: BoxFit.cover,
                  )
                  : Container(
                    height: 300,
                    width: 300,
                    color: Colors.grey[300],
                    child: const Center(child: Text('No image selected')),
                  ),
              const SizedBox(height: 20),
              Text(
                label.isNotEmpty ? 'Prediction: $label' : 'No prediction yet',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                confidence > 0
                    ? 'Confidence: ${confidence.toStringAsFixed(2)}%'
                    : '',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => pickImage(ImageSource.camera),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: const Text("Take a Photo"),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => pickImage(ImageSource.gallery),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: const Text("Pick from gallery"),
              ),
              const SizedBox(height: 60),
              ElevatedButton(
                onPressed: () => getTreatment(),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: const Text("Get Treatment"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> getTreatment() async {
    if (filePath != null) {
      await _response.response(
        label: widget.plantName,
        disease: label,
        image: base64Image,
      );
      Get.snackbar('Success', 'Image processed successfully');

      Get.offAll(() => BottomNavigation());
    } else {
      devtools.log('No image selected for processing');
    }
  }
}
