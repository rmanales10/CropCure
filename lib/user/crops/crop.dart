import 'dart:typed_data';
import 'package:cropcure/user/crops/crop_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PlantDiseasePage extends StatefulWidget {
  final Uint8List imageBytes;
  final String docId;
  const PlantDiseasePage({
    super.key,
    required this.imageBytes,
    required this.docId,
  });

  @override
  State<PlantDiseasePage> createState() => _PlantDiseasePageState();
}

class _PlantDiseasePageState extends State<PlantDiseasePage> {
  final _controller = Get.put(CropController());

  @override
  void initState() {
    super.initState();
    initPlant();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        // Wrapping the entire body in SingleChildScrollView
        child: Column(
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Icon(Icons.arrow_back, color: Colors.black),
                  ),
                  // Logo
                  Image.asset(
                    "assets/images/3.png", // Replace with your logo path
                    height: 60,
                  ),
                ],
              ),
            ),
            // Disease List Section
            Obx(() {
              _controller.fetchPlantDet(id: widget.docId);
              final plant = _controller.plantDet;
              return Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Plant Name
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              plant['name'] ?? 'Null',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                Get.dialog(
                                  AlertDialog(
                                    title: Text('Delete'),
                                    content: Text(
                                      'Are you sure you want to delete ?',
                                    ),
                                    actions: [
                                      ElevatedButton(
                                        onPressed: () async {
                                          await _controller.deletePlant(
                                            plant['id'],
                                          );
                                          Get.back(closeOverlays: true);
                                          Get.snackbar(
                                            'Success',
                                            'Plant deleted successfully!',
                                          );
                                        },
                                        child: Text('Yes'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Get.back(),
                                        child: Text('No'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              icon: Icon(Icons.delete, color: Colors.red),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Diseases List
                        ...plant['diseases'].map<Widget>((disease) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Divider(color: Colors.grey),
                              // Disease Image
                              Container(
                                height: 150,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  image: DecorationImage(
                                    image: MemoryImage(widget.imageBytes),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Disease Name
                              Text(
                                disease['name'],
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 15, 129, 19),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                "Cause:",
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              // Disease Cause
                              Text(
                                "${disease['cause'].replaceAll('*', '')}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 5),
                              // Disease Treatment
                              const Text(
                                "Treatment:",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              ...disease['treatment'].map<Widget>((treatment) {
                                return Text(
                                  "- ${treatment.replaceAll('*', '')}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                );
                              }).toList(),
                              const SizedBox(height: 10),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> initPlant() async {
    await _controller.fetchPlantDetails();
  }
}
