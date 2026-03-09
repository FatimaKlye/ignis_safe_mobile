import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'editprofile.dart';
import 'login.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    this.name,
    this.completedSimulations = "0 / 3",
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
  static const String _kLangKey = "ignis_lang";
  static const int _totalSimulations = 3;

  final ImagePicker _picker = ImagePicker();
  final SupabaseClient _supabase = Supabase.instance.client;

  Uint8List? _avatarBytes;
  bool _isUploadingAvatar = false;
  bool _isLoadingProfile = true;
  bool _isLoggingOut = false;

  String _language = "English";
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
    await Future.wait([
      _loadLanguage(),
      _loadProfile(),
    ]);
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
            completedSimulations = '${rawCompleted.toInt()} / $_totalSimulations';
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

        final dbLastSimulation =
            (profileData['last_simulation'] ?? '').toString().trim();
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

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;

      setState(() {
        _language = prefs.getString(_kLangKey) ?? "English";
      });
    } catch (_) {}
  }

  Future<void> _changeLanguage(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLangKey, value);

    if (!mounted) return;

    setState(() {
      _language = value;
    });

    _showDialogBox(
      title: value == "English" ? "Language Updated" : "Na-update ang Wika",
      message: value == "English"
          ? "System language set to English."
          : "Ang system language ay Tagalog na.",
    );
  }

  Future<void> _pickAvatar() async {
    if (_isUploadingAvatar) return;

    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) return;

      final user = _supabase.auth.currentUser;

      if (user == null) {
        if (!mounted) return;
        _showDialogBox(
          title: "Error",
          message: "No active user session.",
        );
        return;
      }

      final bytes = await image.readAsBytes();

      const bucketName = 'profile_pic';
      final ext = image.name.contains('.')
          ? image.name.split('.').last.toLowerCase()
          : 'jpg';
      final filePath = '${user.id}/avatar.$ext';

      if (!mounted) return;

      setState(() {
        _avatarBytes = bytes;
        _isUploadingAvatar = true;
      });

      await _supabase.storage.from(bucketName).uploadBinary(
        filePath,
        bytes,
        fileOptions: FileOptions(
          upsert: true,
          contentType: _getContentType(ext),
        ),
      );

      final rawUrl = _supabase.storage.from(bucketName).getPublicUrl(filePath);
      final avatarUrl = '$rawUrl?v=${DateTime.now().millisecondsSinceEpoch}';

      await _supabase.from('profiles').update({
        'avatar_url': avatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      if (!mounted) return;

      setState(() {
        _avatarUrl = avatarUrl;
        _avatarBytes = null;
        _isUploadingAvatar = false;
      });
    } catch (e) {
      debugPrint('PROFILE IMAGE ERROR: $e');

      if (!mounted) return;

      setState(() {
        _isUploadingAvatar = false;
      });

      _showDialogBox(
        title: "Error",
        message: "Could not upload profile image.\n$e",
      );
    }
  }

  String _getContentType(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
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
        title: _language == "English" ? "Logout Failed" : "Hindi Makapag-logout",
        message: _language == "English"
            ? "Something went wrong while logging out. Please try again."
            : "May problema sa pag-log out. Pakisubukang muli.",
      );
    }
  }

  void _showFAQ() {
    final isEnglish = _language == "English";

    final text = isEnglish
        ? "• Edit Profile → Update your information.\n\n"
            "• Change Password → Inside Edit Profile.\n\n"
            "• Simulations → Complete Pre → Simulation → Post."
        : "• I-edit ang Profile → I-update ang impormasyon.\n\n"
            "• Palitan ang Password → Sa loob ng Edit Profile.\n\n"
            "• Simulation → Pre → Simulation → Post.";

    _showDialogBox(title: "FAQ", message: text);
  }

  void _showDialogBox({
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            height: 1.4,
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
      ),
    );
  }

  ImageProvider? _getAvatarImage() {
    if (_avatarBytes != null) {
      return MemoryImage(_avatarBytes!);
    }

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
    final isEnglish = _language == "English";
    final avatarImage = _getAvatarImage();

    return Scaffold(
      backgroundColor: Colors.transparent,
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
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pushReplacementNamed(
                          context,
                          '/home',
                        ),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        "Profile",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: _pickAvatar,
                          child: Container(
                            width: 180,
                            height: 180,
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
                                    size: 70,
                                    color: Colors.grey.shade500,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _isLoadingProfile
                            ? const CircularProgressIndicator()
                            : Column(
                                children: [
                                  Text(
                                    _displayName.isEmpty ? '—' : _displayName,
                                    textAlign: TextAlign.center,
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
                              "${isEnglish ? "Completed Simulations" : "Natapos na Simulation"}: $_completedSimulations",
                        ),
                        const SizedBox(height: 12),
                        _InfoTile(
                          icon: Icons.local_fire_department_outlined,
                          text:
                              "${isEnglish ? "Last Simulation" : "Huling Simulation"}: $_lastSimulation",
                        ),
                        const SizedBox(height: 26),
                        _BigButton(
                          icon: Icons.edit,
                          label: isEnglish ? "Edit Profile" : "I-edit ang Profile",
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
                        _LanguageSelector(
                          selected: _language,
                          onChanged: _changeLanguage,
                        ),
                        const SizedBox(height: 14),
                        _BigButton(
                          icon: Icons.help_outline,
                          label: "FAQ",
                          onTap: _showFAQ,
                        ),
                        const SizedBox(height: 14),
                        _BigButton(
                          icon: Icons.logout_rounded,
                          label: _isLoggingOut
                              ? (isEnglish ? "Logging Out..." : "Nagla-log out...")
                              : (isEnglish ? "Log Out" : "Mag Log Out"),
                          onTap: _isLoggingOut ? null : _logout,
                          color: brandRed,
                        ),
                        const SizedBox(height: 30),
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

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
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
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
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
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: btnColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector({
    required this.selected,
    required this.onChanged,
  });

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
          const Text(
            "Language",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          DropdownButton<String>(
            value: selected,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(
                value: "English",
                child: Text("English"),
              ),
              DropdownMenuItem(
                value: "Tagalog",
                child: Text("Tagalog"),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                onChanged(value);
              }
            },
          ),
        ],
      ),
    );
  }
}