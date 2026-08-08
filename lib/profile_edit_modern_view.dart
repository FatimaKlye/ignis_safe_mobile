part of 'profile.dart';

Widget _buildModernEditProfileView(
  _EditProfilePageState state,
  BuildContext context,
) {
  const red = Color(0xFFB11217);
  const navy = Color(0xFF142D57);
  final mediaQuery = MediaQuery.of(context);
  final avatarImage = state._buildAvatarImage();

  if (state._isLoading) {
    return _ModernEditLoadingView(
      title: state._txt('Edit Profile', 'I-edit ang Profile'),
      loadingText: state._txt(
        'Loading your profile...',
        'Nilo-load ang iyong profile...',
      ),
      onBack: () => Navigator.pop(context),
    );
  }

  return Scaffold(
    backgroundColor: const Color(0xFFF7F4F2),
    body: Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFF9F6), Color(0xFFF6F7FA)],
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 285,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFC9232A), red, Color(0xFF7F0B12)],
              ),
            ),
            child: const Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  top: -90,
                  right: -55,
                  child: _ProfileHeaderOrb(size: 220, opacity: 0.10),
                ),
                Positioned(
                  top: 155,
                  left: -55,
                  child: _ProfileHeaderOrb(size: 135, opacity: 0.07),
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth < 370
                  ? 16.0
                  : 22.0;
              final avatarSize = constraints.maxWidth < 370 ? 104.0 : 116.0;

              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  12,
                  horizontalPadding,
                  26 + mediaQuery.viewInsets.bottom,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 540),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _ModernBackButton(
                              onTap: () => Navigator.pop(context),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    state._txt(
                                      'Edit Profile',
                                      'I-edit ang Profile',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 23,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    state._txt(
                                      'Keep your account details up to date',
                                      'Panatilihing updated ang iyong account',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.72,
                                      ),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        Center(
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: state._pickAvatar,
                                child: Stack(
                                  clipBehavior: Clip.none,
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
                                            color: Colors.black.withValues(
                                              alpha: 0.18,
                                            ),
                                            blurRadius: 24,
                                            spreadRadius: -3,
                                            offset: const Offset(0, 12),
                                          ),
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        backgroundColor: const Color(
                                          0xFFFFEDEA,
                                        ),
                                        backgroundImage: avatarImage,
                                        child: avatarImage == null
                                            ? Icon(
                                                Icons.person_rounded,
                                                size: avatarSize * 0.40,
                                                color: red,
                                              )
                                            : null,
                                      ),
                                    ),
                                    Positioned(
                                      right: -2,
                                      bottom: 2,
                                      child: Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: navy,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 3,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: navy.withValues(
                                                alpha: 0.25,
                                              ),
                                              blurRadius: 12,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.photo_camera_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                state._txt(
                                  'Tap to change profile photo',
                                  'I-tap para palitan ang profile photo',
                                ),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.76),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _ModernEditSection(
                          icon: Icons.person_outline_rounded,
                          iconColor: red,
                          title: state._txt(
                            'Personal information',
                            'Personal na impormasyon',
                          ),
                          subtitle: state._txt(
                            'Your name and account email',
                            'Iyong pangalan at account email',
                          ),
                          children: [
                            _ModernEditField(
                              label: state._txt('First Name', 'Pangalan'),
                              controller: state._firstNameCtrl,
                              icon: Icons.badge_outlined,
                            ),
                            const SizedBox(height: 15),
                            _ModernEditField(
                              label: state._txt('Last Name', 'Apelyido'),
                              controller: state._lastNameCtrl,
                              icon: Icons.badge_outlined,
                            ),
                            const SizedBox(height: 15),
                            _ModernEditField(
                              label: state._txt(
                                'Email Address',
                                'Email Address',
                              ),
                              controller: state._emailCtrl,
                              icon: Icons.alternate_email_rounded,
                              enabled: false,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _ModernEditSection(
                          icon: Icons.shield_outlined,
                          iconColor: navy,
                          title: state._txt('Security', 'Seguridad'),
                          subtitle: state._txt(
                            'Change your password only when needed',
                            'Palitan lamang ang password kung kailangan',
                          ),
                          children: [
                            _ModernEditField(
                              label: state._txt(
                                'New Password',
                                'Bagong Password',
                              ),
                              controller: state._passwordCtrl,
                              icon: Icons.lock_outline_rounded,
                              obscureText: !state._showPass,
                              trailing: IconButton(
                                tooltip: '',
                                onPressed:
                                    state._toggleModernPasswordVisibility,
                                icon: Icon(
                                  state._showPass
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: const Color(0xFF777B86),
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            _ModernEditField(
                              label: state._txt(
                                'Confirm Password',
                                'Kumpirmahin ang Password',
                              ),
                              controller: state._confirmCtrl,
                              icon: Icons.lock_reset_rounded,
                              obscureText: !state._showConfirm,
                              trailing: IconButton(
                                tooltip: '',
                                onPressed: state._toggleModernConfirmVisibility,
                                icon: Icon(
                                  state._showConfirm
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: const Color(0xFF777B86),
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(height: 13),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(11),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F6FB),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.info_outline_rounded,
                                    color: navy,
                                    size: 17,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      state._txt(
                                        'Leave both password fields blank to keep your current password.',
                                        'Iwanang blangko ang dalawang password field upang panatilihin ang kasalukuyang password.',
                                      ),
                                      style: const TextStyle(
                                        color: Color(0xFF647087),
                                        fontSize: 10.5,
                                        height: 1.35,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: red,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: red.withValues(
                                alpha: 0.45,
                              ),
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: state._isSaving
                                ? null
                                : state._onSavePressed,
                            icon: state._isSaving
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.3,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.check_rounded, size: 21),
                            label: Text(
                              state._isSaving
                                  ? state._txt('Saving...', 'Sine-save...')
                                  : state._txt(
                                      'Save Changes',
                                      'I-save ang Pagbabago',
                                    ),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
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

class _ModernEditLoadingView extends StatelessWidget {
  const _ModernEditLoadingView({
    required this.title,
    required this.loadingText,
    required this.onBack,
  });

  final String title;
  final String loadingText;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F6),
      body: Stack(
        children: [
          Container(
            height: 210,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFC9232A),
                  Color(0xFFB11217),
                  Color(0xFF7F0B12),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _ModernBackButton(onTap: onBack),
                  const SizedBox(width: 13),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 28),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.09),
                    blurRadius: 28,
                    spreadRadius: -6,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox.square(
                    dimension: 38,
                    child: CircularProgressIndicator(
                      color: Color(0xFFB11217),
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 17),
                  Text(
                    loadingText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF142D57),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
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

class _ModernBackButton extends StatelessWidget {
  const _ModernBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: const SizedBox(
          width: 43,
          height: 43,
          child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _ModernEditSection extends StatelessWidget {
  const _ModernEditSection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: const Color(0xFFEEE9E6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 22,
            spreadRadius: -8,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF24262C),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF858994),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}

class _ModernEditField extends StatelessWidget {
  const _ModernEditField({
    required this.label,
    required this.controller,
    required this.icon,
    this.enabled = true,
    this.obscureText = false,
    this.trailing,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool enabled;
  final bool obscureText;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFB11217);

    return TextField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      maxLines: 1,
      style: TextStyle(
        color: enabled ? const Color(0xFF24262C) : const Color(0xFF777B86),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Color(0xFF777B86),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: const TextStyle(
          color: red,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        prefixIcon: Icon(icon, color: enabled ? red : const Color(0xFF9A9DA5)),
        suffixIcon: trailing,
        filled: true,
        fillColor: enabled ? const Color(0xFFFAF8F7) : const Color(0xFFF1F1F3),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E1DF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E1DF)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE4E4E6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: red, width: 1.5),
        ),
      ),
    );
  }
}
