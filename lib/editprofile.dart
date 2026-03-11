import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  static const Color brandRed = Color(0xFFB11217);
  static const Color darkText = Color(0xFF222222);

  final ImagePicker _picker = ImagePicker();

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  File? _avatarFile;
  String? _existingAvatarUrl;

  bool _avatarChanged = false;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _showPass = false;
  bool _showConfirm = false;

  String _originalFirstName = '';
  String _originalLastName = '';
  String _originalUsername = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception('No active session.');
      }

      final data = await supabase
          .from('profiles')
          .select('first_name, last_name, username, email, avatar_url')
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) {
        final metadata = user.userMetadata ?? {};

        await supabase.from('profiles').upsert({
          'id': user.id,
          'first_name': (metadata['first_name'] ?? '').toString(),
          'last_name': (metadata['last_name'] ?? '').toString(),
          'username': (metadata['username'] ?? '').toString(),
          'email': user.email ?? '',
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      final refreshed = await supabase
          .from('profiles')
          .select('first_name, last_name, username, email, avatar_url')
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;

      final firstName = (refreshed?['first_name'] ?? '').toString();
      final lastName = (refreshed?['last_name'] ?? '').toString();
      final username = (refreshed?['username'] ?? '').toString();
      final email = (refreshed?['email'] ?? user.email ?? '').toString();
      final avatarUrl = refreshed?['avatar_url']?.toString();

      setState(() {
        _firstNameCtrl.text = firstName;
        _lastNameCtrl.text = lastName;
        _usernameCtrl.text = username;
        _emailCtrl.text = email;
        _existingAvatarUrl = avatarUrl;

        _originalFirstName = firstName;
        _originalLastName = lastName;
        _originalUsername = username;

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      await _showInfoDialog(
        title: 'Failed to load profile',
        message: '$e',
        buttonText: 'OK',
      );
    }
  }

  Future<void> _pickAvatar() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (picked == null) return;

    setState(() {
      _avatarFile = File(picked.path);
      _avatarChanged = true;
    });
  }

  Future<bool> _validateInputs() async {
    final first = _firstNameCtrl.text.trim();
    final last = _lastNameCtrl.text.trim();
    // final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;

    // if (first.isEmpty || last.isEmpty || username.isEmpty) {
    if (first.isEmpty || last.isEmpty) {
      await _showInfoDialog(
        title: 'Incomplete Details',
        // message: 'Please complete First Name, Last Name, and Username.',
        message: 'Please complete First Name and Last Name.',
        buttonText: 'OK',
      );
      return false;
    }

    if (password.isNotEmpty || confirm.isNotEmpty) {
      if (password.length < 6) {
        await _showInfoDialog(
          title: 'Invalid Password',
          message: 'Password must be at least 6 characters.',
          buttonText: 'OK',
        );
        return false;
      }

      if (password != confirm) {
        await _showInfoDialog(
          title: 'Password Mismatch',
          message: 'Passwords do not match.',
          buttonText: 'OK',
        );
        return false;
      }
    }

    return true;
  }

  bool _hasActualChanges() {
    return _firstNameCtrl.text.trim() != _originalFirstName ||
        _lastNameCtrl.text.trim() != _originalLastName ||
      // _usernameCtrl.text.trim() != _originalUsername ||
        _avatarChanged ||
        _passwordCtrl.text.trim().isNotEmpty;
  }

  List<String> _computeChanges() {
    final changes = <String>[];

    final first = _firstNameCtrl.text.trim();
    final last = _lastNameCtrl.text.trim();
    // final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (first != _originalFirstName) {
      changes.add('First Name: "$_originalFirstName" → "$first"');
    }

    if (last != _originalLastName) {
      changes.add('Last Name: "$_originalLastName" → "$last"');
    }

    // if (username != _originalUsername) {
    //   changes.add('Username: "$_originalUsername" → "$username"');
    // }

    if (_avatarChanged) {
      changes.add('Profile Photo: Updated');
    }

    if (password.isNotEmpty) {
      changes.add('Password: Will be updated');
    } else {
      changes.add('Password: No change (left blank)');
    }

    return changes;
  }

  Future<void> _onSavePressed() async {
    if (_isSaving) return;
    if (!await _validateInputs()) return;

    if (!_hasActualChanges()) {
      await _showInfoDialog(
        title: 'No changes detected',
        message:
            'Nothing to update.\n\nPassword is blank, so it will remain unchanged.',
        buttonText: 'OK',
      );
      return;
    }

    final changes = _computeChanges();

    final wantsUpdate = await _showChangesDialog(changes);
    if (wantsUpdate != true) return;

    final sure = await _showConfirmDialog(
      title: 'Confirm Update',
      message: 'Are you sure you want to update these changes?',
      confirmText: 'Yes, Update',
      cancelText: 'No',
    );
    if (sure != true) return;

    setState(() => _isSaving = true);

    try {
      await _performUpdate();

      if (!mounted) return;

      await _showInfoDialog(
        title: 'Updated',
        message: 'Changed successfully.',
        buttonText: 'OK',
      );

      Navigator.pop(context, true);
    } on AuthException catch (e) {
      if (!mounted) return;
      await _showInfoDialog(
        title: 'Update Failed',
        message: e.message,
        buttonText: 'OK',
      );
    } catch (e) {
      if (!mounted) return;
      await _showInfoDialog(
        title: 'Update Failed',
        message: 'Update failed: $e',
        buttonText: 'OK',
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _performUpdate() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No active session.');
    }

    String? avatarUrl = _existingAvatarUrl;

    if (_avatarChanged && _avatarFile != null) {
      final bytes = await _avatarFile!.readAsBytes();
      final path = '${user.id}/avatar.jpg';

      await supabase.storage.from('avatars').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(
          upsert: true,
          contentType: 'image/jpeg',
        ),
      );

      final publicUrl = supabase.storage.from('avatars').getPublicUrl(path);
      avatarUrl = '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
    }

    await supabase.from('profiles').upsert({
      'id': user.id,
      'first_name': _firstNameCtrl.text.trim(),
      'last_name': _lastNameCtrl.text.trim(),
      // 'username': _usernameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'avatar_url': avatarUrl,
      'updated_at': DateTime.now().toIso8601String(),
    });

    final pass = _passwordCtrl.text.trim();
    if (pass.isNotEmpty) {
      await supabase.auth.updateUser(UserAttributes(password: pass));
      _passwordCtrl.clear();
      _confirmCtrl.clear();
    }

    if (!mounted) return;

    setState(() {
      _originalFirstName = _firstNameCtrl.text.trim();
      _originalLastName = _lastNameCtrl.text.trim();
      _originalUsername = _usernameCtrl.text.trim();
      _existingAvatarUrl = avatarUrl;
      _avatarChanged = false;
    });
  }

  Future<bool?> _showChangesDialog(List<String> changes) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Review Changes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
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
                        .map(
                          (c) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              '• $c',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                height: 1.3,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 10),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Leave the password fields blank if you want to keep your current password.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                      height: 1.3,
                    ),
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
                          'Back',
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
                          'Update',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
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
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
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

  ImageProvider? _buildAvatarImage() {
    if (_avatarFile != null) return FileImage(_avatarFile!);

    if (_existingAvatarUrl != null && _existingAvatarUrl!.isNotEmpty) {
      if (_existingAvatarUrl!.startsWith('http')) {
        return NetworkImage(_existingAvatarUrl!);
      }
      return AssetImage(_existingAvatarUrl!);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final avatarImage = _buildAvatarImage();

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
                        'Edit Profile',
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
                                  size: 64,
                                  color: Colors.grey.shade500,
                                )
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
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
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
                          label: 'First Name',
                          controller: _firstNameCtrl,
                          icon: Icons.badge_outlined,
                        ),
                        const SizedBox(height: 12),
                        _Field(
                          label: 'Last Name',
                          controller: _lastNameCtrl,
                          icon: Icons.badge_outlined,
                        ),
                        const SizedBox(height: 12),
                        // _Field(
                        //   label: 'Username',
                        //   controller: _usernameCtrl,
                        //   icon: Icons.alternate_email,
                        // ),
                        // const SizedBox(height: 12),
                        _Field(
                          label: 'Email',
                          controller: _emailCtrl,
                          icon: Icons.mail_outline,
                          enabled: false,
                        ),
                        const SizedBox(height: 18),
                        _PasswordField(
                          label: 'New Password',
                          controller: _passwordCtrl,
                          show: _showPass,
                          onToggle: () => setState(() => _showPass = !_showPass),
                        ),
                        const SizedBox(height: 12),
                        _PasswordField(
                          label: 'Confirm Password',
                          controller: _confirmCtrl,
                          show: _showConfirm,
                          onToggle: () =>
                              setState(() => _showConfirm = !_showConfirm),
                        ),
                        const SizedBox(height: 8),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Leave password blank if you do not want to change it.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                            ),
                          ),
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
                      onPressed: _isSaving ? null : _onSavePressed,
                      child: Text(
                        _isSaving ? 'Saving...' : 'Save Changes',
                        style: const TextStyle(
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