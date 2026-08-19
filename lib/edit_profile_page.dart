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
  bool _isPickingImage = false;
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
        message: _friendlyError(
          e,
          'Failed to load profile.',
          'Hindi na-load ang profile. Pakisubukang muli.',
        ),
        buttonText: _txt('OK', 'Sige'),
        icon: Icons.error_outline_rounded,
      );
    }
  }

  Future<void> _pickAvatar() async {
    if (_isPickingImage) return;

    setState(() => _isPickingImage = true);

    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (picked == null) return;

      final bytes = await picked.readAsBytes();

      if (!mounted) return;

      final croppedBytes = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => ProfileImageCropPage(imageBytes: bytes, isTl: _isTl),
        ),
      );

      if (croppedBytes == null || !mounted) return;

      setState(() {
        _newAvatarBytes = croppedBytes;
        _newAvatarExt = 'png';
      });
    } catch (e) {
      if (!mounted) return;
      await _showInfoDialog(
        title: _txt('Image Error', 'Error sa Larawan'),
        message: _txt(
          'Could not select an image. Please try again.',
          'Hindi mapili ang larawan. Pakisubukang muli.',
        ),
        buttonText: _txt('OK', 'Sige'),
        icon: Icons.error_outline_rounded,
      );
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      } else {
        _isPickingImage = false;
      }
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
        message: _txt(
          'Please complete First Name and Last Name.',
          'Pakikumpleto ang Pangalan at Apelyido.',
        ),
        buttonText: _txt('OK', 'Sige'),
        icon: Icons.warning_amber_rounded,
      );
      return false;
    }

    if (password.isNotEmpty || confirm.isNotEmpty) {
      if (password.length < 6) {
        await _showInfoDialog(
          title: _txt('Invalid Password', 'Hindi Wastong Password'),
          message: _txt(
            'Password must be at least 6 characters.',
            'Ang password ay dapat may hindi bababa sa 6 na character.',
          ),
          buttonText: _txt('OK', 'Sige'),
          icon: Icons.warning_amber_rounded,
        );
        return false;
      }

      if (password != confirm) {
        await _showInfoDialog(
          title: _txt('Password Mismatch', 'Hindi Magkatugma ang Password'),
          message: _txt(
            'Passwords do not match.',
            'Hindi magkatugma ang mga password.',
          ),
          buttonText: _txt('OK', 'Sige'),
          icon: Icons.warning_amber_rounded,
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
      changes.add(
        _txt(
          'First Name: "$_originalFirstName" → "$first"',
          'Pangalan: "$_originalFirstName" → "$first"',
        ),
      );
    }

    if (last != _originalLastName) {
      changes.add(
        _txt(
          'Last Name: "$_originalLastName" → "$last"',
          'Apelyido: "$_originalLastName" → "$last"',
        ),
      );
    }

    if (_newAvatarBytes != null) {
      changes.add(
        _txt('Profile Photo: Updated', 'Larawan sa Profile: Na-update'),
      );
    }

    if (password.isNotEmpty) {
      changes.add(_txt('Password: Will be updated', 'Password: I-a-update'));
    } else {
      changes.add(
        _txt(
          'Password: No change (left blank)',
          'Password: Walang pagbabago (iniwang blangko)',
        ),
      );
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
        icon: Icons.info_outline_rounded,
      );
      return;
    }

    final changes = _computeChanges();

    final wantsUpdate = await _showChangesDialog(changes);
    if (wantsUpdate != true) return;

    final sure = await _showConfirmDialog(
      title: _txt('Confirm Update', 'Kumpirmahin ang Update'),
      message: _txt(
        'Are you sure you want to update these changes?',
        'Sigurado ka bang gusto mong i-update ang mga pagbabagong ito?',
      ),
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
        icon: Icons.check_circle_rounded,
      );

      Navigator.pop(context, true);
    } on AuthException catch (e) {
      if (!mounted) return;
      await _showInfoDialog(
        title: _txt('Update Failed', 'Hindi Na-update'),
        message: _authErrorMessage(e.message),
        buttonText: _txt('OK', 'Sige'),
        icon: Icons.error_outline_rounded,
      );
    } catch (e) {
      if (!mounted) return;
      await _showInfoDialog(
        title: _txt('Update Failed', 'Hindi Na-update'),
        message: _friendlyError(
          e,
          'Update failed.',
          'Hindi na-update ang profile. Pakisubukang muli.',
        ),
        buttonText: _txt('OK', 'Sige'),
        icon: Icons.error_outline_rounded,
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

    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();
    final email = _emailCtrl.text.trim().toLowerCase();
    String? avatarUrl = _existingAvatarUrl;

    if (_newAvatarBytes != null) {
      final ext = (_newAvatarExt ?? 'jpg').toLowerCase();
      final path = '${user.id}/avatar.$ext';

      await supabase.storage
          .from(_bucketName)
          .uploadBinary(
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

    final updatedProfile = await supabase
        .from('profiles')
        .update({
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'avatar_url': avatarUrl,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', user.id)
        .select('first_name, last_name, email, avatar_url')
        .maybeSingle();

    if (updatedProfile == null) {
      throw Exception(
        _txt(
          'No profile row was updated. Please check the profiles RLS update policy.',
          'Walang profile row na na-update. Pakisuri ang RLS update policy ng profiles table.',
        ),
      );
    }

    final pass = _passwordCtrl.text.trim();
    final metadata = <String, dynamic>{
      'first_name': firstName,
      'last_name': lastName,
    };

    if (avatarUrl != null && avatarUrl.trim().isNotEmpty) {
      metadata['avatar_url'] = avatarUrl;
    }

    if (pass.isNotEmpty) {
      await supabase.auth.updateUser(
        UserAttributes(password: pass, data: metadata),
      );
      _passwordCtrl.clear();
      _confirmCtrl.clear();
    } else {
      await supabase.auth.updateUser(UserAttributes(data: metadata));
    }

    if (!mounted) return;

    notifyProfileChanged();

    setState(() {
      _originalFirstName = firstName;
      _originalLastName = lastName;
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
      builder: (dialogContext) {
        final size = MediaQuery.of(dialogContext).size;
        final horizontalInset = size.width < 360 ? 12.0 : 20.0;
        final maxDialogHeight = size.height * 0.85;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: horizontalInset,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: size.width - (horizontalInset * 2),
              maxHeight: maxDialogHeight,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.20),
                    blurRadius: 30,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                    decoration: const BoxDecoration(
                      color: brandRed,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(22),
                        topRight: Radius.circular(22),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.fact_check_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _txt('Review Changes', 'Suriin ang mga Pagbabago'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...changes.map(
                            (c) => Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFBF0F0),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: brandRed.withOpacity(0.14),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: brandRed,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      c,
                                      softWrap: true,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        height: 1.3,
                                        color: Color(0xFF3A3A3A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: Colors.grey.shade600,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _txt(
                                      'Leave the password fields blank if you want to keep your current password.',
                                      'Iwanang blangko ang password fields kung gusto mong panatilihin ang kasalukuyan mong password.',
                                    ),
                                    softWrap: true,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black54,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF3A3A3A),
                                    side: BorderSide(
                                      color: Colors.black.withOpacity(0.16),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 13,
                                    ),
                                  ),
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      _txt('Back', 'Bumalik'),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: brandRed,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 13,
                                    ),
                                    elevation: 4,
                                  ),
                                  onPressed: () => Navigator.pop(context, true),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      _txt('Update', 'I-update'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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
      builder: (dialogContext) {
        final size = MediaQuery.of(dialogContext).size;
        final horizontalInset = size.width < 360 ? 12.0 : 20.0;
        final maxDialogHeight = size.height * 0.85;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: horizontalInset,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: size.width - (horizontalInset * 2),
              maxHeight: maxDialogHeight,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.20),
                    blurRadius: 30,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                    decoration: const BoxDecoration(
                      color: brandRed,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(22),
                        topRight: Radius.circular(22),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.help_outline_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBF0F0),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: brandRed.withOpacity(0.14),
                              ),
                            ),
                            child: Text(
                              message,
                              softWrap: true,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                height: 1.35,
                                color: Color(0xFF3A3A3A),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF3A3A3A),
                                    side: BorderSide(
                                      color: Colors.black.withOpacity(0.16),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 13,
                                    ),
                                  ),
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      cancelText,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: brandRed,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 13,
                                    ),
                                    elevation: 4,
                                  ),
                                  onPressed: () => Navigator.pop(context, true),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      confirmText,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showInfoDialog({
    required String title,
    required String message,
    required String buttonText,
    IconData icon = Icons.info_outline_rounded,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final size = MediaQuery.of(dialogContext).size;
        final horizontalInset = size.width < 360 ? 12.0 : 20.0;
        final maxDialogHeight = size.height * 0.85;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: horizontalInset,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: size.width - (horizontalInset * 2),
              maxHeight: maxDialogHeight,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.20),
                    blurRadius: 30,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                    decoration: const BoxDecoration(
                      color: brandRed,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(22),
                        topRight: Radius.circular(22),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: Colors.white, size: 24),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBF0F0),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: brandRed.withOpacity(0.14),
                              ),
                            ),
                            child: Text(
                              message,
                              softWrap: true,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                height: 1.35,
                                color: Color(0xFF3A3A3A),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: brandRed,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                elevation: 4,
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  buttonText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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

  void _toggleModernPasswordVisibility() {
    setState(() => _showPass = !_showPass);
  }

  void _toggleModernConfirmVisibility() {
    setState(() => _showConfirm = !_showConfirm);
  }

  @override
  Widget build(BuildContext context) =>
      _buildModernEditProfileView(this, context);

  // Kept temporarily as a layout reference while the modern view is rolled out.
  // ignore: unused_element
  Widget _buildLegacyEditProfile(BuildContext context) {
    final avatarImage = _buildAvatarImage();

    if (_isLoading) {
      final topPadding = MediaQuery.of(context).padding.top;

      return Scaffold(
        backgroundColor: Colors.white,
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
                    colors: [brandRed, brandRed, Colors.transparent],
                    stops: [0.0, 0.65, 1.0],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    Expanded(
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _txt('Edit Profile', 'I-edit ang Profile'),
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 66,
                    height: 66,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.10),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const CircularProgressIndicator(
                      color: brandRed,
                      strokeWidth: 4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _txt('Loading profile...', 'Nilo-load ang profile...'),
                    style: const TextStyle(
                      color: brandRed,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final mediaQuery = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
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
              height: mediaQuery.padding.top + 200,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [brandRed, brandRed, Colors.transparent],
                  stops: [0.0, 0.65, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                final horizontalPadding = screenWidth < 360 ? 16.0 : 25.0;
                final avatarSize = (screenWidth * 0.42)
                    .clamp(132.0, 160.0)
                    .toDouble();
                final cameraSize = (avatarSize * 0.2625)
                    .clamp(36.0, 42.0)
                    .toDouble();
                final maxContentWidth = screenWidth > 520
                    ? 520.0
                    : double.infinity;

                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    14,
                    horizontalPadding,
                    14 + mediaQuery.viewInsets.bottom,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      child: Column(
                        children: [
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              SizedBox(
                                width: 48,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: IconButton(
                                    onPressed: () => Navigator.pop(context),
                                    icon: const Icon(
                                      Icons.arrow_back,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      _txt(
                                        'Edit Profile',
                                        'I-edit ang Profile',
                                      ),
                                      maxLines: 1,
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: screenWidth < 360 ? 48 : 60),
                            ],
                          ),
                          const SizedBox(height: 35),
                          GestureDetector(
                            onTap: _isPickingImage ? null : _pickAvatar,
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  width: avatarSize,
                                  height: avatarSize,
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.18),
                                        blurRadius: 20,
                                        offset: const Offset(0, 12),
                                      ),
                                    ],
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.grey.shade100,
                                      image: avatarImage != null
                                          ? DecorationImage(
                                              image: avatarImage,
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: avatarImage == null
                                        ? Icon(
                                            Icons.person,
                                            size: avatarSize * 0.38,
                                            color: Colors.grey.shade400,
                                          )
                                        : null,
                                  ),
                                ),
                                Container(
                                  width: cameraSize,
                                  height: cameraSize,
                                  decoration: BoxDecoration(
                                    color: brandRed,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.18),
                                        blurRadius: 10,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: cameraSize * 0.48,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 18,
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
                                const SizedBox(height: 20),
                                _Field(
                                  label: _txt('Last Name', 'Apelyido'),
                                  controller: _lastNameCtrl,
                                  icon: Icons.badge_outlined,
                                ),
                                const SizedBox(height: 20),
                                _Field(
                                  label: _txt('Email', 'Email'),
                                  controller: _emailCtrl,
                                  icon: Icons.mail_outline,
                                  enabled: false,
                                ),
                                const SizedBox(height: 24),
                                _PasswordField(
                                  label: _txt(
                                    'New Password',
                                    'Bagong Password',
                                  ),
                                  controller: _passwordCtrl,
                                  show: _showPass,
                                  onToggle: () =>
                                      setState(() => _showPass = !_showPass),
                                ),
                                const SizedBox(height: 20),
                                _PasswordField(
                                  label: _txt(
                                    'Confirm Password',
                                    'Kumpirmahin ang Password',
                                  ),
                                  controller: _confirmCtrl,
                                  show: _showConfirm,
                                  onToggle: () => setState(
                                    () => _showConfirm = !_showConfirm,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    _txt(
                                      'Leave password blank if you do not want to change it.',
                                      'Iwanang blangko ang password kung ayaw mo itong palitan.',
                                    ),
                                    softWrap: true,
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
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: brandRed,
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: _isSaving ? null : _onSavePressed,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _isSaving
                                      ? _txt('Saving...', 'Sine-save...')
                                      : _txt(
                                          'Save Changes',
                                          'I-save ang Pagbabago',
                                        ),
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                      ),
                    ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade500,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          maxLines: 1,
          decoration: InputDecoration(
            isDense: true,
            prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade500),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            border: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0x1F000000)),
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0x1F000000)),
            ),
            disabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0x14000000)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFB11217), width: 1.6),
            ),
          ),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: enabled ? const Color(0xFF222222) : Colors.grey.shade500,
          ),
        ),
      ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade500,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: !show,
          maxLines: 1,
          decoration: InputDecoration(
            isDense: true,
            prefixIcon: Icon(
              Icons.lock_outline,
              size: 20,
              color: Colors.grey.shade500,
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            border: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0x1F000000)),
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0x1F000000)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFB11217), width: 1.6),
            ),
            suffixIcon: IconButton(
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: EdgeInsets.zero,
              onPressed: onToggle,
              icon: Icon(
                show
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF222222),
          ),
        ),
      ],
    );
  }
}
