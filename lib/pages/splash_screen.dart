import 'package:flutter/material.dart';
import "package:lottie/lottie.dart";
import "package:arxiv/pages/home_page.dart";
import "package:another_flutter_splash_screen/another_flutter_splash_screen.dart";

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    return FlutterSplashScreen.fadeIn(
      backgroundColor: Colors.white,
      childWidget: SizedBox(
        height: 150.0,
        width: 150.0,
        child: Lottie.asset(
          "assets/animation/OpenScholarXIVLoader.json",
        ),
      ),
      nextScreen: const HomePage(),
    );
  }
}
