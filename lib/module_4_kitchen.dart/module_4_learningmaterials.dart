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
  bool _isSwitchingPage = false;
  bool _lastPageCompleted = false;

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
    setState(() {
      _isSwitchingPage = true;
      _progress = 0.0;
      _canNext = false;
      _lastPageCompleted = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scrollCtrl.hasClients) _scrollCtrl.jumpTo(0);
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
            child: Text(_t(context, "OK", "Sige")),
          ),
        ],
      ),
    );
  }

  void _showDoThisNowPopup() {
    _showInfoPopup(
      title: _t(context, "If a pan catches fire", "Kapag nagliyab ang kawali"),
      icon: Icons.local_fire_department_rounded,
      color: const Color(0xFFDC2626),
      message: _t(
        context,
        "1) Turn off the heat.\n"
            "2) Cover the pan with a metal lid or baking tray.\n"
            "3) Do NOT carry the pan.\n"
            "4) Do NOT use water on burning oil.\n"
            "5) If it grows, evacuate and call for help.",
        "1) Patayin ang apoy o kalan.\n"
            "2) Takpan ang kawali gamit ang metal na takip o tray.\n"
            "3) HUWAG buhatin ang kawali.\n"
            "4) HUWAG lagyan ng tubig ang nagliliyab na mantika.\n"
            "5) Kung lumalaki, lumikas at tumawag ng tulong.",
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
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  _t(context, "MODULE 4", "MODYUL 4"),
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
                                "Kitchen Fire: What It Is, Common Types, and What To Do",
                                "Sunog sa Kusina: Ano Ito, Karaniwang Uri, at Ano ang Dapat Gawin",
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
                        child: Text(
                          _t(context, "« BACK", "« BALIK"),
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
                        onPressed: (isLast ? _lastPageCompleted : _canNext) ? _goNext : null,
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
      pageTitle: _t(
        context,
        "PAGE 1 – KITCHEN FIRE OVERVIEW",
        "PAHINA 1 – PANGKALAHATANG TINGIN SA SUNOG SA KUSINA",
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              _t(context, "What is a Kitchen Fire?", "Ano ang Sunog sa Kusina?"),
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
                asset: "assets/kitchen.png",
                c1: accent,
                c2: accent2,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  _t(
                    context,
                    "A kitchen fire starts in the cooking area. It often happens when food, oil, or appliances overheat. Most kitchen fires spread fast because heat and grease build up quickly.",
                    "Ang sunog sa kusina ay nagsisimula sa lugar ng pagluluto. Madalas itong nangyayari kapag sobrang uminit ang pagkain, mantika, o kagamitan. Mabilis kumalat ang karamihan ng sunog sa kusina dahil mabilis maipon ang init at sebo.",
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

          const SizedBox(height: 14),

          _Callout(
            icon: Icons.warning_rounded,
            color: const Color(0xFFDC2626),
            title: _t(context, "Common danger", "Karaniwang panganib"),
            lines: [
              _t(context, "Grease can ignite suddenly.", "Maaaring biglang magliyab ang sebo o mantika."),
              _t(context, "Smoke can block vision fast.", "Mabilis mahahadlangan ng usok ang iyong paningin."),
              _t(context, "Wrong action (like water on oil) can make it worse.", "Ang maling aksyon (tulad ng tubig sa mantika) ay maaaring magpalala ng sunog."),
            ],
          ),

          const SizedBox(height: 14),

          _ChipLine(
            icon: Icons.menu_book_rounded,
            color: const Color(0xFFF59E0B),
            text: _t(context, "Tap the buttons below for quick pop-ups.", "Pindutin ang mga button sa ibaba para sa mabilis na impormasyon."),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _ActionPill(
                  icon: Icons.help_rounded,
                  label: _t(context, "Why it happens", "Bakit ito nangyayari"),
                  onTap: () => _showInfoPopup(
                    title: _t(context, "Why kitchen fires happen", "Bakit nagkakaroon ng sunog sa kusina"),
                    message: _t(
                      context,
                      "Usually from unattended cooking, overheated oil, grease buildup, or flammable items near heat.",
                      "Karaniwang dulot ng napabayaang pagluluto, sobrang init na mantika, naipong sebo, o madaling masunog na bagay malapit sa init.",
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionPill(
                  icon: Icons.local_fire_department_rounded,
                  label: _t(context, "If pan ignites", "Kapag nagliyab ang kawali"),
                  onTap: _showDoThisNowPopup,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          _SectionTitle(_t(context, "Types of Kitchen Fires", "Mga Uri ng Sunog sa Kusina")),
          const SizedBox(height: 12),

          _MiniTile(
            color: Color(0xFFF59E0B),
            icon: Icons.oil_barrel_rounded,
            title: _t(context, "Grease Fire", "Sunog sa Mantika"),
            desc: _t(context, "Cooking oil or fat overheats and ignites (fast and intense).", "Sobrang umiinit ang mantika o taba at nagliliyab (mabilis at matindi)."),
          ),
          const SizedBox(height: 10),
          _MiniTile(
            color: Color(0xFFF59E0B),
            icon: Icons.local_pizza_rounded,
            title: _t(context, "Oven Fire", "Sunog sa Hurno"),
            desc: _t(context, "Food spills or grease buildup burns inside the oven.", "Ang tapon na pagkain o naipong sebo ay nasusunog sa loob ng oven."),
          ),
          const SizedBox(height: 10),
          _MiniTile(
            color: Color(0xFFFB923C),
            icon: Icons.microwave_rounded,
            title: _t(context, "Microwave Fire", "Sunog sa Microwave"),
            desc: _t(context, "Metal or overheated food ignites and causes flames/smoke.", "Ang metal o sobrang init na pagkain ay maaaring magliyab at magdulot ng apoy/usok."),
          ),
          const SizedBox(height: 10),
          _MiniTile(
            color: Color(0xFFEA580C),
            icon: Icons.local_gas_station_rounded,
            title: _t(context, "Gas Stove Fire", "Sunog sa Gas na Kalan"),
            desc: _t(context, "Flame flare-ups or leaking gas ignites near the stove.", "Biglaang paglaki ng apoy o tumatagas na gas ang nagiging sanhi ng sindi malapit sa kalan."),
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
        "PAGE 2 – CAUSES & PREVENTION",
        "PAHINA 2 – MGA SANHI AT PAG-IWAS",
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              _t(context, "Common Causes of Kitchen Fires", "Karaniwang Sanhi ng Sunog sa Kusina"),
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
                icon: Icons.kitchen_rounded,
                c1: accent2,
                c2: accent,
              ),
              SizedBox(width: 15),
              Expanded(
                child: _Bullets(
                  items: [
                    _t(context, "Leaving cooking unattended", "Napapabayaang pagluluto"),
                    _t(context, "Oil overheating while frying", "Sobrang pag-init ng mantika habang nagpiprito"),
                    _t(context, "Grease buildup on stove/hood", "Naipong sebo sa stove o hood"),
                    _t(context, "Towels or paper near flames", "Tuwalya o papel na malapit sa apoy"),
                    _t(context, "Cooking while tired or distracted", "Pagluluto habang pagod o hindi nakatutok"),
                    _t(context, "Wrong use of appliances (dirty toaster, etc.)", "Maling paggamit ng appliances (maruming toaster, atbp.)"),
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
                  label: _t(context, "Quick check", "Mabilisang pagsusuri"),
                  onTap: () => _showInfoPopup(
                    title: _t(context, "Quick Check", "Mabilisang Pagsusuri"),
                    icon: Icons.check_circle_rounded,
                    color: const Color(0xFFF59E0B),
                    message:
                        _t(context, "If you leave the kitchen for even 1 minute while frying, risk increases a lot. Stay nearby and keep heat controlled.", "Kung iiwan mo ang kusina kahit 1 minuto habang nagpiprito, malaki ang pagtaas ng panganib. Manatili sa malapit at kontrolin ang init."),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionPill(
                  icon: Icons.tips_and_updates_rounded,
                  label: _t(context, "Safety tips", "Mga tip sa kaligtasan"),
                  onTap: () => _showInfoPopup(
                    title: _t(context, "Safety Tips", "Mga Tip sa Kaligtasan"),
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

          _ChipLine(
            icon: Icons.fact_check_rounded,
            color: Color(0xFFF59E0B),
            text: _t(context, "Small habits prevent most kitchen fires.", "Ang simpleng tamang gawi ay nakaiiwas sa karamihan ng sunog sa kusina."),
          ),

          const SizedBox(height: 24),

          _SectionTitle(_t(context, "Prevention (Simple Steps)", "Pag-iwas (Simpleng Hakbang)")),
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
              Expanded(
                child: _Bullets(
                  items: [
                    _t(context, "Keep a lid near the pan when cooking.", "Maghanda ng takip malapit sa kawali habang nagluluto."),
                    _t(context, "Clean grease from stove and hood.", "Linisin ang sebo sa stove at hood."),
                    _t(context, "Keep flammables away from heat.", "Ilayo ang madaling masunog na bagay sa init."),
                    _t(context, "Turn handles inward.", "Iharap paloob ang hawakan ng kawali."),
                    _t(context, "Use the right heat level (don’t overheat oil).", "Gamitin ang tamang antas ng init (huwag paabutin sa sobrang init ang mantika)."),
                    _t(context, "Know your extinguisher location.", "Alamin kung saan nakalagay ang pamatay-sunog."),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          _Callout(
            icon: Icons.shield_rounded,
            color: Color(0xFFF59E0B),
            title: _t(context, "Prevention goal", "Layunin ng pag-iwas"),
            lines: [
              _t(context, "Reduce heat, reduce grease buildup, and keep flammable items away.", "Bawasan ang init, bawasan ang naipong sebo, at ilayo ang madaling masunog na bagay."),
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
      pageTitle: _t(
        context,
        "PAGE 3 – WHAT TO DO DURING A KITCHEN FIRE",
        "PAHINA 3 – ANO ANG GAGAWIN KAPAG MAY SUNOG SA KUSINA",
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              _t(context, "Emergency Response", "Pagtugon sa Emerhensiya"),
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
                c1: Color(0xFFEA580C),
                c2: Color(0xFFF59E0B),
              ),
              SizedBox(width: 15),
              Expanded(
                child: _Bullets(
                  items: [
                    _t(context, "Turn off heat source if safe.", "Patayin ang pinagmumulan ng init kung ligtas."),
                    _t(context, "Cover small pan fire with a metal lid/tray.", "Takpan ang maliit na apoy sa kawali gamit ang metal na takip/tray."),
                    _t(context, "Do NOT use water on burning oil/grease.", "HUWAG gumamit ng tubig sa nagliliyab na mantika/sebo."),
                    _t(context, "Use a fire extinguisher if trained and safe.", "Gumamit ng pamatay-sunog kung sanay at ligtas."),
                    _t(context, "If it spreads: evacuate and call emergency services.", "Kung kumalat ang apoy: lumikas at tumawag sa serbisyong pang-emergency."),
                    _t(context, "Close doors behind you to slow the fire.", "Isara ang pinto sa likod mo upang bumagal ang pagkalat ng apoy."),
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
                  label: _t(context, "Grease fire rule", "Patakaran sa sunog ng mantika"),
                  onTap: () => _showInfoPopup(
                    title: _t(context, "Grease Fire Rule", "Patakaran sa Sunog ng Mantika"),
                    icon: Icons.block_rounded,
                    color: const Color(0xFFDC2626),
                    message:
                        _t(context, "Never pour water on burning oil. Water can spread burning grease and cause flare-ups.", "Huwag kailanman magbuhos ng tubig sa nagliliyab na mantika. Maaaring kumalat ang apoy at lumala."),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionPill(
                  icon: Icons.help_center_rounded,
                  label: _t(context, "When to evacuate", "Kailan dapat lumikas"),
                  onTap: () => _showInfoPopup(
                    title: _t(context, "Evacuate when…", "Lumikas kapag…"),
                    icon: Icons.directions_run_rounded,
                    color: const Color(0xFFDC2626),
                    message:
                        _t(context, "Evacuate immediately if flames grow, smoke fills the room, or you can’t control it quickly. Call for help.", "Lumikas agad kung lumalaki ang apoy, napupuno ng usok ang silid, o hindi mo ito makontrol agad. Tumawag ng tulong."),
                  ),
                ),
              ),
            ],
          ),

            const SizedBox(height: 18),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: _ImageBox(
                    asset: "assets/response_kitchen.png",
                    c1: const Color(0xFFEA580C),
                    c2: accent,
                  ),
                ),
                const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(_t(context, "One-minute plan", "Isang minutong plano")),
                    const SizedBox(height: 10),
                    _Bullets(
                      items: [
                        _t(context, "Stop the heat.", "Patayin ang init."),
                        _t(context, "Smother small flames.", "Takpan ang maliit na apoy."),
                        _t(context, "Use extinguisher only if safe.", "Gumamit ng pamatay-sunog kung ligtas."),
                        _t(context, "Get out if unsure.", "Lumabas kung hindi sigurado."),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _ActionPill(
                      icon: Icons.play_circle_rounded,
                      label: _t(context, "Show steps", "Ipakita ang mga hakbang"),
                      onTap: _showDoThisNowPopup,
                    ),
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
              _t(context, "Your safety is the priority. If you feel unsafe, evacuate and call for help.", "Kaligtasan mo ang prayoridad. Kung delikado na, lumikas at tumawag ng tulong."),
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