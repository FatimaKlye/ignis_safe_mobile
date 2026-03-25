import 'package:flutter/material.dart';
import 'pre_assess_instruction.dart';

class LearningMaterialKitchenPage extends StatefulWidget {
  const LearningMaterialKitchenPage({super.key});

  @override
  State<LearningMaterialKitchenPage> createState() =>
      _LearningMaterialKitchenPageState();
}

class _LearningMaterialKitchenPageState extends State<LearningMaterialKitchenPage> {
  static const accent = Color(0xFFF59E0B); // amber primary
  static const accent2 = Color(0xFFEA580C); // deep orange

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
          builder: (_) => const PreAssessmentIntroPage2(),
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
      title: "If a pan catches fire",
      icon: Icons.local_fire_department_rounded,
      color: const Color(0xFFDC2626),
      message:
          "1) Turn off the heat.\n"
          "2) Cover the pan with a metal lid or baking tray.\n"
          "3) Do NOT carry the pan.\n"
          "4) Do NOT use water on burning oil.\n"
          "5) If it grows, evacuate and call for help.",
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
                                  "MODULE 4",
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
                              "Kitchen Fire: What It Is, Common Types, and What To Do",
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
                          side: const BorderSide(color: Color(0xFFF59E0B)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        onPressed: _goBack,
                        child: const Text(
                          "« BACK",
                          style: TextStyle(
                            color: Color(0xFFF59E0B),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
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
      // ✅ Removed floatingActionButton
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
      pageTitle: "PAGE 1 – KITCHEN FIRE OVERVIEW",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              "What is a Kitchen Fire?",
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
                asset: "assets/kitchen_overview.png",
                c1: accent,
                c2: accent2,
              ),
              const SizedBox(width: 15),
              const Expanded(
                child: Text(
                  "A kitchen fire starts in the cooking area. It often happens when food, oil, or appliances overheat. Most kitchen fires spread fast because heat and grease build up quickly.",
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
            title: "Common danger",
            lines: const [
              "Grease can ignite suddenly.",
              "Smoke can block vision fast.",
              "Wrong action (like water on oil) can make it worse.",
            ],
          ),

          const SizedBox(height: 14),

          _ChipLine(
            icon: Icons.menu_book_rounded,
            color: const Color(0xFFF59E0B),
            text: "Tap the buttons below for quick pop-ups.",
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _ActionPill(
                  icon: Icons.help_rounded,
                  label: "Why it happens",
                  onTap: () => _showInfoPopup(
                    title: "Why kitchen fires happen",
                    message:
                        "Usually from unattended cooking, overheated oil, grease buildup, or flammable items near heat.",
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionPill(
                  icon: Icons.local_fire_department_rounded,
                  label: "If pan ignites",
                  onTap: _showDoThisNowPopup,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          const _SectionTitle("Types of Kitchen Fires"),
          const SizedBox(height: 12),

          const _MiniTile(
            color: Color(0xFFF59E0B),
            icon: Icons.oil_barrel_rounded,
            title: "Grease Fire",
            desc: "Cooking oil or fat overheats and ignites (fast and intense).",
          ),
          const SizedBox(height: 10),
          const _MiniTile(
            color: Color(0xFFF59E0B),
            icon: Icons.local_pizza_rounded,
            title: "Oven Fire",
            desc: "Food spills or grease buildup burns inside the oven.",
          ),
          const SizedBox(height: 10),
          const _MiniTile(
            color: Color(0xFFFB923C),
            icon: Icons.microwave_rounded,
            title: "Microwave Fire",
            desc: "Metal or overheated food ignites and causes flames/smoke.",
          ),
          const SizedBox(height: 10),
          const _MiniTile(
            color: Color(0xFFEA580C),
            icon: Icons.local_gas_station_rounded,
            title: "Gas Stove Fire",
            desc: "Flame flare-ups or leaking gas ignites near the stove.",
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
              "Common Causes of Kitchen Fires",
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
                icon: Icons.kitchen_rounded,
                c1: accent2,
                c2: accent,
              ),
              SizedBox(width: 15),
              Expanded(
                child: _Bullets(
                  items: [
                    "Leaving cooking unattended",
                    "Oil overheating while frying",
                    "Grease buildup on stove/hood",
                    "Towels or paper near flames",
                    "Cooking while tired or distracted",
                    "Wrong use of appliances (dirty toaster, etc.)",
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
                    color: const Color(0xFFF59E0B),
                    message:
                        "If you leave the kitchen for even 1 minute while frying, risk increases a lot. Stay nearby and keep heat controlled.",
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
                    color: const Color(0xFFEA580C),
                    message:
                        "• Keep a lid nearby when cooking.\n"
                        "• Clean grease regularly.\n"
                        "• Keep flammables away from heat.\n"
                        "• Turn pot handles inward.\n"
                        "• Don’t overheat oil.",
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          const _ChipLine(
            icon: Icons.fact_check_rounded,
            color: Color(0xFFF59E0B),
            text: "Small habits prevent most kitchen fires.",
          ),

          const SizedBox(height: 24),

          const _SectionTitle("Prevention (Simple Steps)"),
          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ImageBox(
                asset: "assets/prevent_kitchen.png",
                c1: accent2,
                c2: accent,
              ),
              const SizedBox(width: 15),
              const Expanded(
                child: _Bullets(
                  items: [
                    "Keep a lid near the pan when cooking.",
                    "Clean grease from stove and hood.",
                    "Keep flammables away from heat.",
                    "Turn handles inward.",
                    "Use the right heat level (don’t overheat oil).",
                    "Know your extinguisher location.",
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          const _Callout(
            icon: Icons.shield_rounded,
            color: Color(0xFFF59E0B),
            title: "Prevention goal",
            lines: [
              "Reduce heat, reduce grease buildup, and keep flammable items away.",
            ],
          ),
        ],
      ),
    );
  }

  // ===================== PAGE 3 =====================
  Widget _page3EmergencyResponse() {
    return _ModernCard(
      accent1: const Color(0xFFEA580C),
      accent2: accent,
      pageTitle: "PAGE 3 – WHAT TO DO DURING A KITCHEN FIRE",
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
                c1: Color(0xFFEA580C),
                c2: Color(0xFFF59E0B),
              ),
              SizedBox(width: 15),
              Expanded(
                child: _Bullets(
                  items: [
                    "Turn off heat source if safe.",
                    "Cover small pan fire with a metal lid/tray.",
                    "Do NOT use water on burning oil/grease.",
                    "Use a fire extinguisher if trained and safe.",
                    "If it spreads: evacuate and call emergency services.",
                    "Close doors behind you to slow the fire.",
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
                  icon: Icons.local_fire_department_rounded,
                  label: "Grease fire rule",
                  onTap: () => _showInfoPopup(
                    title: "Grease Fire Rule",
                    icon: Icons.block_rounded,
                    color: const Color(0xFFDC2626),
                    message:
                        "Never pour water on burning oil. Water can spread burning grease and cause flare-ups.",
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionPill(
                  icon: Icons.help_center_rounded,
                  label: "When to evacuate",
                  onTap: () => _showInfoPopup(
                    title: "Evacuate when…",
                    icon: Icons.directions_run_rounded,
                    color: const Color(0xFFDC2626),
                    message:
                        "Evacuate immediately if flames grow, smoke fills the room, or you can’t control it quickly. Call for help.",
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
                asset: "assets/response_kitchen.png",
                c1: const Color(0xFFEA580C),
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
                        "Stop the heat.",
                        "Smother small flames.",
                        "Use extinguisher only if safe.",
                        "Get out if unsure.",
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
              "Your safety is the priority. If you feel unsafe, evacuate and call for help.",
            ],
          ),
        ],
      ),
    );
  }
}

// ===================== UI WIDGETS =====================
// (unchanged below)

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
            Icon(icon, size: 18, color: const Color(0xFFF59E0B)),
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