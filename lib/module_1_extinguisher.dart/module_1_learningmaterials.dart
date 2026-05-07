import 'package:flutter/material.dart';
import 'pre_assess_instruction.dart';

class LearningMaterialExtinguisherPage extends StatefulWidget {
  const LearningMaterialExtinguisherPage({super.key});

  @override
  State<LearningMaterialExtinguisherPage> createState() =>
      _LearningMaterialExtinguisherPageState();
}

class _LearningMaterialExtinguisherPageState
    extends State<LearningMaterialExtinguisherPage> {
  static const accent = Color(0xFFB11217);
  static const accent2 = Color(0xFF7A1014);

  final PageController _pageCtrl = PageController();
  final ScrollController _scrollCtrl = ScrollController();

  int _pageIndex = 0;
  double _progress = 0.0;
  bool _canNext = false;
  bool _isSwitchingPage = false;
  bool _lastPageCompleted = false;


  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    if (_isSwitchingPage) return;

    final max = _scrollCtrl.position.maxScrollExtent;
    final off = _scrollCtrl.offset;

    if (max <= 0) {
      if (_progress != 1.0 || !_canNext) {
        setState(() {
          _progress = 1.0;
          _canNext = _pageIndex != 2;
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

    if (_pageIndex == 2 && nearBottom) {
      _lastPageCompleted = true;
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
    // Important: the same ScrollController is reused across PageView pages.
    // We must force-reset scroll AFTER the new page attaches, otherwise the old
    // "near bottom" state can carry over and incorrectly enable the button.
    setState(() {
      _isSwitchingPage = true;
      _progress = 0.0;
      _canNext = false;
      _lastPageCompleted = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.jumpTo(0);
      }
      setState(() => _isSwitchingPage = false);
      _onScroll();
    });
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
        MaterialPageRoute(builder: (_) => const PreAssessmentIntroPage()),
      );
    }
  }

  void _showInfoPopup({
    required String title,
    required String message,
    IconData icon = Icons.info_rounded,
    Color color = accent,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontWeight: FontWeight.w900, color: color),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(height: 1.5, color: Color(0xFF374151)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_tStatic(context, "OK", "Sige")),
          ),
        ],
      ),
    );
  }

  void _showPASSPopup() {
    _showInfoPopup(
      title: _tStatic(context, "PASS Method", "Paraan ng PASS"),
      icon: Icons.checklist_rounded,
      color: const Color(0xFFD62828),
      message: _tStatic(
        context,
        "P — Pull the pin\n"
            "A — Aim at the base of the fire\n"
            "S — Squeeze the handle\n"
            "S — Sweep side to side\n\n"
            "Stop if the fire grows or you feel unsafe.",
        "P — Hilahin ang pin\n"
            "A — Itutok sa pinagmumulan ng apoy\n"
            "S — Pisilin ang hawakan\n"
            "S — Iwasiwas pakaliwa't pakanan\n\n"
            "Huminto kung lumalaki ang apoy o delikado na.",
      ),
    );
  }

  void _showWhenNotToUsePopup() {
    _showInfoPopup(
      title: _tStatic(
        context,
        "Do NOT use an extinguisher if…",
        "HUWAG gumamit ng pamatay-sunog kung…",
      ),
      icon: Icons.block_rounded,
      color: const Color(0xFFDC2626),
      message: _tStatic(
        context,
        "• The fire is too large or spreading fast\n"
            "• Thick smoke is building up\n"
            "• You do not have a clear exit behind you\n"
            "• You are unsure what is burning\n\n"
            "Evacuate and call emergency services.",
        "• Masyadong malaki o mabilis kumalat ang apoy\n"
            "• Makapal na usok ang namumuo\n"
            "• Wala kang malinaw na daan palabas sa likod mo\n"
            "• Hindi ka sigurado kung ano ang nasusunog\n\n"
            "Lumikas at tumawag sa emergency services.",
      ),
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
                const SizedBox(height: 10),

                // KEEPING YOUR HEADER
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
                      Center(
                        child: Text(
                          _tStatic(
                            context,
                            "Learning Material",
                            "Materyal sa Pag-aaral",
                          ),
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
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.bolt_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    _tStatic(context, "MODULE 1", "MODYUL 1"),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Text(
                                _tStatic(
                                  context,
                                  "Fire Extinguisher: Basics, Types, and How to Use",
                                  "Pamatay-Sunog: Mga Batayan, Uri, at Paano Gamitin",
                                ),
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
                      _pageWrap(_page1ExtinguisherBasics()),
                      _pageWrap(_page2TypesAndUses()),
                      _pageWrap(_page3HowToUseAndSafety()),
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
                          side: const BorderSide(color: accent),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        onPressed: _goBack,
                        child: Text(
                          _tStatic(context, "« BACK", "« BALIK"),
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        onPressed: (isLast ? _lastPageCompleted : _canNext) ? _goNext : null,
                        child: Text(
                          isLast
                              ? _tStatic(
                                  context,
                                  "Start pre test",
                                  "Simulan ang paunang pagsusulit",
                                )
                              : _tStatic(context, "NEXT »", "SUNOD »"),
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

  Widget _page1ExtinguisherBasics() {
    return _ModernCard(
      accent1: accent,
      accent2: accent2,
      pageTitle: _tStatic(
        context,
        "PAGE 1 · FIRE EXTINGUISHER BASICS",
        "PAHINA 1 · MGA BATAYAN NG PAMATAY-SUNOG",
      ),
      icon: Icons.lightbulb_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _tStatic(
              context,
              "What is a Fire Extinguisher?",
              "Ano ang Pamatay-Sunog?",
            ),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _tStatic(
              context,
              "A fire extinguisher is a portable safety device used to control small fires before they spread.",
              "Ang pamatay-sunog ay isang portable na kagamitang pangkaligtasan na ginagamit upang mapigil ang maliliit na apoy bago ito kumalat.",
            ),
            style: TextStyle(
              fontSize: 14,
              height: 1.55,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 16),
          _LessonIntroStrip(
            icon: Icons.menu_book_rounded,
            text: _tStatic(
              context,
              "In this lesson, you will learn what a fire extinguisher does, when to use it, and when to stop and evacuate.",
              "Sa araling ito, malalaman mo kung ano ang ginagawa ng pamatay-sunog, kailan ito gagamitin, at kailan ka dapat huminto at lumikas.",
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ImageBox(
                asset: "assets/fire_ex.png",
                c1: accent,
                c2: accent2,
                fallbackIcon: Icons.fire_extinguisher_rounded,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MiniHeadline(
                      _tStatic(context, "How does it work?", "Paano ito gumagana?"),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _tStatic(
                        context,
                        "It releases an extinguishing agent that removes heat, reduces oxygen, or interrupts the chemical reaction of a fire.",
                        "Naglalabas ito ng sangkap na pumapawi ng apoy sa pamamagitan ng pag-alis ng init, pagbawas ng oxygen, o pagpigil sa reaksiyong kemikal ng apoy.",
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.55,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _Callout(
            icon: Icons.warning_amber_rounded,
            color: Color(0xFFDC2626),
            title: _tStatic(context, "Important reminder", "Mahalagang paalala"),
            lines: [
              _tStatic(
                context,
                "Use extinguishers only on small, early-stage fires.",
                "Gamitin lamang ang pamatay-sunog sa maliliit at nagsisimula pa lang na apoy.",
              ),
              _tStatic(
                context,
                "Always choose the correct extinguisher type.",
                "Palaging pumili ng tamang uri ng pamatay-sunog.",
              ),
              _tStatic(
                context,
                "If the situation feels unsafe, evacuate first.",
                "Kung hindi ligtas ang sitwasyon, lumikas muna.",
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ActionPill(
                  icon: Icons.checklist_rounded,
                  label: _tStatic(context, "PASS method", "Paraan ng PASS"),
                  onTap: _showPASSPopup,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionPill(
                  icon: Icons.block_rounded,
                  label: _tStatic(
                    context,
                    "When NOT to use",
                    "Kailan HINDI gagamitin",
                  ),
                  onTap: _showWhenNotToUsePopup,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _ChipLine(
            icon: Icons.flag_rounded,
            color: Color(0xFFB11217),
            text: _tStatic(
              context,
              "Goal: use the right extinguisher, quickly and safely.",
              "Layunin: gamitin ang tamang pamatay-sunog, nang mabilis at ligtas.",
            ),
          ),
        ],
      ),
    );
  }

  Widget _page2TypesAndUses() {
    return _ModernCard(
      accent1: accent2,
      accent2: accent,
      pageTitle: _tStatic(
        context,
        "PAGE 2 · TYPES OF FIRE EXTINGUISHERS",
        "PAHINA 2 · MGA URI NG PAMATAY-SUNOG",
      ),
      icon: Icons.category_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _tStatic(
              context,
              "Different Fires Need Different Extinguishers",
              "Magkakaibang apoy ay nangangailangan ng magkakaibang pamatay-sunog",
            ),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _tStatic(
              context,
              "Using the wrong extinguisher can make a fire worse. Learn the common classes and what they are used for.",
              "Kapag mali ang ginamit na pamatay-sunog, maaari pang lumala ang apoy. Alamin ang karaniwang mga klase at kung para saan ang mga ito.",
            ),
            style: TextStyle(
              fontSize: 14,
              height: 1.55,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 16),
          _LessonIntroStrip(
            icon: Icons.touch_app_rounded,
            text: _tStatic(
              context,
              "Read the guide below, then tap through the fire classes to understand what type matches each situation.",
              "Basahin ang gabay sa ibaba, tapos i-tap ang bawat klase ng apoy upang malaman kung alin ang akma sa bawat sitwasyon.",
            ),
          ),
          const SizedBox(height: 18),
          _SectionTitle(_tStatic(context, "Quick guide", "Mabilis na gabay")),
          const SizedBox(height: 12),
          _MiniTile(
            color: Color(0xFF16A34A),
            icon: Icons.park_rounded,
            title: "Class A",
            desc: _tStatic(
              context,
              "For paper, wood, cloth, and ordinary combustible materials.",
              "Para sa papel, kahoy, tela, at karaniwang nasusunog na materyales.",
            ),
          ),
          const SizedBox(height: 10),
          _MiniTile(
            color: Color(0xFFF59E0B),
            icon: Icons.local_gas_station_rounded,
            title: "Class B",
            desc: _tStatic(
              context,
              "For flammable liquids like oil, gasoline, paint, and solvents.",
              "Para sa madaling magliyab na likido tulad ng langis, gasolina, pintura, at solvents.",
            ),
          ),
          const SizedBox(height: 10),
          _MiniTile(
            color: Color(0xFF2563EB),
            icon: Icons.bolt_rounded,
            title: "Class C",
            desc: _tStatic(
              context,
              "For energized electrical equipment such as wiring and appliances.",
              "Para sa mga kagamitang elektrikal na may kuryente tulad ng mga kable at appliances.",
            ),
          ),
          const SizedBox(height: 10),
          _MiniTile(
            color: Color(0xFF4B5563),
            icon: Icons.precision_manufacturing_rounded,
            title: "Class D",
            desc: _tStatic(
              context,
              "For combustible metals such as magnesium, sodium, or lithium.",
              "Para sa mga metal na madaling masunog tulad ng magnesium, sodium, o lithium.",
            ),
          ),
          const SizedBox(height: 10),
          _MiniTile(
            color: accent,
            icon: Icons.restaurant_rounded,
            title: "Class K",
            desc: _tStatic(
              context,
              "For kitchen fires involving cooking oils, fats, and grease.",
              "Para sa mga apoy sa kusina na may kinalaman sa mantika, taba, at grasa.",
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _ActionPill(
                  icon: Icons.search_rounded,
                  label: _tStatic(context, "How to choose", "Paano pumili"),
                  onTap: () => _showInfoPopup(
                    title: _tStatic(
                      context,
                      "How to choose fast",
                      "Paano pumili nang mabilis",
                    ),
                    icon: Icons.search_rounded,
                    color: const Color(0xFFB11217),
                    message: _tStatic(
                      context,
                      "1) Identify what is burning.\n"
                          "2) Match the extinguisher class label.\n"
                          "3) Keep an exit behind you.\n"
                          "4) If unsure, evacuate.",
                      "1) Tukuyin kung ano ang nasusunog.\n"
                          "2) Itugma ang label ng klase ng pamatay-sunog.\n"
                          "3) Panatilihing may daan palabas sa likod mo.\n"
                          "4) Kapag hindi sigurado, lumikas.",
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionPill(
                  icon: Icons.label_important_rounded,
                  label: _tStatic(context, "Read the label", "Basahin ang label"),
                  onTap: () => _showInfoPopup(
                    title: _tStatic(context, "Read the label", "Basahin ang label"),
                    icon: Icons.label_important_rounded,
                    color: const Color(0xFFD62828),
                    message: _tStatic(
                      context,
                      "Look for the fire class letters A, B, C, D, or K on the extinguisher body.",
                      "Hanapin ang mga letrang A, B, C, D, o K sa katawan ng pamatay-sunog.",
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ActionWideCard(
            icon: Icons.local_fire_department_rounded,
            title: _tStatic(
              context,
              "Open fire class guide",
              "Buksan ang gabay sa klase ng apoy",
            ),
            subtitle: _tStatic(
              context,
              "Tap to view the detailed classes of fire page.",
              "I-tap upang tingnan ang detalyadong pahina ng mga klase ng apoy.",
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ClassesOfFirePage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _page3HowToUseAndSafety() {
    return _ModernCard(
      accent1: const Color(0xFFD62828),
      accent2: accent,
      pageTitle: _tStatic(
        context,
        "PAGE 3 · HOW TO USE & SAFETY",
        "PAHINA 3 · PAANO GAMITIN AT KALIGTASAN",
      ),
      icon: Icons.shield_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _tStatic(
              context,
              "How to Use a Fire Extinguisher",
              "Paano Gumamit ng Pamatay-Sunog",
            ),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _tStatic(
              context,
              "Using an extinguisher properly can help stop a small fire from growing. Learn the PASS method and the safety rules before acting.",
              "Ang tamang paggamit ng pamatay-sunog ay makatutulong pigilan ang maliit na apoy bago ito lumaki. Alamin muna ang PASS method at mga panuntunang pangkaligtasan bago kumilos.",
            ),
            style: TextStyle(
              fontSize: 14,
              height: 1.55,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 16),
          _LessonIntroStrip(
            icon: Icons.verified_user_rounded,
            text: _tStatic(
              context,
              "Follow the PASS method and stop immediately if the fire cannot be controlled within a few seconds.",
              "Sundin ang PASS method at huminto agad kung hindi makontrol ang apoy sa loob ng ilang segundo.",
            ),
          ),
          const SizedBox(height: 18),
          _SectionTitle(
            _tStatic(
              context,
              "PASS in 4 simple steps",
              "PASS sa 4 na simpleng hakbang",
            ),
          ),
          const SizedBox(height: 12),
          _PassStepCard(
            letter: "P",
            word: _tStatic(context, "Pull", "Hilahin"),
            desc: _tStatic(
              context,
              "Pull the safety pin.",
              "Hilahin ang safety pin.",
            ),
          ),
          const SizedBox(height: 10),
          _PassStepCard(
            letter: "A",
            word: _tStatic(context, "Aim", "Itutok"),
            desc: _tStatic(
              context,
              "Aim at the base of the fire, not the flames.",
              "Itutok sa pinakailalim ng apoy, hindi sa mga liyab.",
            ),
          ),
          const SizedBox(height: 10),
          _PassStepCard(
            letter: "S",
            word: _tStatic(context, "Squeeze", "Pisilin"),
            desc: _tStatic(
              context,
              "Squeeze the handle in a controlled way.",
              "Pisilin ang hawakan nang kontrolado.",
            ),
          ),
          const SizedBox(height: 10),
          _PassStepCard(
            letter: "S",
            word: _tStatic(context, "Sweep", "Iwasiwas"),
            desc: _tStatic(
              context,
              "Sweep side to side until the fire is out.",
              "Iwasiwas pakaliwa at pakanan hanggang mamatay ang apoy.",
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _ActionPill(
                  icon: Icons.checklist_rounded,
                  label: _tStatic(
                    context,
                    "Show PASS steps",
                    "Ipakita ang mga hakbang ng PASS",
                  ),
                  onTap: _showPASSPopup,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionPill(
                  icon: Icons.security_rounded,
                  label: _tStatic(
                    context,
                    "Safety rule",
                    "Panuntunang pangkaligtasan",
                  ),
                  onTap: () => _showInfoPopup(
                    title: _tStatic(
                      context,
                      "Safety rule",
                      "Panuntunang pangkaligtasan",
                    ),
                    icon: Icons.security_rounded,
                    color: const Color(0xFFD62828),
                    message: _tStatic(
                      context,
                      "If you cannot control the fire within a few seconds, stop and evacuate. Close doors behind you and call for help.",
                      "Kung hindi mo makontrol ang apoy sa loob ng ilang segundo, huminto at lumikas. Isara ang mga pinto sa likod mo at humingi ng tulong.",
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _Callout(
            icon: Icons.info_outline_rounded,
            color: Color(0xFFB11217),
            title: _tStatic(
              context,
              "Before using an extinguisher",
              "Bago gumamit ng pamatay-sunog",
            ),
            lines: [
              _tStatic(
                context,
                "Check the pressure gauge if present.",
                "Suriin ang pressure gauge kung mayroon.",
              ),
              _tStatic(
                context,
                "Keep your back toward an exit.",
                "Panatilihing nakaharap sa labasan ang iyong likod.",
              ),
              _tStatic(
                context,
                "Make sure the extinguisher matches the fire class.",
                "Siguraduhing tugma ang pamatay-sunog sa klase ng apoy.",
              ),
              _tStatic(
                context,
                "Watch for re-ignition and be ready to evacuate.",
                "Bantayan kung muling sisiklab ang apoy at maging handang lumikas.",
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Callout(
            icon: Icons.block_rounded,
            color: Color(0xFFDC2626),
            title: _tStatic(context, "Remember", "Tandaan"),
            lines: [
              _tStatic(
                context,
                "Never risk your life for property. If it feels unsafe, evacuate immediately.",
                "Huwag isugal ang iyong buhay para sa ari-arian. Kung hindi ligtas, lumikas agad.",
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModernCard extends StatelessWidget {
  final Color accent1;
  final Color accent2;
  final String pageTitle;
  final IconData icon;
  final Widget child;

  const _ModernCard({
    required this.accent1,
    required this.accent2,
    required this.pageTitle,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCFC),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [accent1, accent2],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  pageTitle,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
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
  final IconData fallbackIcon;

  const _ImageBox({
    required this.asset,
    required this.c1,
    required this.c2,
    required this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 118,
      height: 118,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c1.withOpacity(0.12), c2.withOpacity(0.08)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: c1.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Image.asset(
        asset,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(fallbackIcon, size: 42, color: c1),
      ),
    );
  }
}

class _MiniHeadline extends StatelessWidget {
  final String text;
  const _MiniHeadline(this.text);

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

class _LessonIntroStrip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _LessonIntroStrip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFB11217).withOpacity(0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFB11217), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                height: 1.45,
                color: Color(0xFF374151),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
        fontSize: 17,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.15)),
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
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: color,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 10),
                ...lines.map(
                  (l) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "• ",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: color,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            l,
                            style: const TextStyle(
                              height: 1.45,
                              color: Color(0xFF374151),
                            ),
                          ),
                        ),
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
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
                Text(
                  desc,
                  style: const TextStyle(
                    height: 1.45,
                    color: Color(0xFF4B5563),
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
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF7F7), Color(0xFFFFFBFB)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFB11217).withOpacity(0.08)),
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
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111827),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionWideCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionWideCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4F4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFB11217).withOpacity(0.10)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFB11217).withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.local_fire_department_rounded,
                color: Color(0xFFB11217),
              ),
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
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Color(0xFFB11217),
            ),
          ],
        ),
      ),
    );
  }
}

class _PassStepCard extends StatelessWidget {
  final String letter;
  final String word;
  final String desc;

  const _PassStepCard({
    required this.letter,
    required this.word,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFB11217).withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFB11217),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                letter,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  word,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    height: 1.45,
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

class ClassesOfFirePage extends StatelessWidget {
  const ClassesOfFirePage({super.key});

  @override
  Widget build(BuildContext context) {
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
                            child: Text(
                              _tStatic(context, "MODULE 1", "MODYUL 1"),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Flexible(
                            child: Text(
                              _tStatic(
                                context,
                                "Fire Extinguisher: Safe Use and Emergency Response",
                                "Pamatay-Sunog: Ligtas na Paggamit at Pagtugon sa Emerhensiya",
                              ),
                              style: const TextStyle(
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
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFCFC),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Text(
                                  _tStatic(
                                    context,
                                    "Classes of Fire Extinguisher",
                                    "Mga Klase ng Pamatay-Sunog",
                                  ),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFB11217),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _tStatic(
                                  context,
                                  "Fires are classified based on the type of fuel involved. Using the correct extinguisher is critical.",
                                  "Ang mga apoy ay inuuri batay sa uri ng nasusunog na materyal. Mahalaga ang paggamit ng tamang pamatay-sunog.",
                                ),
                                style: TextStyle(
                                  height: 1.55,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                              const SizedBox(height: 22),
                              Row(
                                children: [
                                  const Expanded(
                                    child: _ClassCard(
                                      label: "Class A",
                                      image: "assets/class_a.png",
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  const Expanded(
                                    child: _ClassCard(
                                      label: "Class B",
                                      image: "assets/class_b.png",
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const Expanded(
                                    child: _ClassCard(
                                      label: "Class C",
                                      image: "assets/class_c.png",
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  const Expanded(
                                    child: _ClassCard(
                                      label: "Class D",
                                      image: "assets/class_d.png",
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Row(
                                children: [
                                  Expanded(
                                    child: _ClassCard(
                                      label: "Class K",
                                      image: "assets/class_k.png",
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 28),
                              Text(
                                _tStatic(
                                  context,
                                  "Importance of Fire Extinguisher Training",
                                  "Kahalagahan ng Pagsasanay sa Pamatay-Sunog",
                                ),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _tStatic(
                                  context,
                                  "Learning how to use a fire extinguisher helps improve emergency preparedness, reduce injuries, and protect lives during fire incidents.",
                                  "Ang pag-aaral kung paano gumamit ng pamatay-sunog ay nakatutulong mapabuti ang kahandaan sa emerhensiya, mabawasan ang pinsala, at maprotektahan ang buhay sa mga insidente ng sunog.",
                                ),
                                style: TextStyle(
                                  height: 1.55,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                              const SizedBox(height: 25),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: Color(0xFFB11217),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(
                                      _tStatic(context, "« BACK", "« BALIK"),
                                      style: const TextStyle(
                                        color: Color(0xFFB11217),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFB11217),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    onPressed: () {},
                                    child: Text(
                                      _tStatic(
                                        context,
                                        "Start Pre - Test",
                                        "Simulan ang Paunang Pagsusulit",
                                      ),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
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

class _ClassCard extends StatelessWidget {
  final String label;
  final String image;

  const _ClassCard({required this.label, required this.image});

  @override
  Widget build(BuildContext context) {
    final displayLabel = Localizations.localeOf(context).languageCode == 'tl'
        ? label.replaceFirst('Class', 'Klase')
        : label;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _showModernClassSheet(context, label: label, image: image),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              displayLabel,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFFB11217),
              ),
            ),
            const SizedBox(height: 14),
            Image.asset(image, height: 86, fit: BoxFit.contain),
            const SizedBox(height: 10),
            Text(
              Localizations.localeOf(context).languageCode == 'tl'
                  ? "I-tap upang tingnan"
                  : "Tap to explore",
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showModernClassSheet(
  BuildContext context, {
  required String label,
  required String image,
}) {
  final data = _ClassPopupData.fromLabel(context, label);

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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(26),
              ),
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
                          child: Icon(data.icon, color: Colors.white, size: 24),
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
                Expanded(
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                    children: [
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
                      if (data.note != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: data.accent,
                                size: 18,
                              ),
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
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
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
                Text(
                  "• ",
                  style: TextStyle(fontWeight: FontWeight.w900, color: accent),
                ),
                Expanded(
                  child: Text(
                    line,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
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

  static _ClassPopupData fromLabel(BuildContext context, String label) {
    switch (label) {
      case "Class A":
        return _ClassPopupData(
          title: _tStatic(
            context,
            "Class A Fire Extinguisher",
            "Pamatay-Sunog para sa Class A",
          ),
          description: _tStatic(
            context,
            "Used for fires involving ordinary combustible materials. These are common in homes, schools, and offices.",
            "Ginagamit para sa apoy na may karaniwang nasusunog na materyales. Karaniwan ito sa mga bahay, paaralan, at opisina.",
          ),
          section1Title: _tStatic(
            context,
            "What is a Class A Fire?",
            "Ano ang Class A na Apoy?",
          ),
          section1Bullets: const [
            "Paper",
            "Wood",
            "Cloth",
            "Cardboard",
            "Plastics",
          ],
          section2Title: _tStatic(
            context,
            "Common Extinguishing Agents",
            "Karaniwang Pampatay ng Apoy",
          ),
          section2Bullets: const ["Water", "Foam", "Dry chemical (ABC type)"],
          headerGradient: const [Color(0xFFB11217), Color(0xFFE84C3D)],
          accent: const Color(0xFFB11217),
          softTint: const Color(0xFFFFF1F1),
          borderTint: const Color(0xFFFFD6D6),
          icon: Icons.local_fire_department_rounded,
          note: _tStatic(
            context,
            "Tip: Do not use water on electrical or flammable liquid fires.",
            "Paalala: Huwag gumamit ng tubig sa apoy na elektrikal o sa madaling magliyab na likido.",
          ),
        );
      case "Class B":
        return _ClassPopupData(
          title: _tStatic(
            context,
            "Class B Fire Extinguisher",
            "Pamatay-Sunog para sa Class B",
          ),
          description: _tStatic(
            context,
            "Used for fires involving flammable liquids and gases. These fires spread fast and must be smothered, not soaked.",
            "Ginagamit para sa apoy na may madaling magliyab na likido at gas. Mabilis kumalat ang mga ito at dapat tabunan, hindi binabaha.",
          ),
          section1Title: _tStatic(
            context,
            "What is a Class B Fire?",
            "Ano ang Class B na Apoy?",
          ),
          section1Bullets: const [
            "Gasoline",
            "Oil",
            "Paint",
            "Alcohol",
            "Propane",
          ],
          section2Title: _tStatic(
            context,
            "Common Extinguishing Agents",
            "Karaniwang Pampatay ng Apoy",
          ),
          section2Bullets: const [
            "Foam",
            "Carbon dioxide (CO2)",
            "Dry chemical (ABC or BC type)",
          ],
          headerGradient: const [Color(0xFF7B1FA2), Color(0xFF512DA8)],
          accent: const Color(0xFF6A1B9A),
          softTint: const Color(0xFFF6EEFF),
          borderTint: const Color(0xFFE3D2FF),
          icon: Icons.water_drop_rounded,
          note: _tStatic(
            context,
            "Tip: Never use water on flammable liquid fires—it can spread the fuel.",
            "Paalala: Huwag kailanman gumamit ng tubig sa apoy ng madaling magliyab na likido dahil maaari nitong ikalat ang gasolina o likido.",
          ),
        );
      case "Class C":
        return _ClassPopupData(
          title: _tStatic(
            context,
            "Class C Fire Extinguisher",
            "Pamatay-Sunog para sa Class C",
          ),
          description: _tStatic(
            context,
            "Designed for fires involving energized electrical equipment. The agent must not conduct electricity.",
            "Idinisenyo para sa apoy na may kagamitang elektrikal na may kuryente. Dapat hindi nakakapagpadaloy ng kuryente ang gamit na sangkap.",
          ),
          section1Title: _tStatic(
            context,
            "What is a Class C Fire?",
            "Ano ang Class C na Apoy?",
          ),
          section1Bullets: const [
            "Wiring",
            "Electrical panels",
            "Circuit breakers",
            "Appliances",
          ],
          section2Title: _tStatic(
            context,
            "Common Extinguishing Agents",
            "Karaniwang Pampatay ng Apoy",
          ),
          section2Bullets: const [
            "Carbon dioxide (CO2)",
            "Dry chemical (ABC or BC type)",
          ],
          headerGradient: const [Color(0xFF0D47A1), Color(0xFF1976D2)],
          accent: const Color(0xFF1565C0),
          softTint: const Color(0xFFEEF6FF),
          borderTint: const Color(0xFFD3E9FF),
          icon: Icons.bolt_rounded,
          note: _tStatic(
            context,
            "Safety: If power is turned off, the fire may become Class A or B depending on the fuel.",
            "Kaligtasan: Kapag naputol ang kuryente, maaaring maging Class A o B ang apoy depende sa nasusunog na materyal.",
          ),
        );
      case "Class D":
        return _ClassPopupData(
          title: _tStatic(
            context,
            "Class D Fire Extinguisher",
            "Pamatay-Sunog para sa Class D",
          ),
          description: _tStatic(
            context,
            "Used for fires involving combustible metals. These require special agents and procedures.",
            "Ginagamit para sa apoy na may mga metal na madaling masunog. Nangangailangan ito ng espesyal na sangkap at pamamaraan.",
          ),
          section1Title: _tStatic(
            context,
            "What is a Class D Fire?",
            "Ano ang Class D na Apoy?",
          ),
          section1Bullets: const [
            "Magnesium",
            "Titanium",
            "Sodium",
            "Potassium",
            "Lithium",
          ],
          section2Title: _tStatic(
            context,
            "Common Extinguishing Agents",
            "Karaniwang Pampatay ng Apoy",
          ),
          section2Bullets: const [
            "Special dry powder agents designed for metal fires",
          ],
          headerGradient: const [Color(0xFF455A64), Color(0xFF263238)],
          accent: const Color(0xFF37474F),
          softTint: const Color(0xFFF2F5F7),
          borderTint: const Color(0xFFDCE3E7),
          icon: Icons.precision_manufacturing_rounded,
          note: _tStatic(
            context,
            "Warning: Do not use water on metal fires—it can react violently.",
            "Babala: Huwag gumamit ng tubig sa apoy ng metal dahil maaari itong mag-react nang marahas.",
          ),
        );
      case "Class K":
        return _ClassPopupData(
          title: _tStatic(
            context,
            "Class K Fire Extinguisher",
            "Pamatay-Sunog para sa Class K",
          ),
          description: _tStatic(
            context,
            "Designed for kitchen fires involving cooking oils and fats. Common in commercial kitchens.",
            "Idinisenyo para sa apoy sa kusina na may mantika at taba. Karaniwan ito sa mga komersyal na kusina.",
          ),
          section1Title: _tStatic(
            context,
            "What is a Class K Fire?",
            "Ano ang Class K na Apoy?",
          ),
          section1Bullets: const ["Vegetable oil", "Animal fats", "Grease"],
          section2Title: _tStatic(
            context,
            "Common Extinguishing Agents",
            "Karaniwang Pampatay ng Apoy",
          ),
          section2Bullets: const [
            "Wet chemical agents that cool and form a foam layer to prevent re-ignition",
          ],
          headerGradient: const [Color(0xFF2E7D32), Color(0xFF66BB6A)],
          accent: const Color(0xFF2E7D32),
          softTint: const Color(0xFFEEFFF1),
          borderTint: const Color(0xFFD1F2D7),
          icon: Icons.restaurant_rounded,
          note: _tStatic(
            context,
            "Tip: For kitchen fires, turn off heat if safe before using an extinguisher.",
            "Paalala: Para sa apoy sa kusina, patayin ang init kung ligtas bago gumamit ng pamatay-sunog.",
          ),
        );
      default:
        return _ClassPopupData(
          title: _tStatic(context, "Fire Class", "Klase ng Apoy"),
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

String _tStatic(BuildContext context, String en, String tl) {
  return Localizations.localeOf(context).languageCode == 'tl' ? tl : en;
}
