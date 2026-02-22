import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  final String firstName;
  final String lastName;
  final bool isFirstTime;
  final String avatarImage;

  const HomeHeader({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.isFirstTime,
    required this.avatarImage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 28,
          backgroundImage: AssetImage(avatarImage),
          backgroundColor: Colors.deepOrange.shade100,
        ),
        const SizedBox(width: 16),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hi, $firstName $lastName",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isFirstTime ? "Welcome" : "Welcome back",
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

