import 'package:flutter/material.dart';
import 'pre_assess_instruction.dart';

class LearningMaterialElectricalPage extends StatefulWidget {
  const LearningMaterialElectricalPage({super.key});

  @override
  State<LearningMaterialElectricalPage> createState() =>
      _LearningMaterialElectricalPageState();
}

class _LearningMaterialElectricalPageState
    extends State<LearningMaterialElectricalPage> {
  static const accent = Color(0xFF2563EB); // primary blue
  static const accent2 = Color(0xFF2563EB);

  final PageController _pageCtrl = PageController();
  final ScrollController _scrollCtrl = ScrollController();

  int _pageIndex = 0;

  double _progress = 0.0; // 0.0 -> 1.0 (per page scroll)
  bool _canNext = false;

  String _t(BuildContext context, String en, String tl) {
    return Localizations.localeOf(context).languageCode == 'tl' ? tl : en;
  }

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
    if (!_canNext && _pageIndex < 2) return;

    if (_pageIndex < 2) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PreAssessmentIntroPage2()),
      );
    }
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
                const SizedBox(height: 5),

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

                      Center(
                        child: Text(
                          _t(context, "Learning Material", "Materyal sa Pag-aaral"),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                        ), // adjust 12/16/20/24
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: accent,
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
                                    _t(context, "MODULE 3", "MODYUL 3"),
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
                                _t(
                                  context,
                                  "Electrical Fire: Causes, Safe Actions, and Prevention",
                                  "Sunog sa Kuryente: Sanhi, Ligtas na Aksyon, at Pag-iwas",
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

                      // ===== PROGRESS BAR (small, fixed, on top) =====
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

                // ===== PAGE VIEW (scroll per page, progress unlock) =====
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

                // ===== BOTTOM NAV (fixed) =====
                Padding(
                  padding: const EdgeInsets.fromLTRB(25, 8, 25, 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF2563EB)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        onPressed: _goBack,
                        child: Text(
                          _t(context, "« BACK", "« BALIK"),
                          style: TextStyle(
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        onPressed: (_canNext || isLast) ? _goNext : null,
                        child: Text(
                          isLast
                              ? _t(context, "Start pre test", "Simulan ang paunang pagsusulit")
                              : _t(context, "NEXT »", "SUNOD »"),
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
          const SizedBox(height: 70), // prevents content hiding under buttons
        ],
      ),
    );
  }

  // ===================== PAGE 1 =====================
  Widget _page1OverviewAndTypes() {
    return _ModernCard(
      accent1: accent,
      accent2: accent2,
      pageTitle: _t(
        context,
        "PAGE 1 – ELECTRICAL FIRE OVERVIEW",
        "PAHINA 1 – PANGKALAHATANG TINGIN SA SUNOG SA KURYENTE",
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              _t(context, "What is an Electrical Fire?", "Ano ang Sunog sa Kuryente?"),
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
                asset: "assets/electrical.png",
                c1: accent,
                c2: accent2,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  _t(
                    context,
                    "An electrical fire is a fire caused by electrical equipment, wiring, or devices that overheat, spark, or short circuit. These fires often start behind walls, inside appliances, or in electrical panels, making them difficult to detect early.",
                    "Ang sunog sa kuryente ay sunog na sanhi ng electrical na kagamitan, wiring, o device na sumobra ang init, nagpapahinga ng spark, o nagkaroon ng short circuit. Ang mga sunog na ito ay madalas magsimula sa likod ng mga pader, sa loob ng mga appliance, o sa electrical panel, kaya mahirap itong mapansin agad.",
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _Callout(
            icon: Icons.warning_rounded,
            color: Color(0xFFDC2626),
            title: _t(context, "Why electrical fires are dangerous", "Bakit mapanganib ang sunog sa kuryente"),
            lines: [
              _t(context, "They can spread inside walls.", "Maaari itong kumalat sa loob ng mga pader."),
              _t(context, "They may reignite if power is not disconnected.", "Maaari itong muling magliyab kung hindi mapuputol ang kuryente."),
              _t(context, "Water cannot be used to extinguish them.", "Hindi maaaring gamitan ng tubig para apulahin ito."),
            ],
          ),

          const SizedBox(height: 14),

          _ChipLine(
            icon: Icons.class_rounded,
            color: Color(0xFF1E3A8A),
            text: _t(
              context,
              "Electrical fires are classified as Class C fires in standard fire classifications.",
              "Ang sunog sa kuryente ay kabilang sa Class C sa karaniwang pag-uuri ng sunog.",
            ),
          ),

          const SizedBox(height: 24),

          _SectionTitle(_t(context, "Types of Electrical Fire", "Mga Uri ng Sunog sa Kuryente")),
          const SizedBox(height: 12),

          _MiniTile(
            color: Color(0xFF2563EB),
            icon: Icons.flash_on_rounded,
            title: _t(context, "Short Circuit Fire", "Sunog dahil sa Short Circuit"),
            desc: _t(
              context,
              "Occurs when live wires touch due to damaged insulation, creating sparks and intense heat.",
              "Nangyayari kapag nagdikit ang live wires dahil sa sirang insulation, na nagdudulot ng spark at matinding init.",
            ),
          ),
          const SizedBox(height: 10),
          _MiniTile(
            color: Color(0xFF1D4ED8),
            icon: Icons.power_rounded,
            title: _t(context, "Overloaded Circuit Fire", "Sunog dahil sa Overloaded Circuit"),
            desc: _t(
              context,
              "Happens when too many devices are connected to one outlet or extension cord, causing overheating.",
              "Nangyayari kapag masyadong maraming device ang nakakabit sa iisang saksakan o extension cord kaya umiinit nang husto.",
            ),
          ),
          const SizedBox(height: 10),
          _MiniTile(
            color: Color(0xFFF59E0B),
            icon: Icons.electrical_services_rounded,
            title: _t(context, "Faulty Appliance Fire", "Sunog dahil sa Sirang Appliance"),
            desc: _t(
              context,
              "Caused by defective internal wiring inside appliances such as electric fans, heaters, or chargers.",
              "Dulot ng sirang internal wiring ng appliance tulad ng electric fan, heater, o charger.",
            ),
          ),
          const SizedBox(height: 10),
          _MiniTile(
            color: Color(0xFFEA580C),
            icon: Icons.cable_rounded,
            title: _t(context, "Loose Wiring Fire", "Sunog dahil sa Maluwag na Wiring"),
            desc: _t(
              context,
              "Loose electrical connections generate heat due to resistance and may ignite nearby materials.",
              "Ang maluwag na koneksyon sa kuryente ay lumilikha ng init dahil sa resistance at maaaring magsindi ng katabing materyales.",
            ),
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
      pageTitle: _t(
        context,
        "PAGE 2 – CAUSES OF ELECTRICAL FIRE",
        "PAHINA 2 – MGA SANHI NG SUNOG SA KURYENTE",
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              _t(context, "Common Causes of Electrical Fires", "Karaniwang Sanhi ng Sunog sa Kuryente"),
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
              _IconBox(
                icon: Icons.inventory_2_rounded,
                c1: accent2,
                c2: accent,
              ),
              SizedBox(width: 15),
              Expanded(
                child: _Bullets(
                  items: [
                    _t(context, "Overloaded power strips and outlets", "Sobrang daming nakakabit sa power strip at saksakan"),
                    _t(context, "Old or damaged wiring", "Luma o sirang wiring"),
                    _t(context, "Using substandard extension cords", "Paggamit ng substandard na extension cord"),
                    _t(context, "Poor electrical installation", "Maling electrical installation"),
                    _t(context, "Leaving appliances plugged in for long periods", "Pag-iiwang nakasaksak ang appliances nang matagal"),
                    _t(context, "Improper use of electrical equipment", "Maling paggamit ng electrical equipment"),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          _ChipLine(
            icon: Icons.fact_check_rounded,
            color: Color(0xFFF59E0B),
            text: _t(
              context,
              "Regular inspection and proper usage significantly reduce risk.",
              "Ang regular na inspeksyon at tamang paggamit ay malaking nakakabawas sa panganib.",
            ),
          ),

          const SizedBox(height: 26),

          _SectionTitle(_t(context, "How to Prevent Electrical Fires", "Paano Maiiwasan ang Sunog sa Kuryente")),
          const SizedBox(height: 12),

          _Bullets(
            items: [
              _t(context, "Do not overload outlets or extension cords.", "Huwag sobrahan ang nakakabit sa saksakan o extension cord."),
              _t(context, "Replace damaged cords immediately.", "Palitan agad ang mga sirang kable."),
              _t(context, "Avoid running cords under carpets.", "Iwasang ilagay ang kable sa ilalim ng carpet."),
              _t(context, "Use certified and standard electrical devices.", "Gumamit ng sertipikado at standard na electrical devices."),
              _t(context, "Turn off and unplug appliances when not in use.", "Patayin at tanggalin sa saksakan ang appliances kapag hindi gamit."),
              _t(context, "Have licensed electricians check faulty wiring.", "Magpasuri ng sirang wiring sa lisensyadong electrician."),
            ],
          ),

          const SizedBox(height: 14),

          _Callout(
            icon: Icons.shield_rounded,
            color: Color(0xFF2563EB),
            title: _t(context, "Prevention", "Pag-iwas"),
            lines: [
              _t(context, "Prevention reduces ignition sources and electrical overheating.", "Ang pag-iwas ay nakababawas sa pinagmumulan ng sindi at sobrang init sa kuryente."),
            ],
          ),
        ],
      ),
    );
  }

  // ===================== PAGE 3 =====================
  Widget _page3EmergencyResponse() {
    return _ModernCard(
      accent1: Color(0xFF1D4ED8),
      accent2: accent,
      pageTitle: _t(
        context,
        "PAGE 3 – WHAT TO DO DURING AN ELECTRICAL FIRE",
        "PAHINA 3 – ANO ANG GAGAWIN KAPAG MAY SUNOG SA KURYENTE",
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              _t(context, "Emergency Response for Electrical Fire", "Pagtugon sa Emerhensiya sa Sunog sa Kuryente"),
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
              _IconBox(
                icon: Icons.fire_extinguisher_rounded,
                c1: Color(0xFF2563EB),
                c2: Color(0xFFF59E0B),
              ),
              SizedBox(width: 15),
              Expanded(
                child: _Bullets(
                  items: [
                    _t(context, "Do NOT use water.", "HUWAG gumamit ng tubig."),
                    _t(context, "Turn off the power supply if it is safe to do so.", "Patayin ang power supply kung ligtas gawin."),
                    _t(context, "Use a Class C or ABC fire extinguisher.", "Gumamit ng Class C o ABC fire extinguisher."),
                    _t(context, "Evacuate immediately if the fire spreads.", "Lumikas agad kung kumakalat ang apoy."),
                    _t(context, "Call emergency services.", "Tumawag sa emergency services."),
                    _t(context, "Never touch burning electrical equipment directly.", "Huwag direktang hawakan ang nasusunog na electrical equipment."),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          _Callout(
            icon: Icons.block_rounded,
            color: Color(0xFFDC2626),
            title: _t(context, "Remember", "Tandaan"),
            lines: [
              _t(context, "If you cannot safely disconnect power, evacuate and call for help.", "Kung hindi ligtas putulin ang kuryente, lumikas at tumawag ng tulong."),
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
              color: accent1,
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
        color: c1.withOpacity(0.12),
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
        color: c1.withOpacity(0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Center(
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: c1,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: c1.withOpacity(0.28),
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
