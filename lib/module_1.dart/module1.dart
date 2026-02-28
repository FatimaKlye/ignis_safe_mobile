import 'package:flutter/material.dart';

class LearningMaterialExtinguisherPage extends StatefulWidget {
  const LearningMaterialExtinguisherPage({super.key});

  @override
  State<LearningMaterialExtinguisherPage> createState() =>
      _LearningMaterialExtinguisherPageState();
}

class _LearningMaterialExtinguisherPageState
    extends State<LearningMaterialExtinguisherPage> {
  static const accent = Color(0xFFB11217); // red
  static const accent2 = Color(0xFF2563EB); // blue

  final PageController _pageCtrl = PageController();
  final ScrollController _scrollCtrl = ScrollController();

  int _pageIndex = 0;

  double _progress = 0.0; // 0..1 per page scroll
  bool _canNext = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;

    final max = _scrollCtrl.position.maxScrollExtent;
    final off = _scrollCtrl.offset;

    if (max <= 0) {
      if (_progress != 1.0 || !_canNext) {
        setState(() {
          _progress = 1.0;
          _canNext = true;
        });
      }
      return;
    }

    final p = (off / max).clamp(0.0, 1.0);
    final nearBottom = off >= (max - 8);

    if (_progress != p || _canNext != nearBottom) {
      setState(() {
        _progress = p;
        _canNext = nearBottom;
      });
    }
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  void _resetForNewPage() {
    if (_scrollCtrl.hasClients) _scrollCtrl.jumpTo(0);
    setState(() {
      _progress = 0.0;
      _canNext = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  void _goBack() {
    if (_pageIndex == 0) {
      Navigator.pop(context);
      return;
    }
    _pageCtrl.previousPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _goNext() {
    if (!_canNext) return;

    if (_pageIndex < 2) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    } else {
      // Hook your navigation to pre-test / next module here
      // Navigator.push(context, MaterialPageRoute(builder: (_) => const PreTestExtinguisherPage()));
    }
  }

  // ---------------- POPUPS ----------------
  void _showInfoPopup({
    required String title,
    required String message,
    IconData icon = Icons.info_rounded,
    Color color = accent,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontWeight: FontWeight.w900, color: color),
              ),
            ),
          ],
        ),
        content: Text(message, style: const TextStyle(height: 1.45)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showPASSPopup() {
    _showInfoPopup(
      title: "PASS Method (Simple)",
      icon: Icons.checklist_rounded,
      color: const Color(0xFF16A34A),
      message:
          "P — Pull the pin\n"
          "A — Aim at the base of the fire\n"
          "S — Squeeze the handle\n"
          "S — Sweep side to side\n\n"
          "Stop if the fire grows or you feel unsafe.",
    );
  }

  void _showWhenNotToUsePopup() {
    _showInfoPopup(
      title: "Do NOT use an extinguisher if…",
      icon: Icons.block_rounded,
      color: const Color(0xFFDC2626),
      message:
          "• The fire is too large or spreading fast\n"
          "• Thick smoke is building up\n"
          "• You don’t have a clear exit behind you\n"
          "• You are unsure what is burning\n\n"
          "Evacuate and call emergency services.",
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _pageIndex == 2;

    return Scaffold(
      body: Stack(
        children: [
          // ===== BACKGROUND =====
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
                const SizedBox(height: 10),

                // ===== FIXED HEADER =====
                Padding(
                  padding: const EdgeInsets.only(left: 9, right: 25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(height: 10),
                      const Center(
                        child: Text(
                          "Learning Material",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      Padding(
                      padding: const EdgeInsets.only(left: 25), // adjust 12/16/20/24
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [accent, accent2],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.18),
                                  blurRadius: 10,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  "MODULE 1",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 15),

                          const Expanded(
                            child: Text(
                              "Fire Extinguisher: Basics, Types, and How to Use",
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                      const SizedBox(height: 14),

                      // ===== PROGRESS BAR =====
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: SizedBox(
                          height: 6,
                          child: LinearProgressIndicator(
                            value: _progress,
                            backgroundColor: Colors.white.withOpacity(0.25),
                            valueColor:
                                const AlwaysStoppedAnimation(accent2),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ===== PAGE DOTS =====
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (i) {
                          final active = i == _pageIndex;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: active ? 18 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: active
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 14),
                    ],
                  ),
                ),

                // ===== PAGE VIEW =====
                Expanded(
                  child: PageView(
                    controller: _pageCtrl,
                    onPageChanged: (i) {
                      setState(() => _pageIndex = i);
                      _resetForNewPage();
                    },
                    children: [
                      _pageWrap(_page1ExtinguisherBasics()),
                      _pageWrap(_page2TypesAndUses()),
                      _pageWrap(_page3HowToUseAndSafety()),
                    ],
                  ),
                ),

                // ===== BOTTOM NAV =====
                Padding(
                  padding: const EdgeInsets.fromLTRB(25, 8, 25, 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFB11217)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        onPressed: _goBack,
                        child: const Text(
                          "« BACK",
                          style: TextStyle(
                            color: Color(0xFFB11217),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB11217),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        onPressed: _canNext ? _goNext : null,
                        child: Text(
                          isLast ? "Start pre test" : "NEXT »",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
  }

  Widget _pageWrap(Widget child) {
    return SingleChildScrollView(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        children: [
          const SizedBox(height: 6),
          child,
          const SizedBox(height: 24),
          const SizedBox(height: 70),
        ],
      ),
    );
  }

  // ===================== PAGE 1 =====================
  Widget _page1ExtinguisherBasics() {
    return _ModernCard(
      accent1: accent,
      accent2: accent2,
      pageTitle: "PAGE 1 – FIRE EXTINGUISHER BASICS",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              "What is a Fire Extinguisher?",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: accent,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          const SizedBox(height: 18),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ImageBox(
                asset: "assets/extinguisher_overview.png", // placeholder
                c1: accent,
                c2: accent2,
              ),
              const SizedBox(width: 15),
              const Expanded(
                child: Text(
                  "A fire extinguisher is a portable safety device used to control small fires. It works by releasing an extinguishing agent that removes heat, oxygen, or interrupts the fire reaction.",
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          const _Callout(
            icon: Icons.warning_rounded,
            color: Color(0xFFDC2626),
            title: "Important",
            lines: [
              "Extinguishers are for small, early-stage fires.",
              "You must choose the correct type for the fire.",
              "If unsafe, evacuate first.",
            ],
          ),

          const SizedBox(height: 12),


          Builder(
            builder: (_) => Row(
              children: [
                Expanded(
                  child: _ActionPill(
                    icon: Icons.checklist_rounded,
                    label: "PASS method",
                    onTap: _showPASSPopup,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionPill(
                    icon: Icons.block_rounded,
                    label: "When NOT to use",
                    onTap: _showWhenNotToUsePopup,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          const _ChipLine(
            icon: Icons.fact_check_rounded,
            color: Color(0xFF2563EB),
            text: "Goal: Use the right extinguisher, quickly and safely.",
          ),
        ],
      ),
    );
  }

  // ===================== PAGE 2 =====================
  Widget _page2TypesAndUses() {
    return _ModernCard(
      accent1: accent2,
      accent2: accent,
      pageTitle: "PAGE 2 – TYPES OF FIRE EXTINGUISHERS",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              "Common Extinguisher Types (Simple Guide)",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: accent,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          const SizedBox(height: 18),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _IconBox(
                icon: Icons.category_rounded, // placeholder icon box
                c1: accent2,
                c2: accent,
              ),
              SizedBox(width: 15),
              Expanded(
                child: _Bullets(
                  items: [
                    "Different fires need different extinguishers.",
                    "Check the label (Class) on the cylinder.",
                    "When unsure, evacuate and call for help.",
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          const _SectionTitle("Types you may see"),
          const SizedBox(height: 12),

          _MiniTile(
            color: const Color(0xFF2563EB),
            icon: Icons.bolt_rounded,
            title: "Class C (Electrical)",
            desc: "For energized electrical equipment (wiring, panels, appliances).",
          ),
          const SizedBox(height: 10),
          _MiniTile(
            color: const Color(0xFFF59E0B),
            icon: Icons.local_gas_station_rounded,
            title: "Class B (Flammable liquids)",
            desc: "For gasoline, oil, paint, solvents (do NOT use water).",
          ),
          const SizedBox(height: 10),
          _MiniTile(
            color: const Color(0xFF16A34A),
            icon: Icons.park_rounded,
            title: "Class A (Ordinary materials)",
            desc: "For paper, wood, cloth, trash (common room fires).",
          ),
          const SizedBox(height: 10),
          _MiniTile(
            color: const Color(0xFFB11217),
            icon: Icons.restaurant_rounded,
            title: "Class K (Cooking oils/fats)",
            desc: "For kitchen oil/grease fires (special wet-chemical type).",
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _ActionPill(
                  icon: Icons.search_rounded,
                  label: "How to choose",
                  onTap: () => _showInfoPopup(
                    title: "How to choose fast",
                    icon: Icons.search_rounded,
                    color: const Color(0xFF2563EB),
                    message:
                        "1) Identify what’s burning (paper? oil? electrical?).\n"
                        "2) Match the extinguisher class label.\n"
                        "3) Keep an exit behind you.\n"
                        "4) If unsure, evacuate.",
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionPill(
                  icon: Icons.label_important_rounded,
                  label: "Read the label",
                  onTap: () => _showInfoPopup(
                    title: "Read the label",
                    icon: Icons.label_important_rounded,
                    color: const Color(0xFF16A34A),
                    message:
                        "Look for the fire class letters (A/B/C/K) and simple icons on the extinguisher body.",
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===================== PAGE 3 =====================
  Widget _page3HowToUseAndSafety() {
    return _ModernCard(
      accent1: const Color(0xFF16A34A),
      accent2: accent,
      pageTitle: "PAGE 3 – HOW TO USE & SAFETY",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              "How to Use a Fire Extinguisher",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: accent,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          const SizedBox(height: 18),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _IconBox(
                icon: Icons.fire_extinguisher_rounded,
                c1: Color(0xFF16A34A),
                c2: Color(0xFF2563EB),
              ),
              SizedBox(width: 15),
              Expanded(
                child: _Bullets(
                  items: [
                    "Stand a safe distance away (not too close).",
                    "Aim at the base of the fire (not the flames).",
                    "Use short controlled bursts.",
                    "Sweep side to side until the fire is out.",
                    "Watch for re-ignition and be ready to evacuate.",
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _ActionPill(
                  icon: Icons.checklist_rounded,
                  label: "Show PASS steps",
                  onTap: _showPASSPopup,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionPill(
                  icon: Icons.security_rounded,
                  label: "Safety rule",
                  onTap: () => _showInfoPopup(
                    title: "Safety rule",
                    icon: Icons.security_rounded,
                    color: const Color(0xFF16A34A),
                    message:
                        "If you can’t control it within a few seconds, stop and evacuate. Close doors behind you and call for help.",
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ImageBox(
                asset: "assets/pass_steps.png", // placeholder
                c1: const Color(0xFF16A34A),
                c2: accent,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _SectionTitle("Before you use it"),
                    SizedBox(height: 10),
                    _Bullets(
                      items: [
                        "Check the pressure gauge (if present).",
                        "Keep your back to an exit.",
                        "Make sure the correct class matches the fire.",
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          const _Callout(
            icon: Icons.block_rounded,
            color: Color(0xFFDC2626),
            title: "Remember",
            lines: [
              "Never risk your life for property. If it feels unsafe, evacuate immediately.",
            ],
          ),
        ],
      ),
    );
  }
}

// ===================== UI WIDGETS =====================

class _ModernCard extends StatelessWidget {
  final Color accent1;
  final Color accent2;
  final String pageTitle;
  final Widget child;

  const _ModernCard({
    required this.accent1,
    required this.accent2,
    required this.pageTitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [accent1, accent2],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              pageTitle,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ImageBox extends StatelessWidget {
  final String asset;
  final Color c1;
  final Color c2;

  const _ImageBox({required this.asset, required this.c1, required this.c2});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c1.withOpacity(0.12), c2.withOpacity(0.10)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      padding: const EdgeInsets.all(10),
      child: Image.asset(asset, fit: BoxFit.contain),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color c1;
  final Color c2;

  const _IconBox({required this.icon, required this.c1, required this.c2});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c1.withOpacity(0.14), c2.withOpacity(0.10)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Center(
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [c1, c2],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: c2.withOpacity(0.28),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w900,
        color: Color(0xFF111827),
      ),
    );
  }
}

class _Callout extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final List<String> lines;

  const _Callout({
    required this.icon,
    required this.color,
    required this.title,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w900, color: color),
                ),
                const SizedBox(height: 8),
                ...lines.map(
                  (l) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(l, style: const TextStyle(height: 1.4)),
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

class _ChipLine extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _ChipLine({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.20)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniTile extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String desc;

  const _MiniTile({
    required this.color,
    required this.icon,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                Text(desc, style: const TextStyle(height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bullets extends StatelessWidget {
  final List<String> items;
  const _Bullets({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "•  ",
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Expanded(
                    child: Text(t, style: const TextStyle(height: 1.45)),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: const Color(0xFFB11217)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}