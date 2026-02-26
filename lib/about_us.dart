import 'package:flutter/material.dart';

enum AboutFilter { all, about, team, bfpDasmarinas , contacts }

class AboutUsPage extends StatefulWidget {
  const AboutUsPage({super.key});

  @override
  State<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends State<AboutUsPage> {
  static const Color brandRed = Color(0xFFB11217);

  // navbar
  int _currentIndex = 2; // set to your About index in navbar

  // search + filter
  String _searchQuery = '';
  AboutFilter _filter = AboutFilter.all;

  void _onSearchChanged(String v) => setState(() => _searchQuery = v);

  void _openFilterMenu(BuildContext context) async {
    final selected = await showMenu<AboutFilter>(
      context: context,
      position: const RelativeRect.fromLTRB(9999, 120, 16, 0), // right-side-ish
      items: const [
        PopupMenuItem(value: AboutFilter.all, child: Text("All")),
        PopupMenuItem(value: AboutFilter.about, child: Text("About")),
        PopupMenuItem(value: AboutFilter.team, child: Text("Team")),
        PopupMenuItem(value: AboutFilter.bfpDasmarinas, child: Text("BFP Dasmariñas")),
        PopupMenuItem(value: AboutFilter.contacts, child: Text("Contacts")),
      ],
    );

    if (selected != null && mounted) {
      setState(() => _filter = selected);
    }
  }

  bool _matchesFilter(_AboutSection s) {
    switch (_filter) {
      case AboutFilter.all:
        return true;
      case AboutFilter.about:
        return s.type == _AboutSectionType.about;
      case AboutFilter.team:
        return s.type == _AboutSectionType.team;
      case AboutFilter.bfpDasmarinas:
        return s.type == _AboutSectionType.partner;
      case AboutFilter.contacts:
        return s.type == _AboutSectionType.contact;
    }
  }

  bool _matchesSearch(_AboutSection s, String q) {
    if (q.isEmpty) return true;
    final hay = ('${s.title} ${s.searchText}'.toLowerCase());
    return hay.contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final q = _searchQuery.trim().toLowerCase();

    final sections = _buildSections();
    final visible = sections
        .where((s) => _matchesFilter(s) && _matchesSearch(s, q))
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // background image (same approach as your modules)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 900,
            child: Image.asset('assets/bg.png', fit: BoxFit.cover),
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 25, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // header (kept from your code)
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 22,
                            backgroundImage: AssetImage("assets/avatar.png"),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                "Hi, Andrei Quias",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Welcome to Ignis Safe",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),
                      const Center(
                        child: Text(
                          "About Us",
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF222222),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Search with filter icon INSIDE right side (kept)
                      Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: Colors.grey),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                onChanged: _onSearchChanged,
                                decoration: const InputDecoration(
                                  hintText: "Search",
                                  hintStyle: TextStyle(color: Colors.grey),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: "Filter",
                              onPressed: () => _openFilterMenu(context),
                              icon: Icon(
                                Icons.filter_list_rounded,
                                color: _filter == AboutFilter.all
                                    ? const Color(0xFF9E9E9E)
                                    : brandRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(25, 8, 25, 110),
                    child: Column(
                      children: [
                        if (visible.isEmpty)
                          _EmptyState(
                            onClear: () => setState(() {
                              _searchQuery = '';
                              _filter = AboutFilter.all;
                            }),
                          )
                        else
                          ...visible.map((s) => Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: s.builder(context),
                              )),
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

  List<_AboutSection> _buildSections() {
    return [
      _AboutSection(
        type: _AboutSectionType.about,
        title: "IGNIS SAFE",
        searchText: "Ignis Safe interactive 3D fire safety simulation mission",
        builder: (context) => const _ModernAboutCard(),
      ),
      _AboutSection(
        type: _AboutSectionType.about,
        title: "Logo Meaning",
        searchText:
            "logo shield fire truck hose flame water spray ignis latin fire safe protected secure mission prevention preparedness",
        builder: (context) => const _LogoMeaningCard(),
      ),
      _AboutSection(
        type: _AboutSectionType.team,
        title: "Meet the Developers",
        // ✅ include full names + email for search
        searchText:
            "Fatima Klye M Sierra fatimaklyesierra081005@gmail.com Andrei C Quias Rave Paulo Sierra Sarah Flor Macandile Maricis Punzalan Adviser",
        builder: (context) => const _TeamCard(),
      ),
      _AboutSection(
        type: _AboutSectionType.partner,
        title: "BFP R4A Dasmariñas City Fire Station",
        searchText: "Bureau of Fire Protection Philippines fire safety education",
        builder: (context) => const _PartnerCard(),
      ),
      _AboutSection(
        type: _AboutSectionType.contact,
        title: "Emergency Contact Information",
        searchText: "hotline emergency 046 884 6131 416 0875 0995 336 9534",
        builder: (context) => const _ContactCard(),
      ),
      _AboutSection(
        type: _AboutSectionType.contact,
        title: "Cavite BFP Directory",
        searchText:
            "Office of the Provincial Fire Director Cavite City Kawit Noveleta Rosario Bacoor Imus Dasmarinas Carmona GMA Silang General Trias Amadeo Indang Tanza Trece Martires Alfonso Aguinaldo Magallanes Maragondon Mendez Naic Tagaytay Ternate",
        builder: (context) => _CaviteBfpDirectoryCard(query: _searchQuery),
      ),
    ];
  }
}

// ─────────────────────────────────────────────────────────────
// Sections + UI blocks
// ─────────────────────────────────────────────────────────────

enum _AboutSectionType { about, team, partner, contact }

class _AboutSection {
  final _AboutSectionType type;
  final String title;
  final String searchText;
  final Widget Function(BuildContext) builder;

  _AboutSection({
    required this.type,
    required this.title,
    required this.searchText,
    required this.builder,
  });
}


class _ModernAboutCard extends StatelessWidget {
  static const Color brandRed = Color(0xFFB11217);

  const _ModernAboutCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [brandRed, Color(0xFFE65A5F)],
                    ),
                  ),
                  child: const Icon(Icons.local_fire_department_rounded,
                      color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "IGNIS SAFE",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              "An interactive 3D fire safety simulation that helps users learn proper prevention and emergency response through realistic, hands-on scenarios in a controlled environment.",
              style: TextStyle(
                height: 1.35,
                fontSize: 13.5,
                color: Color(0xFF3A3A3A),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                _Chip(text: "3D Scenarios", icon: Icons.view_in_ar_rounded),
                _Chip(text: "Hands-on Practice", icon: Icons.touch_app_rounded),
                _Chip(text: "Safe Learning", icon: Icons.verified_rounded),
                _Chip(text: "Fire Awareness", icon: Icons.school_rounded),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEDEDED)),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: const [
                  Icon(Icons.flag_rounded, color: brandRed),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Goal: Improve readiness through correct decision-making and proper extinguisher handling.",
                      style: TextStyle(
                        fontSize: 12.8,
                        height: 1.25,
                        color: Color(0xFF2D2D2D),
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
    );
  }
}
class _LogoMeaningCard extends StatelessWidget {
  static const Color brandRed = Color(0xFFB11217);

  const _LogoMeaningCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top: logo left + paragraph right
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F3F3),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFEDEDED)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      "assets/ignis_logo.png", // ✅ change this
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.shield_rounded,
                        size: 46,
                        color: brandRed,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    "The IGNIS SAFE logo is built around a shield, symbolizing protection and safety. "
                    "The fire truck and hose show readiness to respond quickly during emergencies. "
                    "The flame represents fire risk, while the water spray represents control and prevention.",
                    textAlign: TextAlign.justify,
                    style: TextStyle(
                      fontSize: 12.8,
                      height: 1.35,
                      color: Color(0xFF2D2D2D),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            const Center(
              child: Text(
                "IGNIS SAFE",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E1E1E),
                  letterSpacing: 0.6,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Ignis / Safe blocks
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _MeaningMiniBlock(
                    title: "Ignis",
                    body: "is a Latin word meaning fire.",
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _MeaningMiniBlock(
                    title: "Safe",
                    body: "means protected or secure.",
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            const Text(
              "Together, Ignis Safe means protection from fire or fire safety. "
              "It reflects a mission focused on preventing fire risks, ensuring preparedness, "
              "and keeping people and property safe from fire-related hazards.",
              textAlign: TextAlign.justify,
              style: TextStyle(
                fontSize: 12.8,
                height: 1.35,
                color: Color(0xFF2D2D2D),
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              "Ignis Safe focuses on fire safety, prevention, and emergency preparedness.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.8,
                height: 1.35,
                color: Color(0xFF1E1E1E),
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "It provides fire safety education, training, and awareness programs to help individuals and organizations "
              "understand fire risks and how to respond properly during emergencies. It also supports inspection, compliance, "
              "and safety reporting to strengthen overall fire protection systems.",
              textAlign: TextAlign.justify,
              style: TextStyle(
                fontSize: 12.8,
                height: 1.35,
                color: Color(0xFF2D2D2D),
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF1D5D6)),
              ),
              child: const Text(
                "In essence, Ignis Safe helps prevent fires, prepare people for emergencies, and protect lives and property.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.8,
                  height: 1.35,
                  color: Color(0xFF1E1E1E),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeaningMiniBlock extends StatelessWidget {
  final String title;
  final String body;
  const _MeaningMiniBlock({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDEDED)),
      ),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12.8,
            height: 1.25,
            color: Color(0xFF2D2D2D),
          ),
          children: [
            TextSpan(
              text: "$title ",
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            TextSpan(
              text: body,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  const _TeamCard();

  @override
  Widget build(BuildContext context) {
    // ✅ UPDATED DATA + dialog content (name/role/email/bio)
    final team = const [
      _TeamMember(
        fullName: "FATIMA KLYE M. SIERRA",
        displayFirst: "FATIMA",
        displayLast: "SIERRA",
        role: "MOBILE DEVELOPER",
        email: "fatimaklyesierra081005@gmail.com",
        bio:
            "Manages mobile application & databases and supports project coordination. She also serves as an Assistant Project Manager, helping ensure timelines and deliverables are met efficiently.",
        asset: "assets/dev_fatima.png",
      ),
      _TeamMember(
        fullName: "ANDREI C. QUIAS",
        displayFirst: "ANDREI",
        displayLast: "QUIAS",
        role: "3D UNITY DEVELOPER",
        email: "",
        bio:
            "Builds interactive and immersive applications. He also serves as a Project Manager, overseeing planning, coordination, and timely delivery of projects.",
        asset: "assets/dev_andrei.png",
      ),
      _TeamMember(
        fullName: "RAVE PAULO SIERRA",
        displayFirst: "RAVE",
        displayLast: "SIERRA",
        role: "WEBSITE DEVELOPER",
        email: "",
        bio:
            "Responsible for designing, building, and maintaining responsive and functional websites, ensuring performance, usability, and a seamless user experience.",
        asset: "assets/dev_rave.png",
      ),
      _TeamMember(
        fullName: "SARAH FLOR MACANDILE",
        displayFirst: "SARAH",
        displayLast: "MACANDILE",
        role: "DOCUMENTATION",
        email: "",
        bio:
            "Ensures that all project records, reports, and required materials are accurate, organized, and properly maintained to support compliance and operational efficiency.",
        asset: "assets/dev_sarah.png",
      ),
      _TeamMember(
        fullName: "MARICIS PUNZALAN",
        displayFirst: "MARICIS",
        displayLast: "PUNZALAN",
        role: "ADVISER",
        email: "",
        bio:
            "Provides strategic guidance, oversight, and expert recommendations to support informed decision-making and overall project direction.",
        asset: "assets/dev_maricis.png",
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "MEET OUR DEVELOPERS",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFFB11217),
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 146, // ✅ prevents overflow with 2-line name
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: team.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) => _DevTile(m: team[i]),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Tip: Tap any profile (optional) to open a short bio dialog.",
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF666666),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PartnerCard extends StatelessWidget {
  const _PartnerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "BFP R4A Dasmariñas City Fire Station",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E1E1E),
              ),
            ),
            SizedBox(height: 8),
            Text(
              "An official fire service unit operating under the Bureau of Fire Protection (BFP) in the Philippines. The BFP is a national government agency tasked with preventing and suppressing destructive fires, enforcing the Fire Code, and conducting community fire safety education nationwide.",
              style: TextStyle(
                height: 1.35,
                fontSize: 13.2,
                color: Color(0xFF3A3A3A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  static const Color brandRed = Color(0xFFB11217);

  const _ContactCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF5F5), Colors.white],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.phone_in_talk_rounded, color: brandRed),
                SizedBox(width: 10),
                Text(
                  "Emergency Contact Information",
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              "In case of fire or other emergencies, the public may call the station’s hotlines:",
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF3A3A3A),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            _ContactRow(
              icon: Icons.local_phone_rounded,
              label: "Landline",
              value: "(046) 884-6131 / 416-0875",
              onTap: () {}, // keep handler, you can wire later
            ),
            const SizedBox(height: 8),
            _ContactRow(
              icon: Icons.smartphone_rounded,
              label: "Mobile",
              value: "0995-336-9534",
              onTap: () {}, // keep handler, you can wire later
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEDEDED)),
              ),
              child: const Text(
                "If you are in immediate danger, prioritize evacuation and follow local emergency procedures.",
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.25,
                  color: Color(0xFF2D2D2D),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFB11217)),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  height: 1.25,
                  color: Color(0xFF2D2D2D),
                ),
                children: [
                  TextSpan(
                    text: "$label: ",
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DevTile extends StatelessWidget {
  final _TeamMember m;
  const _DevTile({required this.m});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Text(
              m.fullName,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.role,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFB11217),
                  ),
                ),
                if (m.email.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    "EMAIL: ${m.email}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                m.bio,
                textAlign: TextAlign.justify,   // ✅ this makes it justified
                style: const TextStyle(
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          ),
        );
      },
      child: Container(
        width: 112,
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF0F0F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xFFF2F2F2),
              backgroundImage: AssetImage(m.asset),
              onBackgroundImageError: (_, __) {},
            ),
            const SizedBox(height: 8),
            Text(
              m.displayFirst,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E1E1E),
                height: 1.05,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              m.displayLast,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E1E1E),
                height: 1.05,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              m.role,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B6B6B),
                height: 1.05,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamMember {
  final String fullName;
  final String displayFirst;
  final String displayLast;
  final String role;
  final String email;
  final String bio;
  final String asset;

  const _TeamMember({
    required this.fullName,
    required this.displayFirst,
    required this.displayLast,
    required this.role,
    required this.email,
    required this.bio,
    required this.asset,
  });
}

class _Chip extends StatelessWidget {
  final String text;
  final IconData icon;

  const _Chip({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFEDEDED)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFFB11217)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D2D2D),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onClear;
  const _EmptyState({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded, size: 44, color: Colors.grey),
          const SizedBox(height: 10),
          const Text(
            "No results found.",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Try a different keyword or reset filters.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.25,
              color: Color(0xFF6B6B6B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: onClear,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB11217),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Reset",
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _CaviteBfpDirectoryCard extends StatelessWidget {
  final String query;
  const _CaviteBfpDirectoryCard({required this.query});

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();

    // Filter groups and entries by query (name/email/contact + group title)
    final filteredGroups = _caviteBfpGroups
        .map((g) {
          final entries = g.entries.where((e) {
            if (q.isEmpty) return true;
            final hay = [
              e.name,
              e.email,
              ...e.contacts,
            ].join(' ').toLowerCase();
            return hay.contains(q);
          }).toList();

          return _DirectoryGroup(title: g.title, entries: entries);
        })
        .where((g) {
          if (q.isEmpty) return true;
          final groupMatch = g.title.toLowerCase().contains(q);
          return groupMatch || g.entries.isNotEmpty;
        })
        .toList();

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF5F5), Colors.white],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.apartment_rounded, color: Color(0xFFB11217)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Cavite BFP Directory",
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              "Search by station name, district, email, or number. Tap to call/email.",
              style: TextStyle(
                fontSize: 12.5,
                height: 1.25,
                color: Color(0xFF5E5E5E),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            if (filteredGroups.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9F9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEFEFEF)),
                ),
                child: const Text(
                  "No matching results in Cavite BFP Directory.",
                  style: TextStyle(
                    fontSize: 12.8,
                    height: 1.25,
                    color: Color(0xFF2D2D2D),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              ...filteredGroups.map(
                (g) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _DistrictAccordion(
                    group: g,
                    initiallyExpanded: q.isNotEmpty, // auto-open on search
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DistrictAccordion extends StatelessWidget {
  final _DirectoryGroup group;
  final bool initiallyExpanded;
  const _DistrictAccordion({
    required this.group,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEDED)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          collapsedIconColor: const Color(0xFFB11217),
          iconColor: const Color(0xFFB11217),
          title: Text(
            group.title,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2B2B2B),
            ),
          ),
          children: group.entries
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: _DirectoryEntryTile(entry: e),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _DirectoryEntryTile extends StatelessWidget {
  final _DirectoryEntry entry;
  const _DirectoryEntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEFEFEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 10),

          // Email (tappable)
          InkWell(
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.email_rounded,
                      size: 18, color: Color(0xFFB11217)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.email,
                      style: const TextStyle(
                        fontSize: 12.8,
                        height: 1.25,
                        color: Color(0xFF2D2D2D),
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Phones (tappable chips)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: entry.contacts
                .map(
                  (c) => InkWell(
                    borderRadius: BorderRadius.circular(999),    
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFE6E6E6)),
                      ),
                      child: Text(
                        c,
                        style: const TextStyle(
                          fontSize: 12.2,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2D2D2D),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}



// ─────────────────────────────────────────────────────────────
// Directory data models + data
// ─────────────────────────────────────────────────────────────

class _DirectoryGroup {
  final String title;
  final List<_DirectoryEntry> entries;
  const _DirectoryGroup({required this.title, required this.entries});
}

class _DirectoryEntry {
  final String name;
  final String email;
  final List<String> contacts;
  const _DirectoryEntry({
    required this.name,
    required this.email,
    required this.contacts,
  });
}

const List<_DirectoryGroup> _caviteBfpGroups = [
  _DirectoryGroup(
    title: "Office of the Provincial Fire Director",
    entries: [
      _DirectoryEntry(
        name: "Provincial Fire Director – Cavite",
        email: "cavitebfp@yahoo.com",
        contacts: ["046-471-3747", "0943-386-8772", "0967-805-5581"],
      ),
    ],
  ),
  _DirectoryGroup(
    title: "First District",
    entries: [
      _DirectoryEntry(
        name: "Cavite City",
        email: "admn.cavcityfs@gmail.com",
        contacts: ["(046) 484-2899", "0966-694-1416"],
      ),
      _DirectoryEntry(
        name: "Kawit",
        email: "admn.bfpkawit@yahoo.com.ph",
        contacts: ["(046) 484-5250", "0966-132-0605"],
      ),
      _DirectoryEntry(
        name: "Noveleta",
        email: "noveletafirestation@gmail.com",
        contacts: ["(046) 438-5684", "0917-547-3696"],
      ),
      _DirectoryEntry(
        name: "Rosario",
        email: "admn.rosario.fire214@yahoo.com",
        contacts: ["(046) 438-1616", "0939-232-6045"],
      ),
    ],
  ),
  _DirectoryGroup(
    title: "Second District",
    entries: [
      _DirectoryEntry(
        name: "Bacoor City",
        email: "bfpbacoor@yahoo.com",
        contacts: ["(046) 417-6060", "0966-695-9711"],
      ),
    ],
  ),
  _DirectoryGroup(
    title: "Third District",
    entries: [
      _DirectoryEntry(
        name: "Imus City",
        email: "imuscfs@gmail.com",
        contacts: ["(046) 970-5161", "0966-705-9174"],
      ),
    ],
  ),
  _DirectoryGroup(
    title: "Fourth District",
    entries: [
      _DirectoryEntry(
        name: "Dasmariñas City",
        email: "dasmafscavite@gmail.com",
        contacts: ["416-0875", "424-2537", "0995-336-9534"],
      ),
    ],
  ),
  _DirectoryGroup(
    title: "Fifth District",
    entries: [
      _DirectoryEntry(
        name: "Carmona",
        email: "carmonafirestation@gmail.com",
        contacts: ["(046) 430-1666", "0915-602-1572"],
      ),
      _DirectoryEntry(
        name: "General Mariano Alvarez (GMA)",
        email: "gma.fire@yahoo.com",
        contacts: ["(046) 443-9110", "0938-781-9294", "0955-790-3765"],
      ),
      _DirectoryEntry(
        name: "Silang",
        email: "silangfirestation@yahoo.com",
        contacts: ["(046) 414-0484", "0915-602-1593"],
      ),
    ],
  ),
  _DirectoryGroup(
    title: "Sixth District",
    entries: [
      _DirectoryEntry(
        name: "General Trias City",
        email: "gen3bfp210.admn@gmail.com",
        contacts: ["(046) 437-7625", "0917-593-1522"],
      ),
    ],
  ),
  _DirectoryGroup(
    title: "Seventh District",
    entries: [
      _DirectoryEntry(
        name: "Amadeo",
        email: "amadeobfp@gmail.com",
        contacts: ["(046) 483-2490", "0915-601-6805"],
      ),
      _DirectoryEntry(
        name: "Indang",
        email: "indang_bfp@yahoo.com",
        contacts: ["(046) 415-1217", "0915-603-4245", "0933-824-5948"],
      ),
      _DirectoryEntry(
        name: "Tanza",
        email: "tanzafs@gmail.com",
        contacts: ["(046) 505-6084"],
      ),
      _DirectoryEntry(
        name: "Trece Martires City",
        email: "charliebase13@gmail.com",
        contacts: ["(046) 419-0057", "0918-425-7897"],
      ),
    ],
  ),
  _DirectoryGroup(
    title: "Eighth District",
    entries: [
      _DirectoryEntry(
        name: "Alfonso",
        email: "alfonsocavitefs@gmail.com",
        contacts: ["(046) 522-0480", "0915-602-2113"],
      ),
      _DirectoryEntry(
        name: "General Emilio Aguinaldo",
        email: "aguinaldo.firestation@gmail.com",
        contacts: ["0921-458-593", "0966-256-7730"],
      ),
      _DirectoryEntry(
        name: "Magallanes",
        email: "magallanes_firestation@yahoo.com",
        contacts: ["(046) 529-6245", "0915-602-1644"],
      ),
      _DirectoryEntry(
        name: "Maragondon",
        email: "maragondon219@gmail.com",
        contacts: ["(046) 412-1911", "0966-375-3790"],
      ),
      _DirectoryEntry(
        name: "Mendez",
        email: "mendez_firestation@yahoo.com",
        contacts: ["(046) 413-2237", "0977-200-1102"],
      ),
      _DirectoryEntry(
        name: "Naic",
        email: "bfpnaic.official@yahoo.com",
        contacts: ["(046) 412-1481", "0917-679-7861"],
      ),
      _DirectoryEntry(
        name: "Tagaytay City",
        email: "tagaytayfire@gmail.com",
        contacts: ["(046) 483-1193", "0942-989-8495"],
      ),
      _DirectoryEntry(
        name: "Ternate",
        email: "maragondon219@gmail.com",
        contacts: ["(046) 419-1911", "0966-375-9790"],
      ),
    ],
  ),
];