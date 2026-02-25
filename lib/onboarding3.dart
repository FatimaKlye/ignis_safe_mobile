import 'package:flutter/material.dart';
import 'learning_materials.dart';

class OnboardingThreePage extends StatelessWidget {
  const OnboardingThreePage({super.key});

  static const Color brandRed = Color(0xFFB71C1C);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 70),

              // Image
              Image.asset(
                'assets/onboard3.png',
                height: 240,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 26),

              // Dots (3rd active)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  _Dot(active: false),
                  SizedBox(width: 10),
                  _Dot(active: false),
                  SizedBox(width: 10),
                  _Dot(active: true),
                ],
              ),

              const SizedBox(height: 34),

              // Title
              const Text(
                "Train Like It’s Real",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: brandRed,
                  height: 1.12,
                ),
              ),

              const SizedBox(height: 20),

              // Description
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 22),
                child: Text(
                  "Engage in interactive fire scenarios and\npractice proper response procedures within a\nsafe, controlled simulation environment.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black38,
                    height: 1.6,
                  ),
                ),
              ),

              const Spacer(),

              // Bottom buttons
              Padding(
                padding: const EdgeInsets.only(bottom: 22),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LearningMaterialsTab(),
                          ),
                        );
                      },
                      child: const Text(
                        'SKIP',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black26,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LearningMaterialsTab(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandRed,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 26),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'NEXT',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final bool active;

  const _Dot({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: active ? const Color(0xFFB71C1C) : Colors.black12,
        shape: BoxShape.circle,
      ),
    );
  }
}
