import 'package:flutter/material.dart';

import 'onboarding1.dart';

class OnboardingThreePage extends StatelessWidget {
  const OnboardingThreePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const OnboardingFlow(initialPage: 2);
  }
}
