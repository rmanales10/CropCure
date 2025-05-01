import 'package:cropcure/user/home/home.dart';
import 'package:cropcure/user/photo/photo_page.dart';
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.dialog(
            AlertDialog(
              title: Text('Name of Plant'),
              content: TextField(
                controller: plantName,
                decoration: const InputDecoration(
                  hintText: 'EX: Pechay...',
                  border: OutlineInputBorder(),
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Get.to(() => PhotoPage(plantName: plantName.text));
                    plantName.clear();
                  },
                  child: const Text('Confirm'),
                ),
                ElevatedButton(
                  onPressed: () => Get.back(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          );
        },
        backgroundColor: Colors.white,
        tooltip: 'Increment',
        child: Icon(Icons.camera),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: const Color.fromARGB(255, 15, 129, 19),
        unselectedItemColor: Colors.black,
        currentIndex: _currentIndex,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    plantName.clear();
  }
}
