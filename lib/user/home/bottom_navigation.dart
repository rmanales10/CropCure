import 'package:cropcure/user/home/home.dart';
import 'package:cropcure/user/plant_classification/plant_camera_screen.dart';
import 'package:cropcure/user/profile/profile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BottomNavigation extends StatefulWidget {
  const BottomNavigation({super.key});

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  final plantName = TextEditingController();
  int _currentIndex = 0;
  List<Widget> body = [HomePage(), ProfilePage()];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: body[_currentIndex],
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        height: 64,
        width: 64,
        child: FloatingActionButton(
          onPressed: () {
            // Get.dialog(
            //   AlertDialog(
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(20),
            //     ),
            //     title: Column(
            //       children: [
            //         Icon(
            //           Icons.local_florist,
            //           size: 40,
            //           color: const Color.fromARGB(255, 15, 129, 19),
            //         ),
            //         const SizedBox(height: 10),
            //         const Text(
            //           'Name of Plant',
            //           style: TextStyle(
            //             fontSize: 24,
            //             fontWeight: FontWeight.bold,
            //           ),
            //         ),
            //       ],
            //     ),
            //     content: SizedBox(
            //       width: double.maxFinite,
            //       child: TextField(
            //         controller: plantName,
            //         decoration: InputDecoration(
            //           hintText: 'EX: Pechay...',
            //           prefixIcon: const Icon(Icons.edit),
            //           border: OutlineInputBorder(
            //             borderRadius: BorderRadius.circular(12),
            //             borderSide: const BorderSide(color: Colors.grey),
            //           ),
            //           focusedBorder: OutlineInputBorder(
            //             borderRadius: BorderRadius.circular(12),
            //             borderSide: const BorderSide(
            //               color: Color.fromARGB(255, 15, 129, 19),
            //               width: 2,
            //             ),
            //           ),
            //           filled: true,
            //           fillColor: Colors.grey[50],
            //         ),
            //       ),
            //     ),
            //     actions: [
            //       Row(
            //         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            //         children: [
            //           Expanded(
            //             child: Padding(
            //               padding: const EdgeInsets.symmetric(horizontal: 8.0),
            //               child: ElevatedButton(
            //                 onPressed: () => Get.back(),
            //                 style: ElevatedButton.styleFrom(
            //                   backgroundColor: Colors.grey[200],
            //                   foregroundColor: Colors.black87,
            //                   padding: const EdgeInsets.symmetric(vertical: 12),
            //                   shape: RoundedRectangleBorder(
            //                     borderRadius: BorderRadius.circular(12),
            //                   ),
            //                 ),
            //                 child: const Text('Cancel'),
            //               ),
            //             ),
            //           ),
            //           Expanded(
            //             child: Padding(
            //               padding: const EdgeInsets.symmetric(horizontal: 8.0),
            //               child: ElevatedButton(
            //                 onPressed: () {
            //                   Get.to(
            //                     () => PhotoPage(plantName: plantName.text),
            //                   );
            //                 },
            //                 style: ElevatedButton.styleFrom(
            //                   backgroundColor: const Color.fromARGB(
            //                     255,
            //                     15,
            //                     129,
            //                     19,
            //                   ),
            //                   foregroundColor: Colors.white,
            //                   padding: const EdgeInsets.symmetric(vertical: 12),
            //                   shape: RoundedRectangleBorder(
            //                     borderRadius: BorderRadius.circular(12),
            //                   ),
            //                 ),
            //                 child: const Text('Confirm'),
            //               ),
            //             ),
            //           ),
            //         ],
            //       ),
            //     ],
            //     actionsPadding: const EdgeInsets.all(16),
            //     contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            //   ),
            // );
            Get.to(() => PlantCameraScreen());
          },
          backgroundColor: const Color.fromARGB(255, 15, 129, 19),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.camera_alt_rounded,
            size: 32,
            color: Colors.white,
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          child: BottomNavigationBar(
            elevation: 0,
            backgroundColor: Colors.white,
            selectedItemColor: const Color.fromARGB(255, 15, 129, 19),
            unselectedItemColor: Colors.grey[600],
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
            currentIndex: _currentIndex,
            onTap: (int index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: [
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        _currentIndex == 0
                            ? const Color.fromARGB(
                              255,
                              15,
                              129,
                              19,
                            ).withOpacity(0.1)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.home_rounded),
                ),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        _currentIndex == 1
                            ? const Color.fromARGB(
                              255,
                              15,
                              129,
                              19,
                            ).withOpacity(0.1)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person_rounded),
                ),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    plantName.clear();
  }
}
