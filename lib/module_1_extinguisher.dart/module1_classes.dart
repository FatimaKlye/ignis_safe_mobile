import 'package:flutter/material.dart';

class ClassesOfFirePage extends StatelessWidget {
  const ClassesOfFirePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ===== BACKGROUND IMAGE =====
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 900,
            child: Image.asset('assets/bg.png', fit: BoxFit.cover),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 5),

                // ===== FIXED HEADER =====
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(height: 5),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 35,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFC73C),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              "MODULE 1",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 15),
                          const Flexible(
                            child: Text(
                              "Fire Extinguisher: Safe Use and Emergency Response",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),

                // ===== SCROLLABLE CONTENT =====
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Column(
                      children: [
                        // ===== MAIN CARD =====
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
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
                              const Center(
                                child: Text(
                                  "Classes of Fire Extinguisher",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFB11217),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                "Fires are classified based on the type of fuel involved. Using the correct extinguisher is critical.",
                                style: TextStyle(height: 1.5),
                              ),
                              const SizedBox(height: 25),

                              // ===== GRID (TAPPABLE) =====
                              Row(
                                children: const [
                                  Expanded(
                                    child: _ClassCard(
                                      label: "Class A",
                                      image: "assets/class_a.png",
                                    ),
                                  ),
                                  SizedBox(width: 20),
                                  Expanded(
                                    child: _ClassCard(
                                      label: "Class B",
                                      image: "assets/class_b.png",
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 25),
                              Row(
                                children: const [
                                  Expanded(
                                    child: _ClassCard(
                                      label: "Class C",
                                      image: "assets/class_c.png",
                                    ),
                                  ),
                                  SizedBox(width: 20),
                                  Expanded(
                                    child: _ClassCard(
                                      label: "Class D",
                                      image: "assets/class_d.png",
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 25),
                              Row(
                                children: const [
                                  Expanded(
                                    child: _ClassCard(
                                      label: "Class K",
                                      image: "assets/class_k.png",
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 35),

                              const Text(
                                "Importance of Fire Extinguisher Training",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text("Learning how to use a fire extinguisher:"),
                              const SizedBox(height: 8),
                              const Text("• Improves emergency preparedness"),
                              const Text("• Reduces injuries and damage"),
                              const Text("• Helps save lives during fire incidents"),
                              const SizedBox(height: 25),

                              // ===== BUTTONS =====
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Color(0xFFB11217)),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text(
                                      "« BACK",
                                      style: TextStyle(
                                        color: Color(0xFFB11217),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                  
                                ],
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
          ),
        ],
      ),
    );
  }
}

// ==============================
// ===== CLASS CARD WIDGET =======
// ==============================
class _ClassCard extends StatelessWidget {
  final String label;
  final String image;

  const _ClassCard({required this.label, required this.image});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _showModernClassSheet(context, label: label, image: image),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFFB11217),
              ),
            ),
            const SizedBox(height: 15),
            Image.asset(
              image,
              height: 90, // bigger
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================
// ===== MODERN POPUP (DIFFERENT STYLES) ====
// =========================================
void _showModernClassSheet(
  BuildContext context, {
  required String label,
  required String image,
}) {
  final data = _ClassPopupData.fromLabel(label, image);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.35),
    builder: (ctx) {
      return DraggableScrollableSheet(
        initialChildSize: 0.78,
        minChildSize: 0.55,
        maxChildSize: 0.92,
        builder: (ctx, controller) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 18,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: Column(
              children: [
                // Top handle
                const SizedBox(height: 10),
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 10),

                // Header (different per class)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: data.headerGradient,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.25),
                            ),
                          ),
                          child: Icon(
                            data.icon,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            data.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Body
                Expanded(
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                    children: [
                      // Hero card (image + short description)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: data.softTint,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: data.borderTint),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 78,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Image.asset(image, fit: BoxFit.contain),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                data.description,
                                style: const TextStyle(
                                  fontSize: 13.6,
                                  height: 1.45,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      _SectionCard(
                        accent: data.accent,
                        title: data.section1Title,
                        bodyLines: data.section1Bullets,
                      ),

                      const SizedBox(height: 12),

                      _SectionCard(
                        accent: data.accent,
                        title: data.section2Title,
                        bodyLines: data.section2Bullets,
                      ),

                      const SizedBox(height: 18),

                      // optional note pill (varies)
                      if (data.note != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline, color: data.accent, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  data.note!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.4,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

// ==============================
// ===== SECTION CARD ===========
// ==============================
class _SectionCard extends StatelessWidget {
  final Color accent;
  final String title;
  final List<String> bodyLines;

  const _SectionCard({
    required this.accent,
    required this.title,
    required this.bodyLines,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final line in bodyLines) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("• ", style: TextStyle(fontWeight: FontWeight.w900, color: accent)),
                Expanded(
                  child: Text(
                    line,
                    style: const TextStyle(fontSize: 13.5, height: 1.4, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

// ==============================
// ===== POPUP DATA =============
// ==============================
class _ClassPopupData {
  final String title;
  final String description;

  final String section1Title;
  final List<String> section1Bullets;

  final String section2Title;
  final List<String> section2Bullets;

  final List<Color> headerGradient;
  final Color accent;
  final Color softTint;
  final Color borderTint;
  final IconData icon;

  final String? note;

  _ClassPopupData({
    required this.title,
    required this.description,
    required this.section1Title,
    required this.section1Bullets,
    required this.section2Title,
    required this.section2Bullets,
    required this.headerGradient,
    required this.accent,
    required this.softTint,
    required this.borderTint,
    required this.icon,
    this.note,
  });

  static _ClassPopupData fromLabel(String label, String image) {
    switch (label) {
      case "Class A":
        return _ClassPopupData(
          title: "Class A Fire Extinguisher",
          description:
              "Used for fires involving ordinary combustible materials. These are common in homes, schools, and offices.",
          section1Title: "What is a Class A Fire?",
          section1Bullets: const [
            "Paper",
            "Wood",
            "Cloth",
            "Cardboard",
            "Plastics",
          ],
          section2Title: "Common Extinguishing Agents",
          section2Bullets: const [
            "Water",
            "Foam",
            "Dry chemical (ABC type)",
          ],
          headerGradient: const [Color(0xFFB11217), Color(0xFFE84C3D)],
          accent: const Color(0xFFB11217),
          softTint: const Color(0xFFFFF1F1),
          borderTint: const Color(0xFFFFD6D6),
          icon: Icons.local_fire_department_rounded,
          note: "Tip: Do not use water on electrical or flammable liquid fires.",
        );

      case "Class B":
        return _ClassPopupData(
          title: "Class B Fire Extinguisher",
          description:
              "Used for fires involving flammable liquids and gases. These fires spread fast and must be smothered, not soaked.",
          section1Title: "What is a Class B Fire?",
          section1Bullets: const [
            "Gasoline",
            "Oil",
            "Paint",
            "Alcohol",
            "Propane",
          ],
          section2Title: "Common Extinguishing Agents",
          section2Bullets: const [
            "Foam",
            "Carbon dioxide (CO₂)",
            "Dry chemical (ABC or BC type)",
          ],
          headerGradient: const [Color(0xFF7B1FA2), Color(0xFF512DA8)],
          accent: const Color(0xFF6A1B9A),
          softTint: const Color(0xFFF6EEFF),
          borderTint: const Color(0xFFE3D2FF),
          icon: Icons.water_drop_rounded,
          note: "Tip: Never use water on flammable liquid fires—it can spread the fuel.",
        );

      case "Class C":
        return _ClassPopupData(
          title: "Class C Fire Extinguisher",
          description:
              "Designed for fires involving energized electrical equipment. The agent must not conduct electricity.",
          section1Title: "What is a Class C Fire?",
          section1Bullets: const [
            "Wiring",
            "Electrical panels",
            "Circuit breakers",
            "Appliances",
          ],
          section2Title: "Common Extinguishing Agents",
          section2Bullets: const [
            "Carbon dioxide (CO₂)",
            "Dry chemical (ABC or BC type)",
          ],
          headerGradient: const [Color(0xFF0D47A1), Color(0xFF1976D2)],
          accent: const Color(0xFF1565C0),
          softTint: const Color(0xFFEEF6FF),
          borderTint: const Color(0xFFD3E9FF),
          icon: Icons.bolt_rounded,
          note: "Safety: If power is turned off, the fire may become Class A or B depending on the fuel.",
        );

      case "Class D":
        return _ClassPopupData(
          title: "Class D Fire Extinguisher",
          description:
              "Used for fires involving combustible metals. These require special agents and procedures.",
          section1Title: "What is a Class D Fire?",
          section1Bullets: const [
            "Magnesium",
            "Titanium",
            "Sodium",
            "Potassium",
            "Lithium",
          ],
          section2Title: "Common Extinguishing Agents",
          section2Bullets: const [
            "Special dry powder agents designed for metal fires",
          ],
          headerGradient: const [Color(0xFF455A64), Color(0xFF263238)],
          accent: const Color(0xFF37474F),
          softTint: const Color(0xFFF2F5F7),
          borderTint: const Color(0xFFDCE3E7),
          icon: Icons.precision_manufacturing_rounded,
          note: "Warning: Do not use water on metal fires—it can react violently.",
        );

      case "Class K":
        return _ClassPopupData(
          title: "Class K Fire Extinguisher",
          description:
              "Designed for kitchen fires involving cooking oils and fats. Common in commercial kitchens.",
          section1Title: "What is a Class K Fire?",
          section1Bullets: const [
            "Vegetable oil",
            "Animal fats",
            "Grease",
          ],
          section2Title: "Common Extinguishing Agents",
          section2Bullets: const [
            "Wet chemical agents that cool and form a foam layer to prevent re-ignition",
          ],
          headerGradient: const [Color(0xFF2E7D32), Color(0xFF66BB6A)],
          accent: const Color(0xFF2E7D32),
          softTint: const Color(0xFFEEFFF1),
          borderTint: const Color(0xFFD1F2D7),
          icon: Icons.restaurant_rounded,
          note: "Tip: For kitchen fires, turn off heat if safe before using an extinguisher.",
        );

      default:
        return _ClassPopupData(
          title: "Fire Class",
          description: "",
          section1Title: "",
          section1Bullets: const [],
          section2Title: "",
          section2Bullets: const [],
          headerGradient: const [Color(0xFFB11217), Color(0xFFB11217)],
          accent: const Color(0xFFB11217),
          softTint: const Color(0xFFFFF1F1),
          borderTint: const Color(0xFFFFD6D6),
          icon: Icons.info_outline,
        );
    }
  }
}