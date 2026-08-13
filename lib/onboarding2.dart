import 'package:flutter/material.dart';

import 'onboarding1.dart';

class OnboardingTwoPage extends StatelessWidget {
  const OnboardingTwoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const OnboardingFlow(initialPage: 1);
  }
}
