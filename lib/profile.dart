import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'editprofile.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    this.name = "Andrei Quias",
    this.email = "AndreiQuias@gmail.com",
    this.completedSimulations = "2 / 3",
    this.lastSimulation = "Kitchen Fire Safety",
  });

  final String name;
  final String email;
  final String completedSimulations;
  final String lastSimulation;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const Color brandRed = Color(0xFFB11217);
  static const Color darkText = Color(0xFF222222);
  static const String _kLangKey = "ignis_lang";

  final ImagePicker _picker = ImagePicker();
  File? _avatarFile;

  String _language = "English";

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _language = prefs.getString(_kLangKey) ?? "English";
    });
  }

  Future<void> _changeLanguage(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLangKey, value);

    setState(() => _language = value);

    _showDialogBox(
      title: value == "English" ? "Language Updated" : "Na-update ang Wika",
      message: value == "English"
          ? "System language set to English."
          : "Ang system language ay Tagalog na.",
    );
  }

  Future<void> _pickAvatar() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;

    setState(() {
      _avatarFile = File(file.path);
    });
  }

 Future<void> _logout() async {
  await Supabase.instance.client.auth.signOut();
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
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600, height: 1.4),
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
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEnglish = _language == "English";

    return Scaffold(
      backgroundColor: Colors.white,
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
                // ================= HEADER =================
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back,
                            color: Colors.white),
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

                // ================= BODY =================
                Expanded(
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 25),
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
                              image: _avatarFile != null
                                  ? DecorationImage(
                                      image:
                                          FileImage(_avatarFile!),
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
                            child: _avatarFile == null
                                ? Icon(Icons.person,
                                    size: 70,
                                    color:
                                        Colors.grey.shade500)
                                : null,
                          ),
                        ),

                        const SizedBox(height: 18),

                        Text(
                          widget.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: darkText,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          widget.email,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color:
                                Colors.grey.shade600,
                          ),
                        ),

                        const SizedBox(height: 22),

                        _InfoTile(
                          icon: Icons.check_box_outlined,
                          text:
                              "${isEnglish ? "Completed Simulations" : "Natapos na Simulation"}: ${widget.completedSimulations}",
                        ),

                        const SizedBox(height: 12),

                        _InfoTile(
                          icon: Icons.local_fire_department_outlined,
                          text:
                              "${isEnglish ? "Last Simulation" : "Huling Simulation"}: ${widget.lastSimulation}",
                        ),

                        const SizedBox(height: 26),

                        _BigButton(
                          icon: Icons.edit,
                          label: isEnglish
                              ? "Edit Profile"
                              : "I-edit ang Profile",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const EditProfilePage(),
                              ),
                            );
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
                          label: isEnglish
                              ? "Log Out"
                              : "Mag Log Out",
                          onTap: _logout,
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

// ================= WIDGETS =================

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
          horizontal: 14, vertical: 14),
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
  final VoidCallback onTap;
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
          padding:
              const EdgeInsets.symmetric(horizontal: 18),
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
      padding:
          const EdgeInsets.symmetric(horizontal: 18),
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
                  child: Text("English")),
              DropdownMenuItem(
                  value: "Tagalog",
                  child: Text("Tagalog")),
            ],
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ],
      ),
    );
  }
}