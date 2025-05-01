import 'dart:convert';
import 'package:cropcure/user/crops/crop.dart';
import 'package:cropcure/user/crops/crop_controller.dart';
import 'package:cropcure/user/profile/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;
  final _cropController = Get.put(CropController());
  final _profileController = Get.put(ProfileController());
  final PageController _pageController = PageController();
  final RxInt _currentPage = 0.obs;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _animation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.2, 0),
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGreetingSection(),
                _buildPageView(),
                SizedBox(height: 10),
                dottedslide(),
                Expanded(child: Container()),
              ],
            ),
            _buildDraggableScrollableSheet(),
          ],
        ),
      ),
    );
  }

  Obx dottedslide() {
    return Obx(
      () => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          3,
          (index) => Container(
            width: 20,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              color: _currentPage.value == index ? Colors.green : Colors.grey,
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 50, left: 30, right: 30, bottom: 20),
      child: Row(
        children: [
          Obx(() {
            _profileController.fetchUserInfo();
            final data = _profileController.userInfo; // Use .value here
            try {
              return ClipOval(
                child: Image.memory(
                  base64Decode(data['base64image']),
                  height: 70,
                  width: 70,
                  gaplessPlayback: true,
                  fit: BoxFit.cover,
                ),
              );
            } catch (e) {
              return ClipOval(
                child: Image.asset(
                  'assets/images/2.jpg',
                  height: 70,
                  width: 70,
                  gaplessPlayback: true,
                  fit: BoxFit.cover,
                ),
              );
            }
            // return _buildProfileImage(data);
          }),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Obx(
                      () => Text(
                        _profileController.userInfo['fullname'] ?? 'Not set',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    SlideTransition(
                      position: _animation,
                      child: const Text("👋", style: TextStyle(fontSize: 22)),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                const Text(
                  "Welcome to CropCure.",
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageView() {
    return Container(
      margin: const EdgeInsets.only(top: 50),
      height: 200,
      child: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              _currentPage.value = index;
            },
            children: [
              _buildPageViewItem('', 'assets/images/slide1.png'),
              _buildPageViewItem('', 'assets/images/slide2.jpg'),
              _buildPageViewItem('', 'assets/images/slide3.png'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageViewItem(String title, String imagePath) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(image: AssetImage(imagePath), fit: BoxFit.cover),
      ),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDraggableScrollableSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.1,
      maxChildSize: 0.9,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(50)),
            boxShadow: [
              BoxShadow(
                color: Colors.green,
                spreadRadius: 5,
                // blurRadius: 7,
                // offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 50,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Obx(() {
                    _cropController.fetchPlantDetails();
                    return GridView.builder(
                      controller: scrollController,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.9,
                          ),
                      itemCount: _cropController.plantDetails.length,
                      itemBuilder: (context, index) {
                        final plant = _cropController.plantDetails[index];
                        return _buildPlantCard(plant);
                      },
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlantCard(Map<String, dynamic> plant) {
    return GestureDetector(
      onTap:
          () => Get.to(
            () => PlantDiseasePage(
              docId: plant['id'],
              imageBytes: base64Decode(plant['image']),
            ),
          ),
      child: Card(
        color: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 5,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child:
                      plant['image'] != null
                          ? Image.memory(
                            base64Decode(plant['image']),
                            height: 100,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                          )
                          : Image.asset(
                            'assets/images/p3.png',
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                plant['name'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
