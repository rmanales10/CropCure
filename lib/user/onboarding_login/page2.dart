import 'package:flutter/material.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  "assets/images/1.jpg",
                ), // Replace with your background image
                fit: BoxFit.cover,
                alignment: Alignment.center,
                scale: 4.0, // Slightly zoom the image
              ),
            ),
          ),
          // Content on top of the background
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App name with logo
              Center(
                child: Image.asset(
                  "assets/images/4.png", // Replace with your logo image
                  height: 200,
                ),
              ),

              const SizedBox(height: 50),
              // Get Started Button with border
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/signin');
                },
                child: Container(
                  width: 200,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: const Color.fromARGB(
                        255,
                        15,
                        129,
                        19,
                      ), // Button border color
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      "Get Started",
                      style: TextStyle(
                        color: Color.fromARGB(255, 15, 129, 19),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
