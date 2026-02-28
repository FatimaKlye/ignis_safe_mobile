import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({
    super.key,
    this.initialFirstName = "Andrei",
    this.initialLastName = "Quias",
    this.initialUsername = "AndreiQuias",
    this.initialEmail = "AndreiQuias@gmail.com",
  });

  final String initialFirstName;
  final String initialLastName;
  final String initialUsername;
  final String initialEmail;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  static const Color brandRed = Color(0xFFB11217);

  final _picker = ImagePicker();
  File? _avatarFile;
  bool _avatarChanged = false;

  late final TextEditingController _firstNameCtrl =
      TextEditingController(text: widget.initialFirstName);
  late final TextEditingController _lastNameCtrl =
      TextEditingController(text: widget.initialLastName);
  late final TextEditingController _usernameCtrl =
      TextEditingController(text: widget.initialUsername);

  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();

  bool _showPass = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final xfile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (xfile == null) return;
    setState(() {
      _avatarFile = File(xfile.path);
      _avatarChanged = true;
    });
  }
List<String> _computeChanges() {
    final changes = <String>[];

    final first = _firstNameCtrl.text.trim();
    final last = _lastNameCtrl.text.trim();
    final user = _usernameCtrl.text.trim();

    if (first != widget.initialFirstName) {
      changes.add("First Name: \u201c${widget.initialFirstName}\u201d \u2192 \u201c$first\u201d");
    }
    if (last != widget.initialLastName) {
      changes.add("Last Name: \u201c${widget.initialLastName}\u201d \u2192 \u201c$last\u201d");
    }
    if (user != widget.initialUsername) {
      changes.add("Username: \u201c${widget.initialUsername}\u201d \u2192 \u201c$user\u201d");
    }
    if (_avatarChanged) {
      changes.add("Profile Photo: Updated");
    }

    final pass = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;
    if (pass.isNotEmpty || confirm.isNotEmpty) {
      changes.add("Password: Updated");
    }

    return changes;
  }

  bool _validateInputs() {
    final first = _firstNameCtrl.text.trim();
    final last = _lastNameCtrl.text.trim();
    final user = _usernameCtrl.text.trim();

    if (first.isEmpty || last.isEmpty || user.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all required fields.")),
      );
      return false;
    }

    final pass = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;
    if (pass.isNotEmpty || confirm.isNotEmpty) {
      if (pass.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password must be at least 6 characters.")),
        );
        return false;
      }
      if (pass != confirm) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Passwords do not match.")),
        );
        return false;
      }
    }

    return true;
  }

  Future<void> _onSavePressed() async {
    if (!_validateInputs()) return;

    final changes = _computeChanges();
    if (changes.isEmpty) {
      await _showInfoDialog(
        title: "No changes detected",
        message: "Nothing to update.",
        buttonText: "OK",
      );
      return;
    }

    // 1) Show “What changed” popup with Update button
    final wantsUpdate = await _showChangesDialog(changes);
    if (wantsUpdate != true) return;

    // 2) Are you sure?
    final sure = await _showConfirmDialog(
      title: "Confirm Update",
      message: "Are you sure you want to update these changes?",
      confirmText: "Yes, Update",
      cancelText: "No",
    );
    if (sure != true) return;

    // 3) Perform update here (Supabase etc.)
    // TODO: hook your update logic here.
    // Example:
    // await updateProfile();
    // await updatePasswordIfNeeded();
    // await uploadAvatarIfChanged();

    // 4) Success popup
    await _showInfoDialog(
      title: "Updated",
      message: "Changed successfully.",
      buttonText: "OK",
    );

    if (mounted) Navigator.pop(context);
  }

  Future<bool?> _showChangesDialog(List<String> changes) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Changes Detected",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black.withOpacity(0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: changes
                        .map((c) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                "• $c",
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  height: 1.25,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.black.withOpacity(0.18)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text(
                          "Back",
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandRed,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 6,
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          "Update",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    required String cancelText,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          content: Text(
            message,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                cancelText,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: brandRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                confirmText,
                style: const TextStyle(
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

  Future<void> _showInfoDialog({
    required String title,
    required String message,
    required String buttonText,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          content: Text(
            message,
            style: const TextStyle(fontWeight: FontWeight.w600),
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
              child: Text(
                buttonText,
                style: const TextStyle(
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

  @override
  Widget build(BuildContext context) {
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 14),
              child: Column(
                children: [
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const Spacer(),
                      const Text(
                        "Edit Profile",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 60),
                    ],
                  ),
                  const SizedBox(height: 35),

                  GestureDetector(
                    onTap: _pickAvatar,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.shade200,
                            image: _avatarFile != null
                                ? DecorationImage(
                                    image: FileImage(_avatarFile!),
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
                                  size: 64, color: Colors.grey.shade500)
                              : null,
                        ),
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: brandRed,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.18),
                                blurRadius: 10,
                                offset: const Offset(0, 6),
                              )
                            ],
                          ),
                          child: const Icon(Icons.camera_alt,
                              color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black.withOpacity(0.08)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.10),
                          blurRadius: 16,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _Field(
                          label: "First Name",
                          controller: _firstNameCtrl,
                          icon: Icons.badge_outlined,
                        ),
                        const SizedBox(height: 12),
                        _Field(
                          label: "Last Name",
                          controller: _lastNameCtrl,
                          icon: Icons.badge_outlined,
                        ),
                        const SizedBox(height: 12),
                        _Field(
                          label: "Username",
                          controller: _usernameCtrl,
                          icon: Icons.alternate_email,
                        ),
                        const SizedBox(height: 12),

                        _Field(
                          label: "Email",
                          controller:
                              TextEditingController(text: widget.initialEmail),
                          icon: Icons.mail_outline,
                          enabled: false,
                        ),

                        const SizedBox(height: 18),

                        _PasswordField(
                          label: "New Password",
                          controller: _passwordCtrl,
                          show: _showPass,
                          onToggle: () => setState(() => _showPass = !_showPass),
                        ),
                        const SizedBox(height: 12),
                        _PasswordField(
                          label: "Confirm Password",
                          controller: _confirmCtrl,
                          show: _showConfirm,
                          onToggle: () =>
                              setState(() => _showConfirm = !_showConfirm),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandRed,
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _onSavePressed,
                      child: const Text(
                        "Save Changes",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.icon,
    this.enabled = true,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: enabled ? Colors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.10)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              decoration: InputDecoration(
                hintText: label,
                border: InputBorder.none,
                isDense: true,
              ),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: enabled ? const Color(0xFF222222) : Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.label,
    required this.controller,
    required this.show,
    required this.onToggle,
  });

  final String label;
  final TextEditingController controller;
  final bool show;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.10)),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: !show,
              decoration: InputDecoration(
                hintText: label,
                border: InputBorder.none,
                isDense: true,
              ),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF222222),
              ),
            ),
          ),
          IconButton(
            onPressed: onToggle,
            icon: Icon(
              show ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}