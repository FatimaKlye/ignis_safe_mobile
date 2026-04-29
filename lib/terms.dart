import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'localization/language_controller.dart';

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
        SnackBar(
          content: Text(
            t(context, 'Could not save agreement: $e',
                'Hindi ma-save ang kasunduan: $e'),
          ),
        ),
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
        title: Text(
          t(context, 'Terms & Conditions', 'Mga Tuntunin at Kundisyon'),
          style: const TextStyle(
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
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(brandRed),
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
                children: [
                  _Title(t(context, 'TERMS AND CONDITIONS',
                      'MGA TUNTUNIN AT KUNDISYON')),
                  const SizedBox(height: 16),

                  // 1. Introduction
                  _SectionTitle(
                      t(context, '1. Introduction', '1. Panimula')),
                  _BodyText(t(
                    context,
                    'These Terms and Conditions govern your access to and use of the Ignis Safe mobile application. By creating an account or using the application, you agree to comply with and be legally bound by these Terms. If you do not agree with any part of these Terms, you must not use the application.',
                    'Ang Mga Tuntunin at Kundisyong ito ay namamahala sa iyong pag-access at paggamit ng Ignis Safe mobile application. Sa pamamagitan ng paglikha ng account o paggamit ng application, sumasang-ayon kang sumunod at legal na mapigiln ng Mga Tuntuning ito. Kung hindi ka sumasang-ayon sa anumang bahagi ng Mga Tuntuning ito, hindi mo dapat gamitin ang application.',
                  )),

                  // 2. Purpose
                  _SectionTitle(t(context, '2. Purpose of the Application',
                      '2. Layunin ng Application')),
                  _BodyText(t(
                    context,
                    'Ignis Safe is a fire safety learning and assessment platform. The application provides educational modules, interactive simulations powered by Unity, and structured pre-test and post-test evaluations. The system is designed for training, awareness, and performance assessment purposes.',
                    'Ang Ignis Safe ay isang platform para sa pag-aaral at pagtatasa ng kaligtasan sa sunog. Nagbibigay ang application ng mga educational module, interactive simulations na pinapagana ng Unity, at nakabalangkas na pre-test at post-test evaluations. Ang sistema ay dinisenyo para sa layuning pagsasanay, kamalayan, at pagtatasa ng pagganap.',
                  )),

                  // 3. Account Registration
                  _SectionTitle(t(
                    context,
                    '3. Account Registration and Verification',
                    '3. Pagpaparehistro at Pag-verify ng Account',
                  )),
                  _BodyText(t(
                    context,
                    'To access the application, users must provide accurate personal information including First Name, Last Name, and Email Address. For verification, users are redirected to Google services for OTP authentication. Ignis Safe does not collect, store, or have access to your Google password.',
                    'Upang ma-access ang application, ang mga gumagamit ay dapat magbigay ng tumpak na personal na impormasyon kabilang ang Pangalan, Apelyido, at Email Address. Para sa pag-verify, ang mga gumagamit ay nire-redirect sa mga serbisyo ng Google para sa OTP authentication. Ang Ignis Safe ay hindi nangongolekta, nag-iimbak, o may access sa iyong Google password.',
                  )),

                  // 4. Data Collection
                  _SectionTitle(t(context, '4. Data Collection',
                      '4. Pagkolekta ng Data')),
                  _BodyText(t(
                    context,
                    'Ignis Safe collects and processes the following information:\n\n• First Name\n• Last Name\n• Email Address\n• Pre-test and Post-test Scores\n• Training progress and activity data\n\nThis information is used strictly for authentication, monitoring progress, reporting, and improving system functionality.',
                    'Ang Ignis Safe ay nangongolekta at nagpoproseso ng sumusunod na impormasyon:\n\n• Pangalan\n• Apelyido\n• Email Address\n• Mga Marka sa Pre-test at Post-test\n• Data ng progreso at aktibidad sa pagsasanay\n\nAng impormasyong ito ay ginagamit nang mahigpit para sa authentication, pagsubaybay ng progreso, pag-uulat, at pagpapabuti ng functionality ng sistema.',
                  )),

                  // 5. Unity Simulation
                  _SectionTitle(t(
                    context,
                    '5. Unity Simulation Integration',
                    '5. Pagsasama ng Unity Simulation',
                  )),
                  _BodyText(t(
                    context,
                    'Certain learning modules and simulations are delivered through Unity technology. Limited technical data may be processed to ensure proper system functionality, performance optimization, and compatibility.',
                    'Ang ilang mga learning module at simulation ay inihahatid sa pamamagitan ng teknolohiya ng Unity. Limitadong teknikal na data ang maaaring iproseso upang matiyak ang maayos na functionality ng sistema, pag-optimize ng pagganap, at compatibility.',
                  )),

                  // 6. Administrative Access
                  _SectionTitle(t(
                    context,
                    '6. Administrative Access and Reporting',
                    '6. Administratibong Pag-access at Pag-uulat',
                  )),
                  _BodyText(t(
                    context,
                    'User registration details, training progress, and assessment results may be accessed by authorized Bureau of Fire Protection (BFP) administrators for monitoring, evaluation, and official reporting purposes. By using the application, you consent to this administrative access.',
                    'Ang mga detalye ng pagpaparehistro ng gumagamit, progreso sa pagsasanay, at mga resulta ng pagtatasa ay maaaring ma-access ng mga awtorisadong administrator ng Bureau of Fire Protection (BFP) para sa layuning pagsubaybay, ebalwasyon, at opisyal na pag-uulat. Sa paggamit ng application, pumapayag ka sa administratibong pag-access na ito.',
                  )),

                  // 7. Data Protection
                  _SectionTitle(t(
                    context,
                    '7. Data Protection and Security',
                    '7. Proteksyon at Seguridad ng Data',
                  )),
                  _BodyText(t(
                    context,
                    'Ignis Safe implements reasonable technical and organizational measures to protect user information. While we strive to safeguard all data, no digital system can guarantee absolute security.',
                    'Ang Ignis Safe ay nagpapatupad ng makatwirang teknikal at organisasyonal na mga hakbang upang protektahan ang impormasyon ng gumagamit. Bagama\'t nagsisikap kaming pangalagaan ang lahat ng data, walang digital na sistema ang makakagarantiya ng ganap na seguridad.',
                  )),

                  // 8. User Responsibilities
                  _SectionTitle(t(
                    context,
                    '8. User Responsibilities',
                    '8. Mga Responsibilidad ng Gumagamit',
                  )),
                  _BodyText(t(
                    context,
                    'Users agree to provide accurate information, maintain the confidentiality of their credentials, and use the application solely for lawful training purposes. Any attempt to manipulate results, misuse the system, or interfere with functionality may result in account suspension or termination.',
                    'Sumasang-ayon ang mga gumagamit na magbigay ng tumpak na impormasyon, panatilihing kumpidensyal ang kanilang mga kredensyal, at gamitin ang application nang eksklusibo para sa mga legal na layunin ng pagsasanay. Ang anumang pagtatangkang manipulahin ang mga resulta, maling gamitin ang sistema, o makagambala sa functionality ay maaaring magresulta sa pagsuspinde o pagwawakas ng account.',
                  )),

                  // 9. Intellectual Property
                  _SectionTitle(t(
                    context,
                    '9. Intellectual Property',
                    '9. Intelektwal na Ari-arian',
                  )),
                  _BodyText(t(
                    context,
                    'All content within the application, including educational materials, simulations, graphics, and system design, is the intellectual property of Ignis Safe unless otherwise stated. Unauthorized reproduction or distribution is prohibited.',
                    'Ang lahat ng nilalaman sa loob ng application, kabilang ang mga educational na materyales, simulations, graphics, at disenyo ng sistema, ay intelektwal na ari-arian ng Ignis Safe maliban kung may iba pang nakasaad. Ang hindi awtorisadong pagpaparami o pamamahagi ay ipinagbabawal.',
                  )),

                  // 10. Limitation of Liability
                  _SectionTitle(t(
                    context,
                    '10. Limitation of Liability',
                    '10. Limitasyon ng Pananagutan',
                  )),
                  _BodyText(t(
                    context,
                    'Ignis Safe provides training and educational content for awareness and evaluation purposes only. The application does not replace official fire safety certification unless explicitly stated. Ignis Safe shall not be liable for damages arising from system interruptions, external technical issues, or misuse of the application.',
                    'Ang Ignis Safe ay nagbibigay ng pagsasanay at educational na nilalaman para lamang sa layuning kamalayan at ebalwasyon. Ang application ay hindi pumapalit sa opisyal na fire safety certification maliban kung malinaw na nakasaad. Ang Ignis Safe ay hindi mananagot sa mga pinsalang dulot ng mga pagkaantala ng sistema, mga panlabas na teknikal na isyu, o maling paggamit ng application.',
                  )),

                  // 11. Termination
                  _SectionTitle(
                      t(context, '11. Termination', '11. Pagwawakas')),
                  _BodyText(t(
                    context,
                    'Ignis Safe reserves the right to suspend or terminate access to the application if a user violates these Terms or engages in unlawful activity.',
                    'Inireserba ng Ignis Safe ang karapatang suspindihin o wakasan ang pag-access sa application kung lalabag ang isang gumagamit sa Mga Tuntuning ito o makikisangkot sa ilegal na aktibidad.',
                  )),

                  // 12. Amendments
                  _SectionTitle(
                      t(context, '12. Amendments', '12. Mga Pagbabago')),
                  _BodyText(t(
                    context,
                    'These Terms and Conditions may be updated at any time. Continued use of the application after modifications constitutes acceptance of the revised Terms.',
                    'Ang Mga Tuntunin at Kundisyong ito ay maaaring ma-update anumang oras. Ang patuloy na paggamit ng application pagkatapos ng mga pagbabago ay nagtataglay ng pagtanggap sa mga binagong Tuntunin.',
                  )),

                  // 13. Governing Law
                  _SectionTitle(t(
                    context,
                    '13. Governing Law',
                    '13. Namamahalang Batas',
                  )),
                  _BodyText(t(
                    context,
                    'These Terms and Conditions shall be governed by and interpreted in accordance with the laws of the Republic of the Philippines.',
                    'Ang Mga Tuntunin at Kundisyong ito ay pamamahalaan at bibigyang-kahulugan alinsunod sa mga batas ng Republika ng Pilipinas.',
                  )),

                  // 14. Contact Information
                  _SectionTitle(t(
                    context,
                    '14. Contact Information',
                    '14. Impormasyon sa Pakikipag-ugnayan',
                  )),
                  _BodyText(t(
                    context,
                    'For inquiries regarding these Terms and Conditions, please contact: andreicarisma24@gmail.com.',
                    'Para sa mga katanungan tungkol sa Mga Tuntunin at Kundisyong ito, makipag-ugnayan sa: andreicarisma24@gmail.com.',
                  )),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFB71C1C), width: 1),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_scrolledToBottom)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      t(
                        context,
                        'Scroll to the bottom to continue',
                        'Mag-scroll hanggang sa ibaba para magpatuloy',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
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
                      Expanded(
                        child: Text(
                          t(
                            context,
                            'I have read and agree to the Terms and Conditions.',
                            'Nabasa ko at sumasang-ayon ako sa Mga Tuntunin at Kundisyon.',
                          ),
                          style: const TextStyle(
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
                          : Text(
                              t(context, 'I Agree', 'Sumasang-ayon Ako'),
                              style: const TextStyle(
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
  const _Title(this.text);

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
  const _SectionTitle(this.text);

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
  const _BodyText(this.text);

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