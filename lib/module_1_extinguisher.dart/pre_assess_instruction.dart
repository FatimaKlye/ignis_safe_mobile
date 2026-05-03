import 'package:flutter/material.dart';
import '../localization/app_text.dart';
import 'pre_assessment_extinguisher.dart';

class PreAssessmentIntroPage extends StatelessWidget {
  const PreAssessmentIntroPage({super.key});

  static const Color brandRed = Color(0xFFB11217);

  @override
  Widget build(BuildContext context) {
    final isTl = Localizations.localeOf(context).languageCode == 'tl';

    return Scaffold(
      body: Stack(
        children: [
          // ===== BACKGROUND =====
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 900,
            child: Image.asset(
              'assets/bg.png',
              fit: BoxFit.cover,
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 15),

                // ===== HEADER =====
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),

                      const SizedBox(height: 15),

                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          context.tr('pre_assessment').replaceAll('\n', ' '),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                            height: 1.25,
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: brandRed,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.18),
                                  blurRadius: 10,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.bolt_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  context.tr('module_1'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                context.tr('module_1_full_header'),
                                softWrap: true,
                                maxLines: 3,
                                overflow: TextOverflow.visible,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                  height: 1.35,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // ===== BODY =====
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 28,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.96),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 25,
                                offset: const Offset(0, 15),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.black.withOpacity(0.06),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isTl ? 'PANUTO' : 'INSTRUCTIONS',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                  fontFamily: 'Poppins',
                                  color: Color(0xFF1F2937),
                                ),
                              ),

                              const SizedBox(height: 18),

                              Column(
                                children: [
                                  Text(
                                    isTl
                                        ? 'Ang pagsusulit na ito ay ginawa upang suriin ang iyong pangunahing kaalaman tungkol sa'
                                        : 'This quiz is designed to check your basic knowledge about',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      height: 1.45,
                                      color: Colors.black87,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),

                                  const SizedBox(height: 6),

                                  Text(
                                    context.tr('module_1_full_title'),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      height: 1.35,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w800,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),

                                  const SizedBox(height: 6),

                                  Text(
                                    isTl
                                        ? 'Tinutulungan tayo nitong makita kung ano na ang alam mo bago simulan ang aralin.'
                                        : 'It helps us see what you already know before starting the lesson.',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      height: 1.45,
                                      color: Colors.black87,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 18),

                              Container(
                                height: 1,
                                width: double.infinity,
                                color: Colors.black.withOpacity(0.08),
                              ),

                              const SizedBox(height: 18),

                              Text(
                                isTl
                                    ? 'Ang paunang pagsusulit na ito ay hindi graded. Para lamang ito sa pagsasanay at pagkatuto. Layunin nitong ihanda ka sa mga paksang tatalakayin sa modyul na ito.'
                                    : 'This pre-test is not graded. It is for practice and learning purposes only. The goal is to prepare you for the topics discussed in this module.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  height: 1.5,
                                  color: Colors.black.withOpacity(0.55),
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Poppins',
                                ),
                              ),

                              const SizedBox(height: 26),

                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const PreAssessmentExtinguisherPage(),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: brandRed,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 6,
                                  ),
                                  child: Text(
                                    isTl
                                        ? 'Magpatuloy sa mga Tanong'
                                        : 'Proceed to Questions',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      fontFamily: 'Poppins',
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            const _InfoChip(
                              icon: Icons.timer_outlined,
                              label: '2–3 mins',
                            ),
                            _InfoChip(
                              icon: Icons.quiz_outlined,
                              label: isTl
                                  ? 'Pang-practice lang'
                                  : 'Practice only',
                            ),
                            _InfoChip(
                              icon: Icons.lock_outline,
                              label: isTl ? 'Hindi graded' : 'Not graded',
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
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.black.withOpacity(0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.black.withOpacity(0.72),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Colors.black.withOpacity(0.72),
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}