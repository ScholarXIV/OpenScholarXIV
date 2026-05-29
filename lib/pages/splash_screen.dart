import 'package:flutter/material.dart';
import "package:lottie/lottie.dart";
import "package:arxiv/pages/home_page.dart";

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: SizedBox(
          height: 150.0,
          width: 150.0,
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(
              isDark ? Colors.white : Colors.black,
              BlendMode.srcIn,
            ),
            child: Lottie.asset(
              "assets/animation/OpenScholarXIVLoader.json",
              repeat: true,
            ),
          ),
        ),
      ),
    );
  }
}
