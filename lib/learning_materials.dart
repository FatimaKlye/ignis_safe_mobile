import 'package:flutter/material.dart';

class LearningMaterialsPage extends StatelessWidget {
  const LearningMaterialsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // Background
            Positioned.fill(
              child: Image.asset(
                'assets/bg.png',
                fit: BoxFit.cover,
              ),
            ),

            // Foreground Content
            SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Your learning materials content here
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
