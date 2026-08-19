import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'consent_service.dart';
import 'localization/language_controller.dart';
import 'widgets/app_notification.dart';

/// Combined Terms and Conditions, Privacy Notice (RA 10173) and Consent
/// screen shown before a learner may use the app.
///
/// Consent is captured as three separate decisions — Terms, Privacy Notice,
/// and an optional research participation consent — and stored as versioned
/// history in `public.user_consents` (see [ConsentService]).
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

  // All consent boxes deliberately start unchecked.
  bool _acceptTerms = false;
  bool _acceptPrivacy = false;
  bool _acceptResearch = false;

  bool _saving = false;
  bool _returningToLogin = false;

  static const Color brandRed = Color(0xFFB71C1C);
  static const Color background = Colors.white;
  static const Color pageBackground = Color(0xFFF6F5F7);
  static const Color cardBackground = Colors.white;
  static const Color subtleBorder = Color(0xFFEDE7E8);

  final supabase = Supabase.instance.client;
  final ConsentService _consentService = ConsentService();

  bool get _requiredConsentsGiven => _acceptTerms && _acceptPrivacy;

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

  void _notify(
    BuildContext context, {
    String? title,
    required String message,
    AppNotificationType type = AppNotificationType.info,
  }) {
    showAppNotification(
      context,
      title: title,
      message: message,
      type: type,
      accentColor: brandRed,
    );
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

    // Guest (read-only) viewers reach the bottom with nothing left to do
    // here, since there's no "I Agree" action in this mode — so once they
    // finish reading, send them back to Login automatically. Guarded by
    // _returningToLogin so this can only fire once per page instance.
    if (widget.readOnly && !_returningToLogin && value >= 0.99) {
      setState(() => _returningToLogin = true);
      _scheduleReturnToLogin();
    }
  }

  Future<void> _scheduleReturnToLogin() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _onAgree() async {
    if (widget.readOnly || widget.userId == null) {
      Navigator.pop(context, false);
      return;
    }

    if (!_requiredConsentsGiven) return;

    final languageCode = Localizations.localeOf(context).languageCode;

    setState(() => _saving = true);

    try {
      await _consentService.recordConsents(
        userId: widget.userId!,
        documentTypes: <String>[
          ConsentDocuments.terms,
          ConsentDocuments.privacy,
          if (_acceptResearch) ConsentDocuments.research,
        ],
        languageCode: languageCode,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _notify(
        context,
        message: t(context, 'Could not save your consent: $e',
            'Hindi na-save ang iyong pahintulot: $e'),
        type: AppNotificationType.error,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final percent = (_progress * 100).round();
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final screenHeight = media.size.height;
    final isSmallPhone = screenWidth < 360;
    final horizontalMargin = isSmallPhone ? 12.0 : 16.0;

    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: background,
        shadowColor: Colors.black.withOpacity(0.08),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: Text(
          t(context, 'Terms, Privacy & Consent',
              'Tuntunin, Privacy at Pahintulot'),
          style: const TextStyle(
            fontFamily: 'Poppins',
            color: brandRed,
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        iconTheme: const IconThemeData(color: brandRed),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Progress card
              Container(
                margin: EdgeInsets.fromLTRB(
                    horizontalMargin, 12, horizontalMargin, 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _progress,
                          minHeight: 8,
                          backgroundColor: brandRed.withOpacity(0.12),
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(brandRed),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 44,
                      child: Text(
                        _scrolledToBottom ? '100%' : '$percent%',
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: brandRed,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Document card
              Expanded(
                child: Container(
                  margin: EdgeInsets.fromLTRB(
                      horizontalMargin, 0, horizontalMargin, 8),
                  decoration: BoxDecoration(
                    color: cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: subtleBorder, width: 1),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    radius: const Radius.circular(8),
                    child: ListView(
                      controller: _scrollController,
                      padding: EdgeInsets.fromLTRB(isSmallPhone ? 16 : 20, 20,
                          isSmallPhone ? 16 : 20, 28),
                      children: _buildDocument(context),
                    ),
                  ),
                ),
              ),

              // Bottom action bar
              _buildActionBar(
                context,
                horizontalMargin: horizontalMargin,
                maxSheetHeight: screenHeight * 0.52,
              ),
            ],
          ),
          if (_returningToLogin) _buildReturningOverlay(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Document content
  // ---------------------------------------------------------------------

  List<Widget> _buildDocument(BuildContext context) {
    return [
      _Title(t(
        context,
        'IGNIS SAFE\nTERMS AND CONDITIONS, PRIVACY NOTICE AND CONSENT',
        'IGNIS SAFE\nMGA TUNTUNIN AT KUNDISYON, PAUNAWA SA PRIVACY AT PAHINTULOT',
      )),
      const SizedBox(height: 14),
      _MetaBox(t(
        context,
        'Terms and Conditions v${ConsentDocuments.termsVersion}  ·  Privacy Notice v${ConsentDocuments.privacyVersion}\nEffective ${ConsentDocuments.effectiveDateEn}\n\nThis Privacy Notice is issued in accordance with the Data Privacy Act of 2012 (Republic Act No. 10173), its Implementing Rules and Regulations, and applicable issuances of the National Privacy Commission (NPC).',
        'Mga Tuntunin at Kundisyon v${ConsentDocuments.termsVersion}  ·  Paunawa sa Privacy v${ConsentDocuments.privacyVersion}\nEpektibo simula ${ConsentDocuments.effectiveDateTl}\n\nAng Paunawa sa Privacy na ito ay inilabas alinsunod sa Data Privacy Act of 2012 (Republic Act Blg. 10173), sa Implementing Rules and Regulations nito, at sa mga naaangkop na isyuwansa ng National Privacy Commission (NPC).',
      )),

      // ---------------- PART I ----------------
      _PartBanner(t(context, 'PART I — TERMS AND CONDITIONS',
          'BAHAGI I — MGA TUNTUNIN AT KUNDISYON')),

      _SectionTitle(t(context, '1. Introduction and Acceptance',
          '1. Panimula at Pagtanggap')),
      _BodyText(t(
        context,
        'This document has three parts: the Terms and Conditions that govern your use of the IGNIS SAFE mobile application, the Privacy Notice that explains how your personal data is processed, and an optional Research Consent.\n\nBy ticking the boxes at the bottom of this screen and continuing, you confirm that you are at least 18 years old (or are using the app with the permission and supervision of a parent, guardian, or authorized trainer), that you have read and understood this document, and that you agree to it. If you do not agree, do not tick the boxes and do not use the application.\n\nYour acceptance is recorded together with the document version, the language you read it in, and the date and time. If the Terms or the Privacy Notice change materially, you will be asked to read and accept the new version before you can continue using the app.',
        'Ang dokumentong ito ay may tatlong bahagi: ang Mga Tuntunin at Kundisyon na namamahala sa iyong paggamit ng IGNIS SAFE mobile application, ang Paunawa sa Privacy na nagpapaliwanag kung paano pinoproseso ang iyong personal na datos, at isang opsyonal na Pahintulot sa Pananaliksik.\n\nSa paglalagay ng tsek sa mga kahon sa ibaba ng screen na ito at pagpapatuloy, kinukumpirma mong ikaw ay hindi bababa sa 18 taong gulang (o gumagamit ng app nang may pahintulot at pangangasiwa ng magulang, tagapag-alaga, o awtorisadong tagapagsanay), na nabasa at naunawaan mo ang dokumentong ito, at sumasang-ayon ka rito. Kung hindi ka sumasang-ayon, huwag lagyan ng tsek ang mga kahon at huwag gamitin ang application.\n\nAng iyong pagtanggap ay itinatala kasama ang bersyon ng dokumento, ang wikang ginamit mo sa pagbasa, at ang petsa at oras. Kung may mahalagang pagbabago sa Mga Tuntunin o sa Paunawa sa Privacy, hihilingin sa iyong basahin at tanggapin ang bagong bersyon bago ka makapagpatuloy sa paggamit ng app.',
      )),

      _SectionTitle(
          t(context, '2. Purpose of IGNIS SAFE', '2. Layunin ng IGNIS SAFE')),
      _BodyText(t(
        context,
        'IGNIS SAFE is a fire-safety learning and assessment application developed as an academic capstone project in partnership with the BFP R4A Dasmariñas City Fire Station. It provides:\n\n• Learning modules on fire prevention and response;\n• Pre-assessments and post-assessments that measure what you learned;\n• Optional interactive 3D simulations;\n• A record of your own progress and scores.\n\nIGNIS SAFE is an educational tool. It is not an emergency service, it does not dispatch responders, and it must never be relied on during an actual fire. In case of fire, call the BFP R4A Dasmariñas City Fire Station or your local emergency hotline immediately.',
        'Ang IGNIS SAFE ay isang application para sa pag-aaral at pagtatasa ng kaligtasan sa sunog na binuo bilang akademikong capstone project kasama ang BFP R4A Dasmariñas City Fire Station. Nagbibigay ito ng:\n\n• Mga modyul sa pag-iwas at pagtugon sa sunog;\n• Mga pre-assessment at post-assessment na sumusukat sa iyong natutunan;\n• Opsyonal na interactive na 3D simulation;\n• Talaan ng iyong sariling progreso at mga marka.\n\nAng IGNIS SAFE ay kagamitang pang-edukasyon. Hindi ito serbisyong pang-emerhensiya, hindi ito nagpapadala ng mga tagatugon, at hindi ito dapat asahan sa panahon ng tunay na sunog. Sa kaso ng sunog, tumawag agad sa BFP R4A Dasmariñas City Fire Station o sa lokal na hotline ng emerhensiya.',
      )),

      _SectionTitle(t(context, '3. Account Registration and Authentication',
          '3. Pagpaparehistro at Pagpapatunay ng Account')),
      _BodyText(t(
        context,
        'To use IGNIS SAFE you must create an account. You may register with your name, email address, and a password, or sign in with Google.\n\n• Accounts are created and authenticated through Supabase Auth. Your password is stored by Supabase in hashed form; the IGNIS SAFE team cannot read it.\n• Email verification uses a one-time code (OTP) sent to the email address you provide.\n• If you sign in with Google, you authenticate on Google\'s own pages. IGNIS SAFE never sees or stores your Google password.\n• You are responsible for the accuracy of the details you register and for keeping your credentials confidential. Activity carried out through your account is treated as your own.\n• An administrator may deactivate an account; a deactivated account cannot sign in.',
        'Upang magamit ang IGNIS SAFE, kailangan mong lumikha ng account. Maaari kang magparehistro gamit ang iyong pangalan, email address, at password, o mag-sign in gamit ang Google.\n\n• Ang mga account ay nililikha at pinapatunayan sa pamamagitan ng Supabase Auth. Ang iyong password ay iniimbak ng Supabase sa hashed na anyo; hindi ito mababasa ng koponan ng IGNIS SAFE.\n• Ang pag-verify ng email ay gumagamit ng one-time code (OTP) na ipinapadala sa email address na ibinigay mo.\n• Kung mag-sign in ka gamit ang Google, sa mismong pahina ng Google ka nagpapatunay. Hindi nakikita o iniimbak ng IGNIS SAFE ang iyong password sa Google.\n• Ikaw ang may pananagutan sa katumpakan ng mga detalyeng irerehistro mo at sa pagpapanatiling kumpidensyal ng iyong mga kredensyal. Ang aktibidad na isinasagawa sa iyong account ay ituturing na sa iyo.\n• Maaaring i-deactivate ng administrator ang isang account; hindi makakapag-sign in ang na-deactivate na account.',
      )),

      _SectionTitle(t(context, '4. User Responsibilities',
          '4. Mga Responsibilidad ng Gumagamit')),
      _BodyText(t(
        context,
        'When using IGNIS SAFE you agree to:\n\n• Provide true and accurate registration details;\n• Use the app only for lawful fire-safety learning and assessment;\n• Answer assessments honestly and on your own;\n• Keep your password private, and not share or transfer your account;\n• Respect other users and the administrators of the system;\n• Report any security problem or suspicious account activity to the contacts in Section 23.',
        'Sa paggamit ng IGNIS SAFE, sumasang-ayon kang:\n\n• Magbigay ng totoo at tumpak na detalye sa pagpaparehistro;\n• Gamitin ang app para lamang sa legal na pag-aaral at pagtatasa ng kaligtasan sa sunog;\n• Sagutin ang mga pagtatasa nang tapat at nang mag-isa;\n• Panatilihing pribado ang iyong password, at huwag ibahagi o ilipat ang iyong account;\n• Igalang ang ibang gumagamit at ang mga administrator ng sistema;\n• Iulat ang anumang problema sa seguridad o kahina-hinalang aktibidad sa account sa mga contact sa Seksyon 23.',
      )),

      _SectionTitle(t(context, '5. Fire-Safety Training Disclaimer',
          '5. Paunawa Hinggil sa Pagsasanay sa Kaligtasan sa Sunog')),
      _BodyText(t(
        context,
        'The learning materials, assessments, and simulations in IGNIS SAFE are for awareness and education only.\n\n• Completing a module, passing an assessment, or finishing a simulation does not certify you as a fire-safety practitioner and does not substitute for hands-on training, drills, or certification conducted by the Bureau of Fire Protection or another competent authority.\n• The content is general. It cannot account for the specific conditions of your home, workplace, or building.\n• Always follow the instructions of fire officers, building safety officers, and official emergency procedures over anything shown in this app.\n• To the extent permitted by law, IGNIS SAFE and its developers are not liable for injury, loss, or damage arising from reliance on the app during a real emergency.',
        'Ang mga materyal sa pag-aaral, pagtatasa, at simulation sa IGNIS SAFE ay para lamang sa kamalayan at edukasyon.\n\n• Ang pagtatapos ng modyul, pagpasa sa pagtatasa, o pagkumpleto ng simulation ay hindi nagpapatunay na ikaw ay isang fire-safety practitioner at hindi kapalit ng aktwal na pagsasanay, drills, o sertipikasyon na isinasagawa ng Bureau of Fire Protection o iba pang may kakayahang awtoridad.\n• Pangkalahatan ang nilalaman. Hindi nito maisasaalang-alang ang partikular na kalagayan ng iyong tahanan, lugar ng trabaho, o gusali.\n• Palaging sundin ang mga tagubilin ng mga fire officer, building safety officer, at opisyal na pamamaraan sa emerhensiya kaysa sa anumang ipinapakita sa app na ito.\n• Hanggang sa pinahihintulutan ng batas, hindi mananagot ang IGNIS SAFE at ang mga developer nito sa pinsala, pagkawala, o danyos na dulot ng pag-asa sa app sa panahon ng tunay na emerhensiya.',
      )),

      _SectionTitle(t(context, '6. Pre/Post Assessment and Training Records',
          '6. Pre/Post Assessment at mga Talaan ng Pagsasanay')),
      _BodyText(t(
        context,
        'IGNIS SAFE records your assessment activity so that your progress can be measured and shown back to you. For each attempt the system stores the module and assessment taken, the time you started and submitted, the status of the attempt, your score, the number of correct answers, the total number of questions, and the option you selected for each question.\n\nModule progress records which learning material you have read and when your pre-test, simulation, and post-test were completed, together with your pre-test and post-test scores and the improvement between them.\n\nThese records are linked to your account and can be seen by authorized administrators (see Section 10). Assessment results measure knowledge at a point in time only; they are not a professional evaluation of your competence.',
        'Itinatala ng IGNIS SAFE ang iyong aktibidad sa pagtatasa upang masukat at maipakita sa iyo ang iyong progreso. Para sa bawat pagsubok, iniimbak ng sistema ang modyul at pagtatasang kinuha, ang oras ng pagsisimula at pagsusumite, ang katayuan ng pagsubok, ang iyong marka, ang bilang ng tamang sagot, ang kabuuang bilang ng tanong, at ang opsyong pinili mo sa bawat tanong.\n\nItinatala ng module progress kung aling materyal sa pag-aaral ang nabasa mo at kung kailan natapos ang iyong pre-test, simulation, at post-test, kasama ang iyong marka sa pre-test at post-test at ang pag-angat sa pagitan ng mga ito.\n\nNakaugnay ang mga talaang ito sa iyong account at nakikita ng mga awtorisadong administrator (tingnan ang Seksyon 10). Sinusukat lamang ng mga resulta ng pagtatasa ang kaalaman sa isang takdang panahon; hindi ito propesyonal na ebalwasyon ng iyong kakayahan.',
      )),

      _SectionTitle(t(context, '7. Optional 3D Simulation Disclaimer',
          '7. Paunawa Hinggil sa Opsyonal na 3D Simulation')),
      _BodyText(t(
        context,
        'Some modules include an optional interactive 3D simulation built with the Unity engine, which is embedded in the app and runs on your device.\n\n• Simulations are simplified models. Real fires behave differently: they spread faster, produce disabling smoke and heat, and are far less predictable.\n• Performing well in a simulation does not mean you are prepared to fight a real fire. In most real fires the correct response is to alert others, evacuate, and call the fire service.\n• Simulations may cause discomfort on some devices, such as motion discomfort or eye strain. Stop if you feel unwell.\n• Simulations are optional. You can complete the learning modules and assessments without them.\n• The app records that you started and finished a simulation attempt, its status, and its score. It does not send your personal data to Unity.',
        'May ilang modyul na kinabibilangan ng opsyonal na interactive na 3D simulation na gawa sa Unity engine, na nakapaloob sa app at tumatakbo sa iyong device.\n\n• Ang mga simulation ay pinasimpleng modelo. Iba ang kilos ng tunay na sunog: mas mabilis kumalat, may nakakapanghinang usok at init, at higit na mahirap hulaan.\n• Ang mahusay na pagganap sa simulation ay hindi nangangahulugang handa ka nang labanan ang tunay na sunog. Sa karamihan ng tunay na sunog, ang tamang tugon ay bigyang-alam ang iba, lumikas, at tumawag sa serbisyong pangsunog.\n• Maaaring magdulot ng pagkahilo o pangangalay ng mata ang simulation sa ilang device. Huminto kung hindi ka maayos ang pakiramdam.\n• Opsyonal ang mga simulation. Maaari mong tapusin ang mga modyul at pagtatasa nang wala ang mga ito.\n• Itinatala ng app na sinimulan at natapos mo ang isang simulation attempt, ang katayuan nito, at ang marka nito. Hindi nito ipinapadala ang iyong personal na datos sa Unity.',
      )),

      // ---------------- PART II ----------------
      _PartBanner(t(context, 'PART II — PRIVACY NOTICE (RA 10173)',
          'BAHAGI II — PAUNAWA SA PRIVACY (RA 10173)')),

      _SectionTitle(t(context, '8. Personal Data Collected',
          '8. Personal na Datos na Kinokolekta')),
      _BodyText(t(
        context,
        'IGNIS SAFE processes only the data described below.\n\nAccount and profile: first name, last name, email address, username (if set), profile photo (only if you choose to upload one), preferred app language, account status, registration status, and your consent records.\n\nAuthentication data held by Supabase Auth: your email address, your password in hashed form, email-verification and one-time-code status, and session tokens. If you use Google Sign-In, the email address and basic profile information released by your Google account.\n\nLearning and assessment data: assessment attempts (module, assessment, start and submission time, status, score, correct answers, total questions), the option you selected for each question and whether it was correct or flagged, module progress and completion timestamps, and the improvement between your pre-test and post-test.\n\nSimulation data: simulation attempt records (module, start and submission time, status, score).\n\nTechnical data: the app version installed on your device (used to check for updates), settings stored locally on your device such as your language and onboarding state, and the standard service logs kept by Supabase when the app connects to it.\n\nThe IGNIS SAFE mobile app does not collect your precise location, does not use face recognition or other biometric data, and does not read your contacts or messages. It accesses your camera or photo gallery only if you choose to set a profile picture. Sensitive personal information as defined in RA 10173 is not intentionally collected — please do not type such information into free-text fields.',
        'Ang IGNIS SAFE ay nagpoproseso lamang ng datos na inilalarawan sa ibaba.\n\nAccount at profile: pangalan, apelyido, email address, username (kung mayroon), larawan sa profile (kung pipiliin mong mag-upload), piniling wika ng app, katayuan ng account, katayuan ng pagpaparehistro, at ang mga talaan ng iyong pahintulot.\n\nDatos ng pagpapatunay na hawak ng Supabase Auth: ang iyong email address, ang iyong password sa hashed na anyo, ang katayuan ng pag-verify ng email at one-time code, at ang mga session token. Kung gumamit ka ng Google Sign-In, ang email address at pangunahing impormasyon sa profile na ibinibigay ng iyong Google account.\n\nDatos sa pag-aaral at pagtatasa: mga assessment attempt (modyul, pagtatasa, oras ng simula at pagsusumite, katayuan, marka, tamang sagot, kabuuang tanong), ang opsyong pinili mo sa bawat tanong at kung tama o na-flag ito, ang progreso sa modyul at mga oras ng pagkumpleto, at ang pag-angat sa pagitan ng iyong pre-test at post-test.\n\nDatos ng simulation: mga talaan ng simulation attempt (modyul, oras ng simula at pagsusumite, katayuan, marka).\n\nTeknikal na datos: ang bersyon ng app na naka-install sa iyong device (ginagamit sa pagsuri ng update), mga setting na nakaimbak sa iyong device tulad ng wika at katayuan ng onboarding, at ang karaniwang service logs na iniingatan ng Supabase kapag kumokonekta ang app dito.\n\nAng IGNIS SAFE mobile app ay hindi nangongolekta ng iyong tiyak na lokasyon, hindi gumagamit ng face recognition o iba pang biometric na datos, at hindi bumabasa ng iyong mga contact o mensahe. Ina-access lamang nito ang iyong camera o photo gallery kung pipiliin mong maglagay ng larawan sa profile. Hindi sinasadyang kinokolekta ang sensitibong personal na impormasyon ayon sa depinisyon ng RA 10173 — huwag pong ilagay ang ganoong impormasyon sa mga free-text na patlang.',
      )),

      _SectionTitle(t(context, '9. Purpose and Lawful Basis of Processing',
          '9. Layunin at Legal na Batayan ng Pagproseso')),
      _BodyText(t(
        context,
        'Your personal data is processed for the following purposes, on the lawful bases set out in Section 12 of RA 10173:\n\n• Creating and securing your account, delivering the modules, assessments, and simulations, and showing your own progress — necessary for the service you asked for (Sec. 12(b)) and your consent (Sec. 12(a)).\n• Recording assessment results and training records so that authorized BFP administrators can monitor, evaluate, and report on fire-safety training — your consent (Sec. 12(a)) and the legitimate interests of the project and its BFP partner (Sec. 12(f)).\n• Keeping the system secure, preventing abuse, and diagnosing faults — legitimate interests (Sec. 12(f)).\n• Recording your consent and complying with legal obligations — Sec. 12(c).\n• Research and statistical use — only in aggregated or de-identified form, or, for identifiable data, on the separate consent in Part V (Sec. 12(a)).\n\nWe do not use your personal data for advertising, and we do not sell it.',
        'Ang iyong personal na datos ay pinoproseso para sa mga sumusunod na layunin, batay sa mga legal na batayan sa Seksyon 12 ng RA 10173:\n\n• Paglikha at pag-secure ng iyong account, paghahatid ng mga modyul, pagtatasa, at simulation, at pagpapakita ng iyong sariling progreso — kailangan para sa serbisyong hiniling mo (Sek. 12(b)) at sa iyong pahintulot (Sek. 12(a)).\n• Pagtatala ng mga resulta ng pagtatasa at talaan ng pagsasanay upang masubaybayan, masuri, at maiulat ng mga awtorisadong administrator ng BFP ang pagsasanay sa kaligtasan sa sunog — ang iyong pahintulot (Sek. 12(a)) at ang lehitimong interes ng proyekto at ng kapartner nitong BFP (Sek. 12(f)).\n• Pagpapanatili ng seguridad ng sistema, pag-iwas sa pang-aabuso, at pagsusuri ng mga depekto — lehitimong interes (Sek. 12(f)).\n• Pagtatala ng iyong pahintulot at pagsunod sa mga legal na obligasyon — Sek. 12(c).\n• Paggamit sa pananaliksik at estadistika — sa pinagsama-sama o de-identified na anyo lamang, o, para sa datos na nakikilala, sa hiwalay na pahintulot sa Bahagi V (Sek. 12(a)).\n\nHindi namin ginagamit ang iyong personal na datos para sa advertising, at hindi namin ito ipinagbibili.',
      )),

      _SectionTitle(t(context, '10. Who May Access the Data',
          '10. Sino ang Maaaring Mag-access ng Datos')),
      _BodyText(t(
        context,
        '• You — your profile, progress, and assessment history are always visible to you in the app.\n• Authorized IGNIS SAFE administrators — personnel of the BFP R4A Dasmariñas City Fire Station who hold administrator accounts may view learner profiles, training progress, and assessment results through the IGNIS SAFE admin dashboard, for monitoring, evaluation, and official reporting.\n• The IGNIS SAFE project team — the student developers and their academic adviser named in Section 23, on a need-to-know basis, for maintenance, technical support, and correcting faults.\n• Supabase — as our service provider (personal information processor) hosting the database, authentication, storage, and server functions.\n\nDatabase access is restricted by row-level security policies, so a learner account can read and change only its own records. Other learners cannot see your data.',
        '• Ikaw — ang iyong profile, progreso, at kasaysayan ng pagtatasa ay palaging nakikita mo sa app.\n• Mga awtorisadong administrator ng IGNIS SAFE — ang mga tauhan ng BFP R4A Dasmariñas City Fire Station na may administrator account ay maaaring tingnan ang mga profile ng mag-aaral, progreso sa pagsasanay, at mga resulta ng pagtatasa sa pamamagitan ng IGNIS SAFE admin dashboard, para sa pagsubaybay, ebalwasyon, at opisyal na pag-uulat.\n• Ang koponan ng proyektong IGNIS SAFE — ang mga estudyanteng developer at ang kanilang akademikong tagapayo na nakalista sa Seksyon 23, batay sa pangangailangang malaman, para sa pagpapanatili, teknikal na suporta, at pagwawasto ng depekto.\n• Supabase — bilang aming service provider (personal information processor) na nagho-host ng database, pagpapatunay, imbakan, at mga server function.\n\nNililimitahan ng row-level security policies ang pag-access sa database, kaya ang isang learner account ay makakabasa at makakapagbago lamang ng sarili nitong mga talaan. Hindi nakikita ng ibang mag-aaral ang iyong datos.',
      )),

      _SectionTitle(t(context, '11. Third-Party Services Used',
          '11. Mga Serbisyo ng Third Party na Ginagamit')),
      _BodyText(t(
        context,
        'IGNIS SAFE relies on the following third-party services:\n\n• Supabase — authentication, database, file storage for profile photos, and server-side functions. The IGNIS SAFE database is hosted in the Supabase region ap-south-1, which means your personal data is stored on servers outside the Philippines. Under RA 10173, the IGNIS SAFE project remains accountable for your personal data even when it is transferred abroad.\n• Google Sign-In (Google LLC) — optional, used only if you choose to sign in with Google. Google authenticates you and releases your email address and basic profile information to IGNIS SAFE. IGNIS SAFE never receives your Google password.\n• Unity — the 3D simulation engine embedded in the app. Simulations run locally on your device; the app does not transmit your personal data to Unity.\n• Your device app store (for example Google Play) — used to install and update the app, under its own terms and privacy policy.\n\nEach provider processes data under its own terms and privacy policy.',
        'Umaasa ang IGNIS SAFE sa mga sumusunod na serbisyo ng third party:\n\n• Supabase — pagpapatunay, database, imbakan ng file para sa mga larawan sa profile, at mga server-side function. Ang database ng IGNIS SAFE ay naka-host sa rehiyong ap-south-1 ng Supabase, na nangangahulugang ang iyong personal na datos ay nakaimbak sa mga server sa labas ng Pilipinas. Sa ilalim ng RA 10173, nananatiling may pananagutan ang proyektong IGNIS SAFE sa iyong personal na datos kahit ito ay ipinadala sa ibang bansa.\n• Google Sign-In (Google LLC) — opsyonal, ginagamit lamang kung pipiliin mong mag-sign in gamit ang Google. Pinapatunayan ka ng Google at ibinibigay nito sa IGNIS SAFE ang iyong email address at pangunahing impormasyon sa profile. Hindi kailanman natatanggap ng IGNIS SAFE ang iyong password sa Google.\n• Unity — ang 3D simulation engine na nakapaloob sa app. Tumatakbo ang mga simulation sa iyong device; hindi ipinapadala ng app ang iyong personal na datos sa Unity.\n• Ang app store ng iyong device (halimbawa Google Play) — ginagamit sa pag-install at pag-update ng app, sa ilalim ng sarili nitong mga tuntunin at patakaran sa privacy.\n\nAng bawat provider ay nagpoproseso ng datos sa ilalim ng sarili nitong mga tuntunin at patakaran sa privacy.',
      )),

      _SectionTitle(t(context, '12. Data Sharing and Disclosure',
          '12. Pagbabahagi at Paglalahad ng Datos')),
      _BodyText(t(
        context,
        'We do not sell, rent, or trade your personal data, and we do not share it for advertising.\n\nYour personal data may be disclosed only:\n\n• to the authorized administrators and project team described in Section 10;\n• to the service providers in Section 11, strictly to operate the app;\n• in aggregated or de-identified form in academic reports, presentations, and the capstone manuscript, where individual learners cannot be identified;\n• in identifiable form for research, only if you gave the separate research consent in Part V;\n• when required by law, a court order, or a lawful request from a government authority.',
        'Hindi namin ipinagbibili, inuupahan, o ipinagpapalit ang iyong personal na datos, at hindi namin ito ibinabahagi para sa advertising.\n\nAng iyong personal na datos ay maaaring ilahad lamang:\n\n• sa mga awtorisadong administrator at sa koponan ng proyekto na inilarawan sa Seksyon 10;\n• sa mga service provider sa Seksyon 11, para lamang mapatakbo ang app;\n• sa pinagsama-sama o de-identified na anyo sa mga akademikong ulat, presentasyon, at manuskrito ng capstone, kung saan hindi makikilala ang bawat mag-aaral;\n• sa nakikilalang anyo para sa pananaliksik, kung nagbigay ka lamang ng hiwalay na pahintulot sa pananaliksik sa Bahagi V;\n• kapag iniaatas ng batas, ng utos ng hukuman, o ng legal na kahilingan mula sa awtoridad ng pamahalaan.',
      )),

      _SectionTitle(t(context, '13. Data Retention', '13. Pag-iingat ng Datos')),
      _BodyText(t(
        context,
        'Your account and learning records are kept for as long as your account is active and for as long as they are needed for the purposes in Section 9.\n\nConsent records are kept for as long as necessary to show that consent was given, and are preserved even after a consent is withdrawn, because the record of the withdrawal is itself evidence.\n\nData used for the capstone research is kept until the research is completed, evaluated, and archived as required by the academic institution.\n\nIGNIS SAFE does not state a fixed number of years here, because the final retention schedule is set by the BFP partner and the academic institution deploying the system. You may ask for the retention period that applies to you using the contacts in Section 23, and you may request deletion of your data at any time (Section 15), subject to records that must be kept by law or for the integrity of official training reports.',
        'Ang iyong account at mga talaan sa pag-aaral ay iniingatan hangga\'t aktibo ang iyong account at hangga\'t kailangan ang mga ito para sa mga layunin sa Seksyon 9.\n\nAng mga talaan ng pahintulot ay iniingatan hangga\'t kinakailangan upang mapatunayang ibinigay ang pahintulot, at pinapanatili kahit matapos bawiin ang isang pahintulot, dahil ang talaan mismo ng pagbawi ay katibayan.\n\nAng datos na ginagamit sa capstone research ay iniingatan hanggang matapos, masuri, at maiarkibo ang pananaliksik ayon sa hinihingi ng institusyong akademiko.\n\nHindi nagsasaad ang IGNIS SAFE ng tiyak na bilang ng taon dito, dahil ang panghuling retention schedule ay itinatakda ng kapartner na BFP at ng institusyong akademiko na nagpapatupad ng sistema. Maaari mong itanong ang panahon ng pag-iingat na naaangkop sa iyo gamit ang mga contact sa Seksyon 23, at maaari kang humiling ng pagbura ng iyong datos anumang oras (Seksyon 15), maliban sa mga talaang kailangang itago ayon sa batas o para sa integridad ng opisyal na ulat ng pagsasanay.',
      )),

      _SectionTitle(t(context, '14. Data Security and Breach Handling',
          '14. Seguridad ng Datos at Pagharap sa Paglabag')),
      _BodyText(t(
        context,
        'IGNIS SAFE applies the following organizational and technical measures:\n\n• Traffic between the app and Supabase is encrypted in transit (HTTPS/TLS).\n• Passwords are hashed by Supabase Auth and are never stored or visible in plain text.\n• Email verification through one-time codes.\n• Row-level security policies in the database, so each learner account can access only its own records, and administrator access is limited to active administrator accounts.\n• Access on a need-to-know basis for the project team.\n\nNo system can be guaranteed completely secure. IGNIS SAFE does not claim to be "100% secure" or automatically fully compliant with every requirement; security measures are reviewed and improved as the project develops.\n\nIf a personal data breach occurs, we will act promptly and take reasonable steps to limit the harm. Where the breach involves sensitive personal information, or information that may enable identity fraud, and there is a real risk of serious harm, the incident will be reported to the National Privacy Commission and to the affected data subjects within seventy-two (72) hours from knowledge of the breach, as required by RA 10173 and NPC Circular No. 16-03.',
        'Nagpapatupad ang IGNIS SAFE ng mga sumusunod na organisasyonal at teknikal na hakbang:\n\n• Ang komunikasyon sa pagitan ng app at Supabase ay naka-encrypt habang isinasalin (HTTPS/TLS).\n• Ang mga password ay hina-hash ng Supabase Auth at hindi kailanman iniimbak o nakikita sa plain text.\n• Pag-verify ng email sa pamamagitan ng one-time code.\n• Row-level security policies sa database, kaya ang bawat learner account ay maa-access lamang ang sarili nitong mga talaan, at limitado ang access ng administrator sa mga aktibong administrator account.\n• Access batay sa pangangailangang malaman para sa koponan ng proyekto.\n\nWalang sistemang maaaring garantiyahang ganap na ligtas. Hindi inaangkin ng IGNIS SAFE na ito ay "100% secure" o awtomatikong ganap na sumusunod sa bawat kinakailangan; sinusuri at pinapabuti ang mga hakbang sa seguridad habang umuunlad ang proyekto.\n\nKung may mangyaring paglabag sa personal na datos, agad kaming kikilos at gagawa ng makatwirang hakbang upang malimitahan ang pinsala. Kung ang paglabag ay may kinalaman sa sensitibong personal na impormasyon, o impormasyong maaaring magbigay-daan sa pandaraya sa pagkakakilanlan, at may tunay na panganib ng malubhang pinsala, iuulat ang insidente sa National Privacy Commission at sa mga apektadong data subject sa loob ng pitumpu\'t dalawang (72) oras mula sa pagkaalam ng paglabag, ayon sa hinihingi ng RA 10173 at NPC Circular Blg. 16-03.',
      )),

      _SectionTitle(t(context, '15. Your Rights as a Data Subject',
          '15. Ang Iyong mga Karapatan bilang Data Subject')),
      _BodyText(t(
        context,
        'Under RA 10173 you have the following rights over your personal data:\n\n• Right to be informed — to know that your personal data is being or will be processed, and for what purpose. This notice serves that purpose.\n• Right to access — to obtain a copy of the personal data held about you and details of how it is processed. Your profile, progress, and assessment history are also visible in the app at any time.\n• Right to object — to object to the processing of your personal data, including processing based on consent or legitimate interests, and to withdraw consent. Objecting to processing that is essential to the app means the account can no longer be provided.\n• Right to rectification — to correct inaccurate or out-of-date personal data. You can update your name, email address, and profile photo yourself in Profile then Edit Profile, or ask us to correct anything else.\n• Right to erasure or blocking — to ask that your personal data be removed or blocked where it is incomplete, outdated, false, unlawfully obtained, or no longer necessary, subject to records that must be kept by law.\n• Right to data portability — to obtain your personal data in an electronic, structured, and commonly used format so you can move it elsewhere.\n• Right to file a complaint — to complain to the National Privacy Commission if you believe your rights have been violated (privacy.gov.ph).\n• Right to damages — to be indemnified for damages sustained due to inaccurate, incomplete, outdated, false, unlawfully obtained, or unauthorized use of your personal data, as provided by law.\n\nTo exercise any of these rights, contact us using Section 23. We will verify your identity before acting on a request, and will respond within a reasonable period.',
        'Sa ilalim ng RA 10173, mayroon kang mga sumusunod na karapatan sa iyong personal na datos:\n\n• Karapatang mabatid — malaman na ang iyong personal na datos ay pinoproseso o pipoprosesuhin, at kung para saan. Ito ang layunin ng paunawang ito.\n• Karapatang ma-access — makakuha ng kopya ng personal na datos na hawak tungkol sa iyo at ng mga detalye kung paano ito pinoproseso. Nakikita mo rin ang iyong profile, progreso, at kasaysayan ng pagtatasa sa app anumang oras.\n• Karapatang tumutol — tumutol sa pagproseso ng iyong personal na datos, kabilang ang pagprosesong nakabatay sa pahintulot o lehitimong interes, at bawiin ang pahintulot. Ang pagtutol sa pagprosesong mahalaga sa app ay nangangahulugang hindi na maibibigay ang account.\n• Karapatang magwasto — iwasto ang hindi tumpak o lipas na personal na datos. Maaari mong i-update ang iyong pangalan, email address, at larawan sa profile sa Profile at pagkatapos ay Edit Profile, o hilingin sa amin na iwasto ang iba pa.\n• Karapatang magpabura o magpaharang — hilingin na alisin o harangin ang iyong personal na datos kung ito ay hindi kumpleto, lipas, mali, ilegal na nakuha, o hindi na kailangan, maliban sa mga talaang kailangang itago ayon sa batas.\n• Karapatan sa data portability — makuha ang iyong personal na datos sa elektroniko, istrukturado, at karaniwang ginagamit na format upang mailipat mo ito sa ibang lugar.\n• Karapatang maghain ng reklamo — magreklamo sa National Privacy Commission kung sa palagay mo ay nilabag ang iyong mga karapatan (privacy.gov.ph).\n• Karapatan sa danyos — mabayaran sa danyos na natamo dahil sa hindi tumpak, hindi kumpleto, lipas, mali, ilegal na nakuha, o hindi awtorisadong paggamit ng iyong personal na datos, ayon sa itinatakda ng batas.\n\nUpang gamitin ang alinman sa mga karapatang ito, makipag-ugnayan sa amin sa pamamagitan ng Seksyon 23. Bibigyang-patunay namin ang iyong pagkakakilanlan bago kumilos sa kahilingan, at tutugon kami sa loob ng makatwirang panahon.',
      )),

      _SectionTitle(
          t(context, '16. Withdrawal of Consent', '16. Pagbawi ng Pahintulot')),
      _BodyText(t(
        context,
        'You may withdraw your consent at any time.\n\n• Research consent (Part V) may be withdrawn at any time. Withdrawing it does not affect your access to the app, your scores, or your standing in any training programme.\n• Consent to the processing described in this Privacy Notice may also be withdrawn, but that processing is necessary to operate your account. If you withdraw it, we will treat your request as a request to close your account and delete or anonymize your data, subject to Section 13.\n\nTo withdraw, contact us using Section 23. Withdrawal takes effect going forward; it does not undo processing that already lawfully took place. Your withdrawal is recorded in your consent history with the date and time.',
        'Maaari mong bawiin ang iyong pahintulot anumang oras.\n\n• Ang pahintulot sa pananaliksik (Bahagi V) ay maaaring bawiin anumang oras. Hindi nito naaapektuhan ang iyong access sa app, ang iyong mga marka, o ang iyong katayuan sa anumang programa ng pagsasanay.\n• Ang pahintulot sa pagprosesong inilarawan sa Paunawa sa Privacy na ito ay maaari ring bawiin, ngunit kailangan ang pagprosesong iyon upang mapatakbo ang iyong account. Kung babawiin mo ito, ituturing naming kahilingan ito na isara ang iyong account at burahin o gawing anonymous ang iyong datos, alinsunod sa Seksyon 13.\n\nUpang bumawi, makipag-ugnayan sa amin sa pamamagitan ng Seksyon 23. Ang pagbawi ay may bisa sa hinaharap; hindi nito binabaligtad ang pagprosesong legal nang naisagawa. Ang iyong pagbawi ay itinatala sa kasaysayan ng iyong pahintulot kasama ang petsa at oras.',
      )),

      _SectionTitle(t(context, '17. Research and Statistical Use',
          '17. Paggamit sa Pananaliksik at Estadistika')),
      _BodyText(t(
        context,
        'IGNIS SAFE is an academic capstone project, so results are studied to evaluate whether the app improves fire-safety knowledge.\n\n• For ordinary reporting and evaluation, only aggregated or de-identified data is used — for example average pre-test and post-test scores, completion rates, and improvement across a group. Individual learners are not identified in these outputs.\n• Use of your individual, identifiable learning data for the capstone research requires the separate Research Consent in Part V. That consent is optional and is not part of accepting these Terms.\n\nIf you do not give research consent, you can still use every feature of IGNIS SAFE.',
        'Ang IGNIS SAFE ay isang akademikong capstone project, kaya pinag-aaralan ang mga resulta upang masuri kung napapabuti ng app ang kaalaman sa kaligtasan sa sunog.\n\n• Para sa karaniwang pag-uulat at ebalwasyon, pinagsama-sama o de-identified na datos lamang ang ginagamit — halimbawa, katamtamang marka sa pre-test at post-test, antas ng pagkumpleto, at pag-angat ng isang pangkat. Hindi nakikilala ang bawat mag-aaral sa mga resultang ito.\n• Ang paggamit ng iyong indibidwal at nakikilalang datos sa pag-aaral para sa capstone research ay nangangailangan ng hiwalay na Pahintulot sa Pananaliksik sa Bahagi V. Opsyonal ang pahintulot na iyon at hindi bahagi ng pagtanggap sa Mga Tuntuning ito.\n\nKung hindi ka magbibigay ng pahintulot sa pananaliksik, magagamit mo pa rin ang lahat ng tampok ng IGNIS SAFE.',
      )),

      // ---------------- PART III ----------------
      _PartBanner(t(context, 'PART III — GENERAL TERMS',
          'BAHAGI III — PANGKALAHATANG TUNTUNIN')),

      _SectionTitle(t(context, '18. Intellectual Property',
          '18. Intelektwal na Ari-arian')),
      _BodyText(t(
        context,
        'The IGNIS SAFE name and logo, the learning materials, assessment items, 3D models, simulations, graphics, video, text, and software are owned by the IGNIS SAFE project team or their respective licensors, and are protected by Philippine intellectual property law. Content contributed by the Bureau of Fire Protection remains the property of the BFP.\n\nYou are granted a personal, non-transferable, revocable licence to use the app for your own fire-safety learning. You may not copy, reproduce, redistribute, sell, publish, or create derivative works from the content without written permission, except as allowed by law.',
        'Ang pangalan at logo ng IGNIS SAFE, ang mga materyal sa pag-aaral, mga aytem sa pagtatasa, 3D models, simulation, graphics, video, teksto, at software ay pag-aari ng koponan ng proyektong IGNIS SAFE o ng kani-kanilang licensor, at protektado ng batas ng Pilipinas sa intelektwal na ari-arian. Ang nilalamang inambag ng Bureau of Fire Protection ay nananatiling pag-aari ng BFP.\n\nBinibigyan ka ng personal, hindi naililipat, at nababawing lisensya upang gamitin ang app para sa sarili mong pag-aaral sa kaligtasan sa sunog. Hindi mo maaaring kopyahin, paramihin, ipamahagi, ipagbili, ilathala, o gawan ng derivative na akda ang nilalaman nang walang nakasulat na pahintulot, maliban kung pinahihintulutan ng batas.',
      )),

      _SectionTitle(t(context, '19. Prohibited Activities',
          '19. Mga Ipinagbabawal na Gawain')),
      _BodyText(t(
        context,
        'You must not:\n\n• Create an account using someone else\'s identity, or share, sell, or transfer your account;\n• Attempt to view, change, or delete another user\'s data;\n• Attempt to gain administrator access, bypass row-level security, or otherwise circumvent authentication;\n• Manipulate, falsify, or automate assessment or simulation results;\n• Reverse-engineer, decompile, or tamper with the app or its database, except where the law expressly permits it;\n• Upload unlawful, offensive, defamatory, or infringing content, including as a profile photo;\n• Introduce malware, or overload, disrupt, or probe the service without authorization;\n• Extract, scrape, or republish the learning materials or assessment items.',
        'Hindi mo dapat:\n\n• Gumawa ng account gamit ang pagkakakilanlan ng iba, o ibahagi, ipagbili, o ilipat ang iyong account;\n• Subukang tingnan, baguhin, o burahin ang datos ng ibang gumagamit;\n• Subukang makakuha ng access bilang administrator, lampasan ang row-level security, o iwasan ang pagpapatunay;\n• Manipulahin, palsipikahin, o i-automate ang mga resulta ng pagtatasa o simulation;\n• I-reverse-engineer, i-decompile, o pakialaman ang app o ang database nito, maliban kung tahasang pinahihintulutan ng batas;\n• Mag-upload ng ilegal, nakakasakit, mapanirang-puri, o lumalabag na nilalaman, pati na bilang larawan sa profile;\n• Maglagay ng malware, o mag-overload, gumambala, o mag-probe sa serbisyo nang walang pahintulot;\n• Kunin, i-scrape, o ilathalang muli ang mga materyal sa pag-aaral o mga aytem sa pagtatasa.',
      )),

      _SectionTitle(t(
          context,
          '20. System Availability, Suspension and Termination',
          '20. Availability ng Sistema, Pagsuspinde at Pagwawakas')),
      _BodyText(t(
        context,
        'IGNIS SAFE is provided on an "as is" and "as available" basis. It is an academic project and may be unavailable during maintenance, updates, network problems, or provider outages, and features may change or be withdrawn. We do not guarantee uninterrupted or error-free operation, and we do not guarantee that data you have not exported will always be recoverable.\n\nYour account may be suspended or deactivated if you breach these Terms, act unlawfully, or misuse the system, or where an administrator determines this is necessary for the integrity of training records. Where reasonably possible you will be told why.\n\nYou may stop using IGNIS SAFE at any time, and may request deletion of your account under Section 15.',
        'Ang IGNIS SAFE ay ibinibigay sa "as is" at "as available" na batayan. Ito ay akademikong proyekto at maaaring hindi magamit sa panahon ng maintenance, update, problema sa network, o pagkaantala ng provider, at maaaring magbago o matanggal ang mga tampok. Hindi namin ginagarantiyahan ang walang patid o walang error na operasyon, at hindi namin ginagarantiyahan na palaging mababawi ang datos na hindi mo na-export.\n\nMaaaring suspindihin o i-deactivate ang iyong account kung lalabag ka sa Mga Tuntuning ito, kikilos nang labag sa batas, o gagamitin nang mali ang sistema, o kung matukoy ng administrator na kinakailangan ito para sa integridad ng mga talaan ng pagsasanay. Kung makatwirang posible, ipapaalam sa iyo ang dahilan.\n\nMaaari kang tumigil sa paggamit ng IGNIS SAFE anumang oras, at maaaring humiling ng pagbura ng iyong account sa ilalim ng Seksyon 15.',
      )),

      _SectionTitle(t(context, '21. Changes to the Terms and Privacy Notice',
          '21. Mga Pagbabago sa Tuntunin at Paunawa sa Privacy')),
      _BodyText(t(
        context,
        'These Terms and this Privacy Notice may be updated to reflect changes in the app, in our data practices, or in the law.\n\nEach document carries a version number and effective date, shown at the top of this screen. Minor corrections may be made without notice. If we make a material change — for example collecting new categories of personal data, adding a new recipient, or changing the purposes of processing — the new version will be presented to you in the app and you will be asked to read and accept it before continuing. Your previous acceptances are kept as a historical record.',
        'Ang Mga Tuntuning ito at ang Paunawa sa Privacy na ito ay maaaring i-update upang ipakita ang mga pagbabago sa app, sa aming mga gawi sa datos, o sa batas.\n\nAng bawat dokumento ay may numero ng bersyon at petsa ng bisa, na makikita sa itaas ng screen na ito. Ang mga menor na pagwawasto ay maaaring gawin nang walang paunawa. Kung may gagawing mahalagang pagbabago — halimbawa, pagkolekta ng bagong uri ng personal na datos, pagdaragdag ng bagong tatanggap, o pagbabago sa mga layunin ng pagproseso — ipapakita sa iyo sa app ang bagong bersyon at hihilingin sa iyong basahin at tanggapin ito bago magpatuloy. Ang iyong mga naunang pagtanggap ay iniingatan bilang makasaysayang talaan.',
      )),

      _SectionTitle(t(context, '22. Governing Law', '22. Namamahalang Batas')),
      _BodyText(t(
        context,
        'These Terms and this Privacy Notice are governed by the laws of the Republic of the Philippines, including the Data Privacy Act of 2012 (RA 10173) and its Implementing Rules and Regulations. Any dispute that cannot be settled amicably shall be brought before the proper courts of the Philippines, without prejudice to your right to complain to the National Privacy Commission.',
        'Ang Mga Tuntuning ito at ang Paunawa sa Privacy na ito ay pinamamahalaan ng mga batas ng Republika ng Pilipinas, kabilang ang Data Privacy Act of 2012 (RA 10173) at ang Implementing Rules and Regulations nito. Ang anumang alitan na hindi maaayos nang mapayapa ay dadalhin sa nararapat na hukuman ng Pilipinas, nang hindi nawawala ang iyong karapatang magreklamo sa National Privacy Commission.',
      )),

      // ---------------- PART IV ----------------
      _PartBanner(t(context, 'PART IV — CONTACT AND COMPLAINTS',
          'BAHAGI IV — PAKIKIPAG-UGNAYAN AT MGA REKLAMO')),

      _SectionTitle(t(context, '23. Privacy and Contact Information',
          '23. Impormasyon sa Privacy at Pakikipag-ugnayan')),
      _BodyText(t(
        context,
        'For questions about these Terms, this Privacy Notice, or your personal data — or to exercise any right in Section 15 or withdraw consent under Section 16 — contact the IGNIS SAFE project team:\n\n• Andrei C. Quias — Project Manager / 3D Unity Developer — andreicarisma24@gmail.com\n• Fatima Klye M. Sierra — Mobile Application and Database — fatimaklyesierra081005@gmail.com\n\nIGNIS SAFE is deployed in partnership with the BFP R4A Dasmariñas City Fire Station, under City Fire Marshal FCINSP Michael John V. Escaño. Station hotlines: (046) 884-6131 / 416-0875 and 0995-336-9534. Please use these hotlines for fire and emergency matters, not for privacy requests.\n\nA separate Data Protection Officer has not been designated for this application; privacy requests are handled by the project team above. If the deploying institution designates a Data Protection Officer, their contact details will be provided on request.\n\nIf you are not satisfied with how your concern was handled, you may complain to the National Privacy Commission through privacy.gov.ph.',
        'Para sa mga tanong tungkol sa Mga Tuntuning ito, sa Paunawa sa Privacy na ito, o sa iyong personal na datos — o upang gamitin ang alinmang karapatan sa Seksyon 15 o bawiin ang pahintulot sa ilalim ng Seksyon 16 — makipag-ugnayan sa koponan ng proyektong IGNIS SAFE:\n\n• Andrei C. Quias — Project Manager / 3D Unity Developer — andreicarisma24@gmail.com\n• Fatima Klye M. Sierra — Mobile Application at Database — fatimaklyesierra081005@gmail.com\n\nAng IGNIS SAFE ay ipinapatupad kasama ang BFP R4A Dasmariñas City Fire Station, sa ilalim ni City Fire Marshal FCINSP Michael John V. Escaño. Mga hotline ng istasyon: (046) 884-6131 / 416-0875 at 0995-336-9534. Gamitin lamang po ang mga hotline na ito para sa usaping sunog at emerhensiya, hindi para sa mga kahilingan tungkol sa privacy.\n\nWalang hiwalay na Data Protection Officer na itinalaga para sa application na ito; ang mga kahilingan tungkol sa privacy ay hinahawakan ng koponan ng proyekto sa itaas. Kung magtatalaga ang institusyong nagpapatupad ng isang Data Protection Officer, ibibigay ang kanilang detalye sa pakikipag-ugnayan kapag hiniling.\n\nKung hindi ka nasiyahan sa paghawak sa iyong alalahanin, maaari kang magreklamo sa National Privacy Commission sa pamamagitan ng privacy.gov.ph.',
      )),

      // ---------------- PART V ----------------
      _PartBanner(t(
        context,
        'PART V — RESEARCH CONSENT (OPTIONAL)',
        'BAHAGI V — PAHINTULOT SA PANANALIKSIK (OPSYONAL)',
      )),
      _NoteBox(t(
        context,
        'This part is optional and is NOT part of the Terms and Conditions. You may decline it and still use every feature of IGNIS SAFE.',
        'Ang bahaging ito ay opsyonal at HINDI bahagi ng Mga Tuntunin at Kundisyon. Maaari mong tanggihan ito at magamit pa rin ang lahat ng tampok ng IGNIS SAFE.',
      )),

      _SectionTitle(t(context, 'Purpose of the Research',
          'Layunin ng Pananaliksik')),
      _BodyText(t(
        context,
        'IGNIS SAFE is being developed and studied as an undergraduate capstone research project. The researchers want to determine whether the application improves users\' knowledge of fire prevention and response, by comparing pre-assessment and post-assessment results and examining how learners move through the modules.',
        'Ang IGNIS SAFE ay binubuo at pinag-aaralan bilang capstone research project sa antas ng kolehiyo. Nais tukuyin ng mga mananaliksik kung napapabuti ng application ang kaalaman ng mga gumagamit sa pag-iwas at pagtugon sa sunog, sa pamamagitan ng paghahambing ng mga resulta ng pre-assessment at post-assessment at pagsusuri kung paano dumadaan ang mga mag-aaral sa mga modyul.',
      )),

      _SectionTitle(
          t(context, 'Data Used in the Research', 'Datos na Gagamitin')),
      _BodyText(t(
        context,
        'Pre-assessment and post-assessment scores and answers, module progress and completion, simulation attempt results, and the language you use the app in. Direct identifiers such as your name, email address, and profile photo are removed or replaced with a code before analysis. No individual score is published.',
        'Mga marka at sagot sa pre-assessment at post-assessment, progreso at pagkumpleto ng modyul, mga resulta ng simulation attempt, at ang wikang ginagamit mo sa app. Ang mga tuwirang pagkakakilanlan tulad ng iyong pangalan, email address, at larawan sa profile ay inaalis o pinapalitan ng code bago ang pagsusuri. Walang indibidwal na marka na inilalathala.',
      )),

      _SectionTitle(
          t(context, 'Voluntary Participation', 'Kusang-loob na Paglahok')),
      _BodyText(t(
        context,
        'Participation is entirely voluntary. If you decline, or later withdraw, you keep full access to IGNIS SAFE, your scores and progress are unaffected, and there is no penalty of any kind.',
        'Ganap na kusang-loob ang paglahok. Kung tatanggi ka, o babawiin mo ito sa bandang huli, mananatili ang buo mong access sa IGNIS SAFE, hindi maaapektuhan ang iyong mga marka at progreso, at walang anumang parusa.',
      )),

      _SectionTitle(t(context, 'Confidentiality', 'Pagiging Kumpidensyal')),
      _BodyText(t(
        context,
        'Research data is stored in the same protected Supabase database described in Section 14 and is accessed only by the people listed below. Analysis is carried out on de-identified data. Nothing that identifies you personally will appear in any report or presentation.',
        'Ang datos ng pananaliksik ay iniimbak sa parehong protektadong Supabase database na inilarawan sa Seksyon 14 at ina-access lamang ng mga taong nakalista sa ibaba. Isinasagawa ang pagsusuri sa de-identified na datos. Walang anumang makakakilala sa iyo nang personal na lalabas sa anumang ulat o presentasyon.',
      )),

      _SectionTitle(
          t(context, 'Risks and Benefits', 'Mga Panganib at Benepisyo')),
      _BodyText(t(
        context,
        'Participation involves minimal risk. The main risk is the small possibility of a data breach affecting confidentiality; the safeguards in Section 14 apply. There is no physical risk. Taking the assessments may cause mild discomfort if you find some questions difficult.\n\nThere is no payment or reward for participating. Participation helps improve fire-safety education for the community served by the BFP R4A Dasmariñas City Fire Station.',
        'Minimal ang panganib sa paglahok. Ang pangunahing panganib ay ang maliit na posibilidad ng paglabag sa datos na makakaapekto sa pagiging kumpidensyal; nalalapat ang mga proteksyon sa Seksyon 14. Walang pisikal na panganib. Maaaring magdulot ng bahagyang pagkabahala ang pagsagot sa mga pagtatasa kung mahirap para sa iyo ang ilang tanong.\n\nWalang bayad o gantimpala sa paglahok. Nakakatulong ang paglahok upang mapabuti ang edukasyon sa kaligtasan sa sunog para sa komunidad na pinaglilingkuran ng BFP R4A Dasmariñas City Fire Station.',
      )),

      _SectionTitle(t(context, 'Researchers with Access',
          'Mga Mananaliksik na May Access')),
      _BodyText(t(
        context,
        'The IGNIS SAFE student research team — Fatima Klye M. Sierra, Andrei C. Quias, Rave Paulo Piolo V. Sierra, and Sarah Flor Macandile; their academic adviser, Maricis Punzalan; and, where required, the panel and academic authorities evaluating the capstone.',
        'Ang koponan ng mga estudyanteng mananaliksik ng IGNIS SAFE — Fatima Klye M. Sierra, Andrei C. Quias, Rave Paulo Piolo V. Sierra, at Sarah Flor Macandile; ang kanilang akademikong tagapayo, si Maricis Punzalan; at, kung kinakailangan, ang panel at mga awtoridad na akademiko na sumusuri sa capstone.',
      )),

      _SectionTitle(t(context, 'Retention of Research Data',
          'Pag-iingat ng Datos ng Pananaliksik')),
      _BodyText(t(
        context,
        'Research data is kept until the capstone is completed, defended, and archived as required by the academic institution, after which it is deleted or kept only in de-identified form.',
        'Ang datos ng pananaliksik ay iniingatan hanggang matapos, maipagtanggol, at maiarkibo ang capstone ayon sa hinihingi ng institusyong akademiko, pagkatapos nito ay buburahin o iingatan lamang sa de-identified na anyo.',
      )),

      _SectionTitle(t(context, 'Publication and Reporting',
          'Paglalathala at Pag-uulat')),
      _BodyText(t(
        context,
        'Results will be reported in the capstone manuscript, in the oral defence and presentations, and possibly in academic publications — always in aggregated or de-identified form.',
        'Iuulat ang mga resulta sa manuskrito ng capstone, sa oral defence at mga presentasyon, at posibleng sa mga akademikong publikasyon — palaging sa pinagsama-sama o de-identified na anyo.',
      )),

      _SectionTitle(t(context, 'How to Withdraw from the Research',
          'Paano Bumawi sa Pananaliksik')),
      _BodyText(t(
        context,
        'You may withdraw your research consent at any time by contacting the team in Section 23. Your data will then be excluded from further analysis, and the withdrawal will be recorded with the date and time. Results that have already been published or presented in aggregated form cannot be recalled.',
        'Maaari mong bawiin ang iyong pahintulot sa pananaliksik anumang oras sa pamamagitan ng pakikipag-ugnayan sa koponan sa Seksyon 23. Aalisin ang iyong datos sa mga susunod na pagsusuri, at itatala ang pagbawi kasama ang petsa at oras. Ang mga resultang nailathala o naipakita na sa pinagsama-samang anyo ay hindi na mababawi.',
      )),

      const SizedBox(height: 20),
      _EndMarker(t(
        context,
        'End of document. Please review the consent options below.',
        'Katapusan ng dokumento. Pakisuri ang mga pagpipilian sa pahintulot sa ibaba.',
      )),
      const SizedBox(height: 8),
    ];
  }

  // ---------------------------------------------------------------------
  // Bottom action bar
  // ---------------------------------------------------------------------

  Widget _buildActionBar(
    BuildContext context, {
    required double horizontalMargin,
    required double maxSheetHeight,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxSheetHeight),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  horizontalMargin, 14, horizontalMargin, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_scrolledToBottom)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: brandRed.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.keyboard_double_arrow_down_rounded,
                              color: brandRed, size: 18),
                          const SizedBox(width: 8),
                          Flexible(
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
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_scrolledToBottom && !widget.readOnly) ...[
                    _ConsentCheckbox(
                      value: _acceptTerms,
                      enabled: !_saving,
                      required: true,
                      label: t(
                        context,
                        'I have read, understood, and agree to the IGNIS SAFE Terms and Conditions.',
                        'Nabasa, naunawaan, at sumasang-ayon ako sa Mga Tuntunin at Kundisyon ng IGNIS SAFE.',
                      ),
                      onChanged: (v) => setState(() => _acceptTerms = v),
                    ),
                    const SizedBox(height: 8),
                    _ConsentCheckbox(
                      value: _acceptPrivacy,
                      enabled: !_saving,
                      required: true,
                      label: t(
                        context,
                        'I acknowledge that I have read and understood the IGNIS SAFE Privacy Notice and consent to applicable personal-data processing described in it.',
                        'Kinikilala kong nabasa at naunawaan ko ang Paunawa sa Privacy ng IGNIS SAFE at pumapayag ako sa naaangkop na pagproseso ng personal na datos na inilalarawan dito.',
                      ),
                      onChanged: (v) => setState(() => _acceptPrivacy = v),
                    ),
                    const SizedBox(height: 8),
                    _ConsentCheckbox(
                      value: _acceptResearch,
                      enabled: !_saving,
                      required: false,
                      label: t(
                        context,
                        'I voluntarily consent to the use of my de-identified learning and assessment data for the IGNIS SAFE capstone research described in Part V. I may withdraw at any time, and declining does not affect my use of the app.',
                        'Kusang-loob akong pumapayag sa paggamit ng aking de-identified na datos sa pag-aaral at pagtatasa para sa capstone research ng IGNIS SAFE na inilarawan sa Bahagi V. Maaari akong bumawi anumang oras, at ang pagtanggi ay hindi makakaapekto sa aking paggamit ng app.',
                      ),
                      onChanged: (v) => setState(() => _acceptResearch = v),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (_requiredConsentsGiven && !_saving)
                              ? brandRed
                              : Colors.grey.shade400,
                          elevation: (_requiredConsentsGiven && !_saving) ? 2 : 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed:
                            (_requiredConsentsGiven && !_saving) ? _onAgree : null,
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle_rounded,
                                      color: Colors.white, size: 18),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      t(context, 'I Agree and Continue',
                                          'Sumasang-ayon Ako at Magpatuloy'),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    if (!_requiredConsentsGiven) ...[
                      const SizedBox(height: 8),
                      Text(
                        t(
                          context,
                          'Both required boxes must be ticked to continue.',
                          'Kailangang matsekan ang parehong kinakailangang kahon para magpatuloy.',
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11.5,
                          color: Colors.black.withOpacity(0.55),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReturningOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.45),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
            decoration: BoxDecoration(
              color: cardBackground,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(brandRed),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  t(
                    context,
                    'Returning to login page...',
                    'Bumabalik sa login page...',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  final String text;
  const _Title(this.text);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFB71C1C).withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.description_rounded,
                color: Color(0xFFB71C1C),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFB71C1C),
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Divider(height: 1, thickness: 1, color: Color(0xFFEDE7E8)),
      ],
    );
  }
}

/// Version / effective-date / legal-basis header block.
class _MetaBox extends StatelessWidget {
  final String text;
  const _MetaBox(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFB71C1C).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDE7E8)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          color: Colors.black87,
          height: 1.55,
        ),
      ),
    );
  }
}

/// Banner separating the Terms, Privacy Notice and Research parts.
class _PartBanner extends StatelessWidget {
  final String text;
  const _PartBanner(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 26, bottom: 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFB71C1C),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.3,
            height: 1.3,
          ),
        ),
      ),
    );
  }
}

/// Highlighted callout used for the "this part is optional" notice.
class _NoteBox extends StatelessWidget {
  final String text;
  const _NoteBox(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7E6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF0DFB8)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline_rounded,
                size: 18, color: Color(0xFF8A6100)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12.5,
                  color: Color(0xFF6B4B00),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EndMarker extends StatelessWidget {
  final String text;
  const _EndMarker(this.text);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(height: 1, thickness: 1, color: Color(0xFFEDE7E8)),
        const SizedBox(height: 12),
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black.withOpacity(0.55),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 3),
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: const Color(0xFFB71C1C),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFFB71C1C),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BodyText extends StatelessWidget {
  final String text;
  const _BodyText(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 14),
      child: Text(
        text,
        softWrap: true,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13.5,
          color: Colors.black87,
          height: 1.6,
        ),
      ),
    );
  }
}

/// A single consent decision, tagged Required or Optional.
class _ConsentCheckbox extends StatelessWidget {
  final bool value;
  final bool enabled;
  final bool required;
  final String label;
  final ValueChanged<bool> onChanged;

  const _ConsentCheckbox({
    required this.value,
    required this.enabled,
    required this.required,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const brandRed = Color(0xFFB71C1C);
    final tagColor = required ? brandRed : const Color(0xFF4A5A6A);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: enabled ? () => onChanged(!value) : null,
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 6, 10, 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F7F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value ? brandRed.withOpacity(0.45) : const Color(0xFFEDE7E8),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 30,
              child: Checkbox(
                value: value,
                activeColor: brandRed,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: enabled ? (v) => onChanged(v ?? false) : null,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: tagColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      required
                          ? t(context, 'REQUIRED', 'KINAKAILANGAN')
                          : t(context, 'OPTIONAL', 'OPSYONAL'),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: tagColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.black87,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
