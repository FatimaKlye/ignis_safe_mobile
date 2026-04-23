import 'package:flutter/material.dart';
import 'pre_assess_instruction.dart';

class LearningMaterialHousePage extends StatefulWidget {
  const LearningMaterialHousePage({super.key});

  @override
  State<LearningMaterialHousePage> createState() =>
      _LearningMaterialHousePageState();
}

class _LearningMaterialHousePageState extends State<LearningMaterialHousePage> {
  static const accent = Color(0xFFF97316); // primary orange
  static const accent2 = Color(0xFFF59E0B); // warm amber

  final PageController _pageCtrl = PageController();
  final ScrollController _scrollCtrl = ScrollController();

  int _pageIndex = 0;

  double _progress = 0.0;
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
        MaterialPageRoute(
          builder: (_) => const PreAssessmentIntroPage2(),
        ),
      );
    }
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
                        padding: const EdgeInsets.only(left: 16),
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
                                  Icon(Icons.home_rounded,
                                      color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    _t(context, "MODULE 2", "MODYUL 2"),
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
                                  "House Fire: How to Get Out Safely During a Fire",
                                  "Sunog sa Bahay: Paano Makalabas nang Ligtas",
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
                            valueColor:
                                const AlwaysStoppedAnimation(accent2),
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
                      _pageWrap(_page1Overview()),
                      _pageWrap(_page2HowToEscape()),
                      _pageWrap(_page3AfterEscape()),
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
                          side: const BorderSide(color: Color(0xFFF97316)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        onPressed: _goBack,
                        child: Text(
                          _t(context, "« BACK", "« BALIK"),
                          style: TextStyle(
                            color: Color(0xFFF97316),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF97316),
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
          const SizedBox(height: 70),
        ],
      ),
    );
  }

  Widget _page1Overview() {
    return _ModernCard(
      accent1: accent,
      accent2: accent2,
      pageTitle: _t(
        context,
        "PAGE 1 – HOUSE FIRE OVERVIEW",
        "PAHINA 1 – PANGKALAHATANG TINGIN SA SUNOG SA BAHAY",
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              _t(context, "What is a House Fire?", "Ano ang Sunog sa Bahay?"),
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
                asset: "assets/house.jpg",
                c1: accent,
                c2: accent2,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  _t(
                    context,
                    "A house fire is a dangerous emergency that can spread very quickly through rooms, ceilings, and hallways. Smoke, heat, and flames can block exits in just a few minutes, so every second matters.",
                    "Ang sunog sa bahay ay mapanganib na emerhensiya na mabilis kumalat sa mga silid, kisame, at pasilyo. Ang usok, init, at apoy ay maaaring humarang sa labasan sa loob lamang ng ilang minuto.",
                  ),
                  style: TextStyle(
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
            title: _t(context, "Why house fires are dangerous", "Bakit mapanganib ang sunog sa bahay"),
            lines: [
              _t(context, "Smoke can make it hard to see and breathe.", "Maaaring pahirapan ng usok ang paningin at paghinga."),
              _t(context, "Fire spreads fast through curtains, wood, and furniture.", "Mabilis kumalat ang apoy sa kurtina, kahoy, at muwebles."),
              _t(context, "Heat can make doors and escape paths unsafe.", "Maaaring maging delikado ang mga pinto at daanan dahil sa matinding init."),
            ],
          ),
          const SizedBox(height: 14),
          _ChipLine(
            icon: Icons.access_time_rounded,
            color: Color(0xFFB11217),
            text: _t(
              context,
              "When a house is on fire, leave immediately. Do not stop to collect belongings.",
              "Kapag may sunog sa bahay, lumikas agad. Huwag nang huminto para kumuha ng gamit.",
            ),
          ),
          const SizedBox(height: 24),
          _SectionTitle(
            _t(context, "Common Signs of a House Fire", "Karaniwang Palatandaan ng Sunog sa Bahay"),
          ),
          const SizedBox(height: 12),
          _MiniTile(
            color: Color(0xFFF59E0B),
            icon: Icons.smoke_free_rounded,
            title: _t(context, "Smoke", "Usok"),
            desc: _t(
              context,
              "Thick smoke in a room or hallway is an early sign that a fire is spreading nearby.",
              "Ang makapal na usok sa silid o pasilyo ay maagang palatandaan na may kumakalat na apoy sa malapit.",
            ),
          ),
          const SizedBox(height: 10),
          _MiniTile(
            color: Color(0xFFFB923C),
            icon: Icons.campaign_rounded,
            title: _t(context, "Smoke Alarm", "Smoke Alarm"),
            desc: _t(
              context,
              "If the alarm sounds, treat it as a real emergency and begin evacuating at once.",
              "Kapag tumunog ang alarm, ituring itong tunay na emerhensiya at agad na lumikas.",
            ),
          ),
          const SizedBox(height: 10),
          _MiniTile(
            color: Color(0xFFEA580C),
            icon: Icons.local_fire_department_rounded,
            title: _t(context, "Visible Flames", "Nakikitang Apoy"),
            desc: _t(
              context,
              "Flames from appliances, curtains, walls, or ceilings mean the fire is already active and dangerous.",
              "Kapag may apoy mula sa appliances, kurtina, pader, o kisame, aktibo at mapanganib na ang sunog.",
            ),
          ),
          const SizedBox(height: 10),
          _MiniTile(
            color: Color(0xFFF97316),
            icon: Icons.whatshot_rounded,
            title: _t(context, "Hot Doors or Walls", "Mainit na Pinto o Pader"),
            desc: _t(
              context,
              "A hot door may mean fire is on the other side. Do not open it right away.",
              "Ang mainit na pinto ay maaaring senyales na may apoy sa kabilang panig. Huwag agad buksan.",
            ),
          ),
        ],
      ),
    );
  }

  Widget _page2HowToEscape() {
    return _ModernCard(
      accent1: accent2,
      accent2: accent,
      pageTitle: _t(
        context,
        "PAGE 2 – HOW TO GET OUT SAFELY",
        "PAHINA 2 – PAANO MAKALABAS NANG LIGTAS",
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              _t(context, "Steps to Escape from a House Fire", "Mga Hakbang sa Paglikas mula sa Sunog sa Bahay"),
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
                icon: Icons.directions_run_rounded,
                c1: accent2,
                c2: accent,
              ),
              SizedBox(width: 15),
              Expanded(
                child: _Bullets(
                  items: [
                    _t(context, "Stay calm and move quickly to the nearest safe exit.", "Manatiling kalmado at kumilos agad papunta sa pinakamalapit na ligtas na labasan."),
                    _t(context, "Check doors with the back of your hand before opening.", "Suriin ang pinto gamit ang likod ng kamay bago ito buksan."),
                    _t(context, "If the door is hot, do not open it. Use another way out.", "Kung mainit ang pinto, huwag itong buksan. Humanap ng ibang labasan."),
                    _t(context, "Crawl low under smoke where the air is cleaner.", "Gumapang nang mababa sa ilalim ng usok kung saan mas malinis ang hangin."),
                    _t(context, "Help children, older persons, and others who need assistance.", "Tulungan ang mga bata, nakatatanda, at iba pang nangangailangan ng tulong."),
                    _t(context, "Do not use elevators if you are in a multi-level home or building.", "Huwag gumamit ng elevator kung nasa multi-level na bahay o gusali."),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ChipLine(
            icon: Icons.health_and_safety_rounded,
            color: Color(0xFFF97316),
            text: _t(
              context,
              "Stay low, move fast, and head outside using the safest exit.",
              "Manatiling mababa, kumilos nang mabilis, at lumabas gamit ang pinakaligtas na daan.",
            ),
          ),
          const SizedBox(height: 26),
          _SectionTitle(
            _t(context, "Important Escape Reminders", "Mahahalagang Paalala sa Paglikas"),
          ),
          const SizedBox(height: 12),
          _Bullets(
            items: [
              _t(context, "Do not hide during a fire.", "Huwag magtago kapag may sunog."),
              _t(context, "Do not go back inside for phones, bags, or valuables.", "Huwag nang bumalik sa loob para sa telepono, bag, o mahahalagang gamit."),
              _t(context, "Close doors behind you if possible to slow the spread of fire.", "Isara ang pinto sa likod mo kung kaya upang bumagal ang pagkalat ng apoy."),
              _t(context, "Use windows only if doors are blocked and it is safe to do so.", "Gamitin lamang ang bintana kung barado ang pinto at ligtas itong gawin."),
              _t(context, "If your clothes catch fire: Stop, Drop, and Roll.", "Kung magliyab ang damit: Tumigil, Humiga, at Gumulong."),
              _t(context, "Once outside, keep moving away from the house.", "Kapag nasa labas na, lumayo pa sa bahay."),
            ],
          ),
          const SizedBox(height: 14),
          _Callout(
            icon: Icons.block_rounded,
            color: Color(0xFFDC2626),
            title: _t(context, "Never do this", "Huwag itong gawin"),
            lines: [
              _t(context, "Never go back into a burning house after you have escaped.", "Huwag kailanman bumalik sa nasusunog na bahay kapag nakalabas ka na."),
            ],
          ),
        ],
      ),
    );
  }

  Widget _page3AfterEscape() {
    return _ModernCard(
      accent1: Color(0xFFF59E0B),
      accent2: accent,
      pageTitle: _t(
        context,
        "PAGE 3 – AFTER YOU GET OUT",
        "PAHINA 3 – PAGKATAPOS MONG MAKALABAS",
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              _t(context, "What to Do After Escaping", "Ano ang Gagawin Pagkatapos Makalikas"),
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
                icon: Icons.support_agent_rounded,
                c1: Color(0xFFF59E0B),
                c2: Color(0xFFF97316),
              ),
              SizedBox(width: 15),
              Expanded(
                child: _Bullets(
                  items: [
                    _t(context, "Go to a safe meeting place outside the house.", "Pumunta sa ligtas na tagpuan sa labas ng bahay."),
                    _t(context, "Call emergency services immediately.", "Tumawag agad sa emergency services."),
                    _t(context, "Tell firefighters if someone may still be inside.", "Sabihin sa mga bumbero kung may maaaring naiwan pa sa loob."),
                    _t(context, "Stay outside and wait for professional help.", "Manatili sa labas at hintayin ang mga propesyonal na responder."),
                    _t(context, "Do not re-enter the house for any reason.", "Huwag nang pumasok muli sa bahay anuman ang dahilan."),
                    _t(context, "Follow instructions from firefighters or responders.", "Sundin ang utos ng mga bumbero o responder."),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Callout(
            icon: Icons.groups_rounded,
            color: Color(0xFFF97316),
            title: _t(context, "Meeting Place", "Tagpuan"),
            lines: [
              _t(context, "Choose a safe family meeting place outside, such as near a gate, tree, or neighbor’s house.", "Pumili ng ligtas na tagpuan ng pamilya sa labas, tulad ng malapit sa gate, puno, o bahay ng kapitbahay."),
            ],
          ),
          const SizedBox(height: 14),
          _Callout(
            icon: Icons.phone_in_talk_rounded,
            color: Color(0xFFEA580C),
            title: _t(context, "Call for Help", "Tumawag ng Tulong"),
            lines: [
              _t(context, "Call your local fire department or emergency hotline as soon as you are safe.", "Tumawag sa lokal na bumbero o emergency hotline sa sandaling ligtas ka na."),
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