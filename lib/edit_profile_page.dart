part of 'profile.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  static const Color brandRed = Color(0xFFB11217);
  static const String _bucketName = 'profile_pic';

  final ImagePicker _picker = ImagePicker();

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  Uint8List? _newAvatarBytes;
  String? _newAvatarExt;
  String? _existingAvatarUrl;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _showPass = false;
  bool _showConfirm = false;

  String _originalFirstName = '';
  String _originalLastName = '';

  bool get _isTl => Localizations.localeOf(context).languageCode == 'tl';

  String _txt(String en, String tl) => _isTl ? tl : en;

  String _friendlyError(Object error, String enFallback, String tlFallback) {
    return _isTl ? tlFallback : '$enFallback\n$error';
  }

  String _authErrorMessage(String message) {
    if (!_isTl) return message;

    final lower = message.toLowerCase();
    if (lower.contains('password')) {
      return 'Hindi ma-update ang password. Pakisuri ang bagong password at subukang muli.';
    }
    if (lower.contains('email')) {
      return 'Hindi ma-update ang email. Pakisubukang muli.';
    }
    if (lower.contains('rate') || lower.contains('too many')) {
      return 'Masyadong maraming pagsubok. Maghintay sandali bago subukang muli.';
    }
    return 'Hindi na-update ang profile. Pakisubukang muli.';
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
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
        throw Exception(_txt('No active session.', 'Walang aktibong session.'));
      }

      final data = await supabase
          .from('profiles')
          .select('first_name, last_name, email, avatar_url')
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) {
        final metadata = user.userMetadata ?? {};

        await supabase.from('profiles').upsert({
          'id': user.id,
          'first_name': (metadata['first_name'] ?? '').toString(),
          'last_name': (metadata['last_name'] ?? '').toString(),
          'email': user.email ?? '',
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
      }

      final refreshed = await supabase
          .from('profiles')
          .select('first_name, last_name, email, avatar_url')
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;

      final firstName = (refreshed?['first_name'] ?? '').toString();
      final lastName = (refreshed?['last_name'] ?? '').toString();
      final email = (refreshed?['email'] ?? user.email ?? '').toString();
      final avatarUrl = refreshed?['avatar_url']?.toString();

      setState(() {
        _firstNameCtrl.text = firstName;
        _lastNameCtrl.text = lastName;
        _emailCtrl.text = email;
        _existingAvatarUrl = avatarUrl;

        _originalFirstName = firstName;
        _originalLastName = lastName;

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      await _showInfoDialog(
        title: _txt('Failed to load profile', 'Hindi na-load ang profile'),
        message: _friendlyError(e, 'Failed to load profile.', 'Hindi na-load ang profile. Pakisubukang muli.'),
        buttonText: _txt('OK', 'Sige'),
      );
    }
  }

  Future<void> _pickAvatar() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final ext = picked.name.contains('.')
          ? picked.name.split('.').last.toLowerCase()
          : 'jpg';

      if (!mounted) return;

      setState(() {
        _newAvatarBytes = bytes;
        _newAvatarExt = ext;
      });
    } catch (e) {
      if (!mounted) return;
      await _showInfoDialog(
        title: _txt('Image Error', 'Error sa Larawan'),
        message: _friendlyError(e, 'Could not read selected image.', 'Hindi mabasa ang napiling larawan. Pakisubukang muli.'),
        buttonText: _txt('OK', 'Sige'),
      );
    }
  }

  Future<bool> _validateInputs() async {
    final first = _firstNameCtrl.text.trim();
    final last = _lastNameCtrl.text.trim();
    final password = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;

    if (first.isEmpty || last.isEmpty) {
      await _showInfoDialog(
        title: _txt('Incomplete Details', 'Kulang ang Detalye'),
        message: _txt('Please complete First Name and Last Name.', 'Pakikumpleto ang Pangalan at Apelyido.'),
        buttonText: _txt('OK', 'Sige'),
      );
      return false;
    }

    if (password.isNotEmpty || confirm.isNotEmpty) {
      if (password.length < 6) {
        await _showInfoDialog(
          title: _txt('Invalid Password', 'Hindi Wastong Password'),
          message: _txt('Password must be at least 6 characters.', 'Ang password ay dapat may hindi bababa sa 6 na character.'),
          buttonText: _txt('OK', 'Sige'),
        );
        return false;
      }

      if (password != confirm) {
        await _showInfoDialog(
          title: _txt('Password Mismatch', 'Hindi Magkatugma ang Password'),
          message: _txt('Passwords do not match.', 'Hindi magkatugma ang mga password.'),
          buttonText: _txt('OK', 'Sige'),
        );
        return false;
      }
    }

    return true;
  }

  bool _hasActualChanges() {
    return _firstNameCtrl.text.trim() != _originalFirstName ||
        _lastNameCtrl.text.trim() != _originalLastName ||
        _newAvatarBytes != null ||
        _passwordCtrl.text.trim().isNotEmpty;
  }

  List<String> _computeChanges() {
    final changes = <String>[];

    final first = _firstNameCtrl.text.trim();
    final last = _lastNameCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (first != _originalFirstName) {
      changes.add(_txt('First Name: "$_originalFirstName" → "$first"', 'Pangalan: "$_originalFirstName" → "$first"'));
    }

    if (last != _originalLastName) {
      changes.add(_txt('Last Name: "$_originalLastName" → "$last"', 'Apelyido: "$_originalLastName" → "$last"'));
    }

    if (_newAvatarBytes != null) {
      changes.add(_txt('Profile Photo: Updated', 'Larawan sa Profile: Na-update'));
    }

    if (password.isNotEmpty) {
      changes.add(_txt('Password: Will be updated', 'Password: I-a-update'));
    } else {
      changes.add(_txt('Password: No change (left blank)', 'Password: Walang pagbabago (iniwang blangko)'));
    }

    return changes;
  }

  Future<void> _onSavePressed() async {
    if (_isSaving) return;
    if (!await _validateInputs()) return;

    if (!_hasActualChanges()) {
      await _showInfoDialog(
        title: _txt('No changes detected', 'Walang Nakitang Pagbabago'),
        message: _txt(
          'Nothing to update.\n\nPassword is blank, so it will remain unchanged.',
          'Walang kailangang i-update.\n\nBlangko ang password kaya mananatili itong hindi nabago.',
        ),
        buttonText: _txt('OK', 'Sige'),
      );
      return;
    }

    final changes = _computeChanges();

    final wantsUpdate = await _showChangesDialog(changes);
    if (wantsUpdate != true) return;

    final sure = await _showConfirmDialog(
      title: _txt('Confirm Update', 'Kumpirmahin ang Update'),
      message: _txt('Are you sure you want to update these changes?', 'Sigurado ka bang gusto mong i-update ang mga pagbabagong ito?'),
      confirmText: _txt('Yes, Update', 'Oo, I-update'),
      cancelText: _txt('No', 'Hindi'),
    );
    if (sure != true) return;

    setState(() => _isSaving = true);

    try {
      await _performUpdate();

      if (!mounted) return;

      await _showInfoDialog(
        title: _txt('Updated', 'Na-update'),
        message: _txt('Changed successfully.', 'Matagumpay na nabago.'),
        buttonText: _txt('OK', 'Sige'),
      );

      Navigator.pop(context, true);
    } on AuthException catch (e) {
      if (!mounted) return;
      await _showInfoDialog(
        title: _txt('Update Failed', 'Hindi Na-update'),
        message: _authErrorMessage(e.message),
        buttonText: _txt('OK', 'Sige'),
      );
    } catch (e) {
      if (!mounted) return;
      await _showInfoDialog(
        title: _txt('Update Failed', 'Hindi Na-update'),
        message: _friendlyError(e, 'Update failed.', 'Hindi na-update ang profile. Pakisubukang muli.'),
        buttonText: _txt('OK', 'Sige'),
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
      throw Exception(_txt('No active session.', 'Walang aktibong session.'));
    }

    String? avatarUrl = _existingAvatarUrl;

    if (_newAvatarBytes != null) {
      final ext = (_newAvatarExt ?? 'jpg').toLowerCase();
      final path = '${user.id}/avatar.$ext';

      await supabase.storage.from(_bucketName).uploadBinary(
        path,
        _newAvatarBytes!,
        fileOptions: FileOptions(
          upsert: true,
          contentType: _getContentType(ext),
        ),
      );

      final rawUrl = supabase.storage.from(_bucketName).getPublicUrl(path);
      avatarUrl = '$rawUrl?v=${DateTime.now().millisecondsSinceEpoch}';
    }

    await supabase.from('profiles').upsert({
      'id': user.id,
      'first_name': _firstNameCtrl.text.trim(),
      'last_name': _lastNameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'avatar_url': avatarUrl,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
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
      _existingAvatarUrl = avatarUrl;
      _newAvatarBytes = null;
      _newAvatarExt = null;
    });
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
                Text(
                  _txt('Review Changes', 'Suriin ang mga Pagbabago'),
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
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _txt('Leave the password fields blank if you want to keep your current password.', 'Iwanang blangko ang password fields kung gusto mong panatilihin ang kasalukuyan mong password.'),
                    style: const TextStyle(
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
                        child: Text(
                          _txt('Back', 'Bumalik'),
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
                        child: Text(
                          _txt('Update', 'I-update'),
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
    if (_newAvatarBytes != null) {
      return MemoryImage(_newAvatarBytes!);
    }

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
                      Text(
                        _txt('Edit Profile', 'I-edit ang Profile'),
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
                          label: _txt('First Name', 'Pangalan'),
                          controller: _firstNameCtrl,
                          icon: Icons.badge_outlined,
                        ),
                        const SizedBox(height: 12),
                        _Field(
                          label: _txt('Last Name', 'Apelyido'),
                          controller: _lastNameCtrl,
                          icon: Icons.badge_outlined,
                        ),
                        const SizedBox(height: 12),
                        _Field(
                          label: _txt('Email', 'Email'),
                          controller: _emailCtrl,
                          icon: Icons.mail_outline,
                          enabled: false,
                        ),
                        const SizedBox(height: 18),
                        _PasswordField(
                          label: _txt('New Password', 'Bagong Password'),
                          controller: _passwordCtrl,
                          show: _showPass,
                          onToggle: () => setState(() => _showPass = !_showPass),
                        ),
                        const SizedBox(height: 12),
                        _PasswordField(
                          label: _txt('Confirm Password', 'Kumpirmahin ang Password'),
                          controller: _confirmCtrl,
                          show: _showConfirm,
                          onToggle: () =>
                              setState(() => _showConfirm = !_showConfirm),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _txt('Leave password blank if you do not want to change it.', 'Iwanang blangko ang password kung ayaw mo itong palitan.'),
                            style: const TextStyle(
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
                        _isSaving
                            ? _txt('Saving...', 'Sine-save...')
                            : _txt('Save Changes', 'I-save ang Pagbabago'),
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
