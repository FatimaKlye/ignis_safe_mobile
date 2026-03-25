import 'package:flutter/material.dart';
import 'pre_assessment_building.dart';

class LearningMaterialTenementPage extends StatefulWidget {
  const LearningMaterialTenementPage({super.key});

  @override
  State<LearningMaterialTenementPage> createState() =>
      _LearningMaterialTenementPageState();
}

class _LearningMaterialTenementPageState
    extends State<LearningMaterialTenementPage> {
  static const accent = Color(0xFF7C3AED); // purple primary
  static const accent2 = Color(0xFF4338CA); // deep indigo

  final PageController _pageCtrl = PageController();
  final ScrollController _scrollCtrl = ScrollController();

  int _pageIndex = 0;

  double _progress = 0.0;
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
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const PreAssessmentBuildingPage(),
        ),
      );
    }
  }

  // ---------- POPUPS ----------
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

  void _showDoThisNowPopup() {
    _showInfoPopup(
      title: "If there is a fire in a tenement building",
      icon: Icons.local_fire_department_rounded,
      color: const Color(0xFFDC2626),
      message:
          "1) Alert other occupants immediately.\n"
          "2) Leave through the nearest safe exit.\n"
          "3) Stay low if there is smoke.\n"
          "4) Do NOT use elevators.\n"
          "5) Close doors behind you if possible.\n"
          "6) Go to the assembly area and call for help.",
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _pageIndex == 2;

    return Scaffold(
      body: Stack(
        children: [
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
                        padding: const EdgeInsets.only(left: 25),
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
                                  Icon(Icons.apartment_rounded,
                                      color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    "MODULE 5",
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
                                "Tenement Fire: What It Is, Common Causes, and What To Do",
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
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: SizedBox(
                          height: 6,
                          child: LinearProgressIndicator(
                            value: _progress,
                            backgroundColor: Colors.white.withOpacity(0.25),
                            valueColor: const AlwaysStoppedAnimation(accent2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
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
                Expanded(
                  child: PageView(
                    controller: _pageCtrl,
                    onPageChanged: (i) {
                      setState(() => _pageIndex = i);
                      _resetForNewPage();
                    },
                    children: [
                      _pageWrap(_page1OverviewAndTypes()),
                      _pageWrap(_page2CausesAndPrevention()),
                      _pageWrap(_page3EmergencyResponse()),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(25, 8, 25, 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF7C3AED)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        onPressed: _goBack,
                        child: const Text(
                          "« BACK",
                          style: TextStyle(
                            color: Color(0xFF7C3AED),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
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
  Widget _page1OverviewAndTypes() {
    return _ModernCard(
      accent1: accent,
      accent2: accent2,
      pageTitle: "PAGE 1 – TENEMENT FIRE OVERVIEW",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              "What is a Tenement Fire?",
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
                asset: "assets/tenement_overview.png",
                c1: accent,
                c2: accent2,
              ),
              const SizedBox(width: 15),
              const Expanded(
                child: Text(
                  "A tenement fire happens in a residential building with many rooms or floors. It is dangerous because flames and smoke can spread quickly through hallways, stairs, doors, and nearby units.",
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
          _Callout(
            icon: Icons.warning_rounded,
            color: const Color(0xFFDC2626),
            title: "Why it is dangerous",
            lines: const [
              "Many people may need to escape at the same time.",
              "Smoke can rise fast to upper floors.",
              "Narrow exits and blocked hallways increase risk.",
            ],
          ),
          const SizedBox(height: 14),
          _ChipLine(
            icon: Icons.menu_book_rounded,
            color: const Color(0xFF7C3AED),
            text: "Tap the buttons below for quick pop-ups.",
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionPill(
                  icon: Icons.help_rounded,
                  label: "Why it spreads",
                  onTap: () => _showInfoPopup(
                    title: "Why tenement fires spread fast",
                    message:
                        "Fire can move from one room or floor to another through open doors, windows, stairways, electrical lines, and flammable materials stored close together.",
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionPill(
                  icon: Icons.local_fire_department_rounded,
                  label: "If fire starts",
                  onTap: _showDoThisNowPopup,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionTitle("Common Types of Tenement Fires"),
          const SizedBox(height: 12),
          const _MiniTile(
            color: Color(0xFF7C3AED),
            icon: Icons.electrical_services_rounded,
            title: "Electrical Fire",
            desc:
                "Faulty wiring, overloaded outlets, or illegal connections cause ignition.",
          ),
          const SizedBox(height: 10),
          const _MiniTile(
            color: Color(0xFF6366F1),
            icon: Icons.local_fire_department_rounded,
            title: "Cooking Fire",
            desc:
                "Unattended stoves or open flames inside small living spaces start fires.",
          ),
          const SizedBox(height: 10),
          const _MiniTile(
            color: Color(0xFF7C3AED),
            icon: Icons.smoking_rooms_rounded,
            title: "Open Flame Fire",
            desc:
                "Candles, matches, or cigarettes ignite curtains, bedding, or trash.",
          ),
          const SizedBox(height: 10),
          const _MiniTile(
            color: Color(0xFF8B5CF6),
            icon: Icons.apartment_rounded,
            title: "Multi-floor Spread",
            desc:
                "A small fire grows and spreads upward through stairs, hallways, and nearby rooms.",
          ),
        ],
      ),
    );
  }

  // ===================== PAGE 2 =====================
  Widget _page2CausesAndPrevention() {
    return _ModernCard(
      accent1: accent2,
      accent2: accent,
      pageTitle: "PAGE 2 – CAUSES & PREVENTION",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              "Common Causes of Tenement Fires",
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
                icon: Icons.apartment_rounded,
                c1: accent2,
                c2: accent,
              ),
              SizedBox(width: 15),
              Expanded(
                child: _Bullets(
                  items: [
                    "Overloaded outlets and tangled extension cords",
                    "Illegal or unsafe electrical wiring",
                    "Unattended cooking inside rooms or shared areas",
                    "Candles or cigarettes left burning",
                    "Flammable items stored in narrow spaces",
                    "Blocked exits, stairs, or hallways",
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
                  icon: Icons.quiz_rounded,
                  label: "Quick check",
                  onTap: () => _showInfoPopup(
                    title: "Quick Check",
                    icon: Icons.check_circle_rounded,
                    color: const Color(0xFF4338CA),
                    message:
                        "In crowded buildings, one unsafe outlet or blocked exit can put many families at risk, not just one room.",
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionPill(
                  icon: Icons.tips_and_updates_rounded,
                  label: "Safety tips",
                  onTap: () => _showInfoPopup(
                    title: "Safety Tips",
                    icon: Icons.tips_and_updates_rounded,
                    color: const Color(0xFF6366F1),
                    message:
                        "• Avoid overloading outlets.\n"
                        "• Keep exits and stairs clear.\n"
                        "• Check wiring regularly.\n"
                        "• Do not leave open flames unattended.\n"
                        "• Know the nearest safe exit.",
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _ChipLine(
            icon: Icons.fact_check_rounded,
            color: Color(0xFF7C3AED),
            text: "Prevention protects the whole building, not only one room.",
          ),
          const SizedBox(height: 24),
          const _SectionTitle("Prevention (Simple Steps)"),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ImageBox(
                asset: "assets/prevent_tenement.png",
                c1: accent2,
                c2: accent,
              ),
              const SizedBox(width: 15),
              const Expanded(
                child: _Bullets(
                  items: [
                    "Do not overload electrical outlets.",
                    "Repair unsafe wiring immediately.",
                    "Keep hallways, exits, and stairs clear.",
                    "Store flammable items away from heat.",
                    "Turn off appliances when not in use.",
                    "Teach everyone the evacuation route.",
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _Callout(
            icon: Icons.shield_rounded,
            color: Color(0xFF4338CA),
            title: "Prevention goal",
            lines: [
              "Reduce ignition sources, keep escape paths open, and make evacuation easier for everyone.",
            ],
          ),
        ],
      ),
    );
  }

  // ===================== PAGE 3 =====================
  Widget _page3EmergencyResponse() {
    return _ModernCard(
      accent1: const Color(0xFF6366F1),
      accent2: accent,
      pageTitle: "PAGE 3 – WHAT TO DO DURING A TENEMENT FIRE",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              "Emergency Response",
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
                c1: Color(0xFF6366F1),
                c2: Color(0xFF7C3AED),
              ),
              SizedBox(width: 15),
              Expanded(
                child: _Bullets(
                  items: [
                    "Alert nearby occupants immediately.",
                    "Leave using the nearest safe stairway or exit.",
                    "Stay low if smoke is present.",
                    "Do NOT use elevators.",
                    "Close doors behind you if possible.",
                    "Go to a safe open area and wait for responders.",
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
                  icon: Icons.smoke_free_rounded,
                  label: "Smoke rule",
                  onTap: () => _showInfoPopup(
                    title: "Smoke Rule",
                    icon: Icons.block_rounded,
                    color: const Color(0xFFDC2626),
                    message:
                        "Smoke rises and spreads fast in multi-floor buildings. Stay low to breathe cleaner air and move carefully toward the nearest safe exit.",
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionPill(
                  icon: Icons.help_center_rounded,
                  label: "When trapped",
                  onTap: () => _showInfoPopup(
                    title: "If you are trapped",
                    icon: Icons.warning_amber_rounded,
                    color: const Color(0xFFDC2626),
                    message:
                        "Stay inside a room if the hallway is full of smoke or fire. Close the door, block gaps if possible, signal from a window, and call for help.",
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
                asset: "assets/response_tenement.png",
                c1: const Color(0xFF4338CA),
                c2: accent,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle("One-minute plan"),
                    const SizedBox(height: 10),
                    const _Bullets(
                      items: [
                        "Warn others.",
                        "Use the safest exit.",
                        "Stay low in smoke.",
                        "Do not go back inside.",
                      ],
                    ),
                    const SizedBox(height: 8),
                    _ActionPill(
                      icon: Icons.play_circle_rounded,
                      label: "Show steps",
                      onTap: _showDoThisNowPopup,
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
              "In a crowded multi-floor building, evacuation must be fast and orderly. Your safety comes first.",
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
            Icon(icon, size: 18, color: const Color(0xFF7C3AED)),
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