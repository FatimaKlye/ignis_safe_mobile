import 'package:flutter/material.dart';
import 'localization/language_controller.dart';

const Color _faqBrandRed = Color(0xFFB11217);

Future<void> showFAQDialog(BuildContext context) {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (dialogContext) => const FAQDialog(),
  );
}

class FAQDialog extends StatefulWidget {
  const FAQDialog({super.key});

  @override
  State<FAQDialog> createState() => _FAQDialogState();
}

class _FAQDialogState extends State<FAQDialog> {
  int? _expandedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final items = <_FAQItem>[
      _FAQItem(
        question: t(
          context,
          "1. What does IGNIS SAFE do?",
          "1. Ano ang ginagawa ng IGNIS SAFE?",
        ),
        answer: t(
          context,
          "IGNIS SAFE helps users learn fire safety through learning materials, assessments, and interactive fire scenario simulations. It is designed to improve awareness, preparedness, and proper response during fire emergencies.",
          "Tinutulungan ng IGNIS SAFE ang mga gumagamit na matuto tungkol sa kaligtasan sa sunog sa pamamagitan ng mga materyales sa pagkatuto, pagsusulit, at interaktibong simulation ng sitwasyon ng sunog. Layunin nitong mapabuti ang kamalayan, paghahanda, at tamang pagtugon sa mga emerhensiyang sunog.",
        ),
      ),
      _FAQItem(
        question: t(
          context,
          "2. Why do we need to learn fire scenarios?",
          "2. Bakit kailangan nating pag-aralan ang mga sitwasyon ng sunog?",
        ),
        answer: t(
          context,
          "Learning fire scenarios helps people understand what to do in real emergency situations. It builds correct decision-making, reduces panic, and teaches safe actions that can help protect lives and property.",
          "Ang pag-aaral ng mga sitwasyon ng sunog ay tumutulong sa mga tao na malaman ang dapat gawin sa totoong emerhensiya. Pinahuhusay nito ang tamang pagpapasya, binabawasan ang panic, at nagtuturo ng ligtas na mga kilos na makatutulong protektahan ang buhay at ari-arian.",
        ),
      ),
      _FAQItem(
        question: t(
          context,
          "3. What is the purpose of this app?",
          "3. Ano ang layunin ng app na ito?",
        ),
        answer: t(
          context,
          "The purpose of this app is to provide an engaging and practical way to learn fire safety. It combines education and simulation so users can gain knowledge and apply it in realistic fire emergency situations.",
          "Layunin ng app na ito na magbigay ng kaakit-akit at praktikal na paraan para matuto ng kaligtasan sa sunog. Pinagsasama nito ang edukasyon at simulation upang makakuha ng kaalaman ang mga gumagamit at mailapat ito sa makatotohanang sitwasyon ng emerhensiyang sunog.",
        ),
      ),
    ];

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: size.height * 0.75,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FAQHeader(title: t(context, "FAQ", "Mga Madalas Itanong")),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                  child: Column(
                    children: List.generate(items.length, (index) {
                      return _FAQCard(
                        item: items[index],
                        expanded: _expandedIndex == index,
                        onTap: () {
                          setState(() {
                            _expandedIndex = _expandedIndex == index
                                ? null
                                : index;
                          });
                        },
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FAQHeader extends StatelessWidget {
  const _FAQHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 18),
      decoration: const BoxDecoration(
        color: _faqBrandRed,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.help_outline_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            splashRadius: 20,
            tooltip: '',
          ),
        ],
      ),
    );
  }
}

class _FAQItem {
  const _FAQItem({required this.question, required this.answer});

  final String question;
  final String answer;
}

class _FAQCard extends StatelessWidget {
  const _FAQCard({
    required this.item,
    required this.expanded,
    required this.onTap,
  });

  final _FAQItem item;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: expanded ? _faqBrandRed.withOpacity(0.35) : Colors.transparent,
          width: 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.question,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: _faqBrandRed,
                      ),
                    ),
                  ],
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox(width: double.infinity, height: 0),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      item.answer,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                  crossFadeState: expanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                  sizeCurve: Curves.easeInOut,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
