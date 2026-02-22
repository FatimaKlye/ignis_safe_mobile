import 'package:flutter/material.dart';

class LearningMaterialPage extends StatelessWidget {
  const LearningMaterialPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          // ===== RED GRADIENT HEADER =====
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 900,
            child: Image.asset(
              'assets/bg.png',
              fit: BoxFit.cover,
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [

                  const SizedBox(height: 10),

                  // ===== CLOSE BUTTON =====
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "Learning Material",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ===== MODULE HEADER =====
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFC73C),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "MODULE 1",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "Fire Extinguisher: Safe Use and Emergency Response",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    ],
                  ),

                  const SizedBox(height: 30),

                  // ===== MAIN CARD =====
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // ===== TITLE =====
                        const Center(
                          child: Text(
                            "What Is a Fire Extinguisher?",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFB11217),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // ===== IMAGE + TEXT =====
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Image.asset(
                              "assets/module1_fire.png",
                              width: 110,
                            ),

                            const SizedBox(width: 15),

                            const Expanded(
                              child: Text(
                                "A fire extinguisher is a portable device used to put out small fires in their early stages, not large or spreading fires.",
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),

                        const Text(
                          "How to Use a Fire Extinguisher",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          "The PASS Method is a quick and easy guide for using a fire extinguisher: Pull, Aim, Squeeze, and Sweep to put out small fires safely.",
                          style: TextStyle(height: 1.5),
                        ),

                        const SizedBox(height: 20),

                        // ===== PASS IMAGE =====
                        Center(
                          child: Image.asset(
                            "assets/pass.png",
                            fit: BoxFit.contain,
                          ),
                        ),

                        const SizedBox(height: 30),

                        const Text(
                          "Basic Parts of a Fire Extinguisher",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 15),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Image.asset(
                              "assets/m1_fire.png",
                              width: 80,
                            ),

                            const SizedBox(width: 15),

                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Pin – Prevents accidental use"),
                                  SizedBox(height: 4),
                                  Text("Handle – Releases the agent"),
                                  SizedBox(height: 4),
                                  Text("Nozzle/Hose – Directs the spray"),
                                  SizedBox(height: 4),
                                  Text("Pressure Gauge – Shows if it’s ready"),
                                  SizedBox(height: 4),
                                  Text("Cylinder – Holds the agent"),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 25),

                        // ===== NEXT BUTTON =====
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFB11217)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            onPressed: () {},
                            child: const Text(
                              "NEXT »",
                              style: TextStyle(
                                color: Color(0xFFB11217),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}