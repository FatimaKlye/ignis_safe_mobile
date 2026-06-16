import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'localization/language_controller.dart';
import 'login.dart';
import 'module_history_page.dart';

part 'edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    this.name,
    this.completedSimulations = "0 / 5",
    this.lastSimulation = "No simulation yet",
  });

  final String? name;
  final String completedSimulations;
  final String lastSimulation;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const Color brandRed = Color(0xFFB11217);
  static const Color darkText = Color(0xFF222222);
  static const int _totalSimulations = 5;
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoadingProfile = true;
  bool _isLoggingOut = false;

  String _displayName = '';
  String _email = '';
  String? _avatarUrl;

  late String _completedSimulations;
  late String _lastSimulation;

  @override
  void initState() {
    super.initState();
    _completedSimulations = widget.completedSimulations;
    _lastSimulation = widget.lastSimulation;
    _initializePage();
  }

  Future<void> _initializePage() async {
    await _loadProfile();
  }

  String _t(BuildContext context, String en, String tl) {
    return t(context, en, tl);
  }

  Future<void> _loadProfile() async {
    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        if (!mounted) return;
        setState(() {
          _displayName = widget.name?.trim() ?? '';
          _email = '';
          _avatarUrl = null;
          _completedSimulations = widget.completedSimulations;
          _lastSimulation = widget.lastSimulation;
          _isLoadingProfile = false;
        });
        return;
      }

      final profileData = await _supabase
          .from('profiles')
          .select('''
            first_name,
            last_name,
            email,
            avatar_url,
            completed_simulations,
            last_simulation
          ''')
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;

      String displayName = widget.name?.trim() ?? '';
      String email = user.email ?? '';
      String? avatarUrl;
      String completedSimulations = widget.completedSimulations;
      String lastSimulation = widget.lastSimulation;

      if (profileData != null) {
        final firstName = (profileData['first_name'] ?? '').toString().trim();
        final lastName = (profileData['last_name'] ?? '').toString().trim();
        final fullName = '$firstName $lastName'.trim();

        if (fullName.isNotEmpty) {
          displayName = fullName;
        }

        final dbEmail = (profileData['email'] ?? '').toString().trim();
        if (dbEmail.isNotEmpty) {
          email = dbEmail;
        }

        final dbAvatarUrl = profileData['avatar_url']?.toString().trim();
        if (dbAvatarUrl != null && dbAvatarUrl.isNotEmpty) {
          avatarUrl = dbAvatarUrl;
        }

        final rawCompleted = profileData['completed_simulations'];
        if (rawCompleted != null) {
          if (rawCompleted is num) {
            completedSimulations =
                '${rawCompleted.toInt()} / $_totalSimulations';
          } else {
            final rawText = rawCompleted.toString().trim();
            if (rawText.isNotEmpty) {
              if (rawText.contains('/')) {
                completedSimulations = rawText;
              } else {
                final parsed = int.tryParse(rawText);
                if (parsed != null) {
                  completedSimulations = '$parsed / $_totalSimulations';
                }
              }
            }
          }
        }

        final dbLastSimulation = (profileData['last_simulation'] ?? '')
            .toString()
            .trim();
        if (dbLastSimulation.isNotEmpty) {
          lastSimulation = dbLastSimulation;
        }
      }

      setState(() {
        _displayName = displayName;
        _email = email;
        _avatarUrl = avatarUrl;
        _completedSimulations = completedSimulations;
        _lastSimulation = lastSimulation;
        _isLoadingProfile = false;
      });
    } catch (e) {
      final user = _supabase.auth.currentUser;

      if (!mounted) return;
      setState(() {
        _displayName = widget.name?.trim() ?? '';
        _email = user?.email ?? '';
        _avatarUrl = null;
        _completedSimulations = widget.completedSimulations;
        _lastSimulation = widget.lastSimulation;
        _isLoadingProfile = false;
      });
    }
  }

  Future<void> _logout() async {
    if (_isLoggingOut) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await _supabase.auth.signOut();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoggingOut = false;
      });

      _showDialogBox(
        title: _t(context, "Logout Failed", "Hindi Makapag-logout"),
        message: _t(
          context,
          "Something went wrong while logging out. Please try again.",
          "May problema sa pag-log out. Pakisubukang muli.",
        ),
      );
    }
  }

  void _showFAQ() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final size = MediaQuery.of(dialogContext).size;

        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            _t(context, "FAQ", "Mga Madalas Itanong"),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: size.width - 40,
              maxHeight: size.height * 0.68,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
              Text(
                _t(
                  context,
                  "1. What does IGNIS SAFE do?",
                  "1. Ano ang ginagawa ng IGNIS SAFE?",
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              SizedBox(height: 6),
              Text(
                _t(
                  context,
                  "IGNIS SAFE helps users learn fire safety through learning materials, assessments, and interactive fire scenario simulations. It is designed to improve awareness, preparedness, and proper response during fire emergencies.",
                  "Tinutulungan ng IGNIS SAFE ang mga gumagamit na matuto tungkol sa kaligtasan sa sunog sa pamamagitan ng mga materyales sa pagkatuto, pagsusulit, at interaktibong simulation ng sitwasyon ng sunog. Layunin nitong mapabuti ang kamalayan, paghahanda, at tamang pagtugon sa mga emerhensiyang sunog.",
                ),
                style: const TextStyle(
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 16),
              Text(
                _t(
                  context,
                  "2. Why do we need to learn fire scenarios?",
                  "2. Bakit kailangan nating pag-aralan ang mga sitwasyon ng sunog?",
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              SizedBox(height: 6),
              Text(
                _t(
                  context,
                  "Learning fire scenarios helps people understand what to do in real emergency situations. It builds correct decision-making, reduces panic, and teaches safe actions that can help protect lives and property.",
                  "Ang pag-aaral ng mga sitwasyon ng sunog ay tumutulong sa mga tao na malaman ang dapat gawin sa totoong emerhensiya. Pinahuhusay nito ang tamang pagpapasya, binabawasan ang panic, at nagtuturo ng ligtas na mga kilos na makatutulong protektahan ang buhay at ari-arian.",
                ),
                style: const TextStyle(
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 16),
              Text(
                _t(
                  context,
                  "3. What is the purpose of this app?",
                  "3. Ano ang layunin ng app na ito?",
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              SizedBox(height: 6),
              Text(
                _t(
                  context,
                  "The purpose of this app is to provide an engaging and practical way to learn fire safety. It combines education and simulation so users can gain knowledge and apply it in realistic fire emergency situations.",
                  "Layunin ng app na ito na magbigay ng kaakit-akit at praktikal na paraan para matuto ng kaligtasan sa sunog. Pinagsasama nito ang edukasyon at simulation upang makakuha ng kaalaman ang mga gumagamit at mailapat ito sa makatotohanang sitwasyon ng emerhensiyang sunog.",
                ),
                style: const TextStyle(
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: brandRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "OK",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDialogBox({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final size = MediaQuery.of(dialogContext).size;

        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: size.width - 40,
              maxHeight: size.height * 0.55,
            ),
            child: SingleChildScrollView(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: brandRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "OK",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  ImageProvider? _getAvatarImage() {
    if (_avatarUrl != null && _avatarUrl!.trim().isNotEmpty) {
      if (_avatarUrl!.startsWith('http')) {
        return NetworkImage(_avatarUrl!);
      }
      return AssetImage(_avatarUrl!);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final avatarImage = _getAvatarImage();
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/bg.png', fit: BoxFit.cover),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: topPadding + 200,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFB11217),
                    Color(0xFFB11217),
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.65, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = constraints.maxHeight;
                final compactWidth = width < 370;
                final compactHeight = height < 660;
                final horizontalPadding = compactWidth ? 16.0 : 25.0;
                final verticalPadding = compactHeight ? 8.0 : 14.0;
                final topGap = compactHeight ? 8.0 : 20.0;
                final titleGap = compactHeight ? 18.0 : 30.0;
                final listGap = compactHeight ? 16.0 : 24.0;
                final avatarRadius = compactWidth ? 20.0 : 22.0;
                final titleSize = (width * 0.075).clamp(20.0, 30.0).toDouble();
                final avatarSize = (width * 0.48).clamp(140.0, 180.0).toDouble();

                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: topGap),
                      Row(
                        children: [
                          PopupMenuButton<String>(
                            tooltip: '',
                            offset: const Offset(0, 55),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            onSelected: (value) async {
                              if (value == 'profile') {
                                return;
                              }
                              if (value == 'logout') {
                                await _logout();
                                return;
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'profile',
                                child: Row(
                                  children: [
                                    const Icon(Icons.person_outline_rounded),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        _t(context, 'Profile', 'Profile'),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'logout',
                                child: Row(
                                  children: [
                                    const Icon(Icons.logout_rounded),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        _t(context, 'Log Out', 'Mag-logout'),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            child: CircleAvatar(
                              radius: avatarRadius,
                              backgroundColor: Colors.grey.shade400,
                              backgroundImage: avatarImage,
                              child: avatarImage == null
                                  ? const Icon(
                                      Icons.person,
                                      size: 22,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _displayName.trim().isEmpty
                                      ? _t(context, 'Hi!', 'Kumusta!')
                                      : _t(
                                          context,
                                          'Hi, ${_displayName.trim()}',
                                          'Kumusta, ${_displayName.trim()}',
                                        ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _t(
                                    context,
                                    'Welcome to Ignis Safe',
                                    'Mabuhay, Ignis Safe',
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: titleGap),
                      Center(
                        child: Text(
                          _t(context, 'Profile', 'Profile'),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: titleSize,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.12,
                          ),
                        ),
                      ),
                      SizedBox(height: listGap),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.zero,
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 520),
                              child: Column(
                                children: [
                                  const SizedBox(height: 10),
                                  Container(
                                    width: avatarSize,
                                    height: avatarSize,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.grey.shade200,
                                      image: avatarImage != null
                                          ? DecorationImage(
                                              image: avatarImage,
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 18,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: avatarImage == null
                                        ? Icon(
                                            Icons.person,
                                            size: avatarSize * 0.39,
                                            color: Colors.grey.shade500,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(height: 18),
                                  _isLoadingProfile
                                      ? const CircularProgressIndicator()
                                      : Column(
                                          children: [
                                            Text(
                                              _displayName.isEmpty
                                                  ? '—'
                                                  : _displayName,
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.w900,
                                                color: darkText,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              _email.isEmpty ? '—' : _email,
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                  const SizedBox(height: 22),
                                  _InfoTile(
                                    icon: Icons.check_box_outlined,
                                    text:
                                        "${_t(context, "Completed Modules", "Natapos na Module")}: $_completedSimulations",
                                  ),
                                  const SizedBox(height: 12),
                                  _InfoTile(
                                    icon: Icons.local_fire_department_outlined,
                                    text:
                                        "${_t(context, "Last Simulation", "Huling Simulation")}: $_lastSimulation",
                                  ),
                                  const SizedBox(height: 26),
                                  _BigButton(
                                    icon: Icons.edit,
                                    label: _t(
                                      context,
                                      "Edit Profile",
                                      "I-edit ang Profile",
                                    ),
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const EditProfilePage(),
                                        ),
                                      );

                                      if (mounted) {
                                        setState(() {
                                          _isLoadingProfile = true;
                                        });
                                        await _loadProfile();
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  _BigButton(
                                    icon: Icons.history,
                                    label: _t(
                                      context,
                                      "Module History",
                                      "Kasaysayan ng Modyul",
                                    ),
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const ModuleHistoryPage(),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  // _LanguageSelector(
                                  //   selected: _language,
                                  //   onChanged: _changeLanguage,
                                  // ),
                                  // const SizedBox(height: 14),
                                  _BigButton(
                                    icon: Icons.help_outline,
                                    label: _t(
                                      context,
                                      "FAQ",
                                      "Mga Madalas Itanong",
                                    ),
                                    onTap: _showFAQ,
                                  ),
                                  const SizedBox(height: 14),
                                  _BigButton(
                                    icon: Icons.logout_rounded,
                                    label: _isLoggingOut
                                        ? _t(
                                            context,
                                            "Logging Out...",
                                            "Nagla-log out...",
                                          )
                                        : _t(context, "Log Out", "Mag Log Out"),
                                    onTap: _isLoggingOut ? null : _logout,
                                    color: brandRed,
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              softWrap: true,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  const _BigButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final btnColor = color ?? Colors.black;

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              Icon(icon, color: btnColor),
              const SizedBox(width: 12),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: btnColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.language),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "Language",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ),
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: DropdownButton<String>(
                value: selected,
                underline: const SizedBox(),
                isExpanded: false,
                items: const [
                  DropdownMenuItem(value: "English", child: Text("English")),
                  DropdownMenuItem(value: "Tagalog", child: Text("Tagalog")),
                ],
                onChanged: (value) {
                  if (value != null) {
                    onChanged(value);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
