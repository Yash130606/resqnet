import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));

    _fadeAnimation =
        Tween<double>(begin: 0, end: 1).animate(_controller);

    _controller.forward();

    Timer(const Duration(seconds: 4), () {
      context.go('/onboarding');

    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [

          /// 🔴 Background Image
          Image.asset(
            "assets/images/disaster_bg.png",
            fit: BoxFit.cover,
          ),

          /// 🔴 Dark Overlay
          Container(
  decoration: const BoxDecoration(
    gradient: LinearGradient(
      colors: [
        Colors.black87,
        Colors.black54,
        Colors.black87,
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  ),
),


          /// 🔴 Content
          FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                /// LOGO
                Image.asset(
                  "assets/images/logo.png",
                  width: 480,
                  height: 480,
                ),

                const SizedBox(height: 30),

                /// MAIN SLOGAN
                const Text(
                  "Coordinating Hope.\nSaving Lives.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 15),

                /// SUB SLOGAN
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  child: Text(
                    "A Real-Time Smart Disaster Response & Relief Coordination Platform",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white70,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                /// LOADING INDICATOR
                const CircularProgressIndicator(
                  color: Colors.redAccent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
