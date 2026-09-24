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

  Uint8List? _newAvatarBytes;
  String? _newAvatarExt;
  String? _existingAvatarUrl;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isPickingImage = false;

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

    return true;
  }

  bool _hasActualChanges() {
    return _firstNameCtrl.text.trim() != _originalFirstName ||
        _lastNameCtrl.text.trim() != _originalLastName ||
        _newAvatarBytes != null;
  }

  List<String> _computeChanges() {
    final changes = <String>[];

    final first = _firstNameCtrl.text.trim();
    final last = _lastNameCtrl.text.trim();

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

    return changes;
  }

  Future<void> _onSavePressed() async {
    if (_isSaving) return;
    if (!await _validateInputs()) return;

    if (!_hasActualChanges()) {
      await _showInfoDialog(
        title: _txt('No changes detected', 'Walang Nakitang Pagbabago'),
        message: _txt(
          'Nothing to update.',
          'Walang kailangang i-update.',
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

    final metadata = <String, dynamic>{
      'first_name': firstName,
      'last_name': lastName,
    };

    if (avatarUrl != null && avatarUrl.trim().isNotEmpty) {
      metadata['avatar_url'] = avatarUrl;
    }

    await supabase.auth.updateUser(UserAttributes(data: metadata));

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

  Future<void> _openChangePassword() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ForgotPassPage(
          entrySource: ForgotPassEntrySource.profile,
        ),
      ),
    );
  }

  Future<void> _openChangeEmail() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ChangeEmailPage()),
    );

    if (changed == true && mounted) {
      await _loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) =>
      _buildModernEditProfileView(this, context);

}
