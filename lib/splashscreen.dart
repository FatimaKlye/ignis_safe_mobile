import 'dart:async';
import 'package:flutter/material.dart';
import 'login.dart';

class IgnisSafeSplash extends StatefulWidget {
  const IgnisSafeSplash({super.key});

  @override
  State<IgnisSafeSplash> createState() => _IgnisSafeSplashState();
}

class _IgnisSafeSplashState extends State<IgnisSafeSplash> {
  @override
  void initState() {
    super.initState();
    // Automatically navigates to LoginPage after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            // Replicates the gradient from your uploaded background
            colors: [
              Color(0xFFC61818), // Deep Red
              Color(0xFFC61818), // Solid red for the top 60%
              Color(0xFFF9F9F9), // Fades to white/light grey
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Responsive logo sizing
            Image.asset(
              'assets/logo.png',
              width: MediaQuery.of(context).size.width * 3.0,
            ),
            const SizedBox(height: 30),     
          ],
        ),
      ),
    );
  }
}