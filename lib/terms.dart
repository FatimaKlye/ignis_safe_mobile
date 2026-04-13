import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TermsAndConditionsPage extends StatefulWidget {
  final String? userId;
  final bool readOnly;

  const TermsAndConditionsPage({
    super.key,
    this.userId,
    this.readOnly = false,
  });

  @override
  State<TermsAndConditionsPage> createState() =>
      _TermsAndConditionsPageState();
}

class _TermsAndConditionsPageState extends State<TermsAndConditionsPage> {
  final ScrollController _scrollController = ScrollController();

  double _progress = 0.0;
  bool _scrolledToBottom = false;
  bool _checked = false;
  bool _saving = false;

  static const Color brandRed = Color(0xFFB71C1C);
  static const Color background = Colors.white;

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleScroll());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;

    final max = _scrollController.position.maxScrollExtent;
    final offset = _scrollController.offset;
    final value = (max <= 0) ? 1.0 : (offset / max).clamp(0.0, 1.0);

    if (value != _progress) {
      setState(() => _progress = value);
    }

    if (!_scrolledToBottom && value >= 0.99) {
      setState(() => _scrolledToBottom = true);
    }
  }

  Future<void> _onAgree() async {
    if (widget.readOnly || widget.userId == null) {
      Navigator.pop(context, false);
      return;
    }

    setState(() => _saving = true);

    try {
      await supabase.from('profiles').update({
        'terms_accepted': true,
        'terms_accepted_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', widget.userId!);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save agreement: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final percent = (_progress * 100).round();

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: const Text(
          'Terms & Conditions',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: brandRed,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: brandRed),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 6,
                    backgroundColor: brandRed.withOpacity(0.15),
                    valueColor: const AlwaysStoppedAnimation<Color>(brandRed),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _scrolledToBottom ? '100%' : '$percent%',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: brandRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFB71C1C),
          ),
          Expanded(
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                children: const [
                  _Title('TERMS AND CONDITIONS'),
                  SizedBox(height: 16),
                  _SectionTitle('1. Introduction'),
                  _BodyText(
                    'These Terms and Conditions govern your access to and use of the Ignis Safe mobile application. By creating an account or using the application, you agree to comply with and be legally bound by these Terms. If you do not agree with any part of these Terms, you must not use the application.',
                  ),
                  _SectionTitle('2. Purpose of the Application'),
                  _BodyText(
                    'Ignis Safe is a fire safety learning and assessment platform. The application provides educational modules, interactive simulations powered by Unity, and structured pre-test and post-test evaluations. The system is designed for training, awareness, and performance assessment purposes.',
                  ),
                  _SectionTitle('3. Account Registration and Verification'),
                  _BodyText(
                    'To access the application, users must provide accurate personal information including First Name, Last Name, and Email Address. For verification, users are redirected to Google services for OTP authentication. Ignis Safe does not collect, store, or have access to your Google password.',
                  ),
                  _SectionTitle('4. Data Collection'),
                  _BodyText(
                    'Ignis Safe collects and processes the following information:\n\n• First Name\n• Last Name\n• Email Address\n• Pre-test and Post-test Scores\n• Training progress and activity data\n\nThis information is used strictly for authentication, monitoring progress, reporting, and improving system functionality.',
                  ),
                  _SectionTitle('5. Unity Simulation Integration'),
                  _BodyText(
                    'Certain learning modules and simulations are delivered through Unity technology. Limited technical data may be processed to ensure proper system functionality, performance optimization, and compatibility.',
                  ),
                  _SectionTitle('6. Administrative Access and Reporting'),
                  _BodyText(
                    'User registration details, training progress, and assessment results may be accessed by authorized Bureau of Fire Protection (BFP) administrators for monitoring, evaluation, and official reporting purposes. By using the application, you consent to this administrative access.',
                  ),
                  _SectionTitle('7. Data Protection and Security'),
                  _BodyText(
                    'Ignis Safe implements reasonable technical and organizational measures to protect user information. While we strive to safeguard all data, no digital system can guarantee absolute security.',
                  ),
                  _SectionTitle('8. User Responsibilities'),
                  _BodyText(
                    'Users agree to provide accurate information, maintain the confidentiality of their credentials, and use the application solely for lawful training purposes. Any attempt to manipulate results, misuse the system, or interfere with functionality may result in account suspension or termination.',
                  ),
                  _SectionTitle('9. Intellectual Property'),
                  _BodyText(
                    'All content within the application, including educational materials, simulations, graphics, and system design, is the intellectual property of Ignis Safe unless otherwise stated. Unauthorized reproduction or distribution is prohibited.',
                  ),
                  _SectionTitle('10. Limitation of Liability'),
                  _BodyText(
                    'Ignis Safe provides training and educational content for awareness and evaluation purposes only. The application does not replace official fire safety certification unless explicitly stated. Ignis Safe shall not be liable for damages arising from system interruptions, external technical issues, or misuse of the application.',
                  ),
                  _SectionTitle('11. Termination'),
                  _BodyText(
                    'Ignis Safe reserves the right to suspend or terminate access to the application if a user violates these Terms or engages in unlawful activity.',
                  ),
                  _SectionTitle('12. Amendments'),
                  _BodyText(
                    'These Terms and Conditions may be updated at any time. Continued use of the application after modifications constitutes acceptance of the revised Terms.',
                  ),
                  _SectionTitle('13. Governing Law'),
                  _BodyText(
                    'These Terms and Conditions shall be governed by and interpreted in accordance with the laws of the Republic of the Philippines.',
                  ),
                  _SectionTitle('14. Contact Information'),
                  _BodyText(
                    'For inquiries regarding these Terms and Conditions, please contact: andreicarisma24@gmail.com.',
                  ),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFB71C1C), width: 1),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_scrolledToBottom)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text(
                      'Scroll to the bottom to continue',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: brandRed,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if (_scrolledToBottom && !widget.readOnly) ...[
                  Row(
                    children: [
                      Checkbox(
                        value: _checked,
                        activeColor: brandRed,
                        onChanged: _saving
                            ? null
                            : (v) => setState(() => _checked = v ?? false),
                      ),
                      const Expanded(
                        child: Text(
                          'I have read and agree to the Terms and Conditions.',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            (_checked && !_saving) ? brandRed : Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: (_checked && !_saving) ? _onAgree : null,
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'I Agree',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Title extends StatelessWidget {
  final String text;
  const _Title(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Color(0xFFB71C1C),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFFB71C1C),
        ),
      ),
    );
  }
}

class _BodyText extends StatelessWidget {
  final String text;
  const _BodyText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13.5,
        color: Colors.black87,
        height: 1.5,
      ),
    );
  }
}
