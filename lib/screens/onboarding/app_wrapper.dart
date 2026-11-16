import 'package:floi/utils/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../main_shell.dart';
import 'onboarding_screen.dart';

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  bool _isLoading = true;
  bool _hasCompletedOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hasCompletedOnboarding =
          prefs.getBool('has_completed_onboarding') ?? false;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Skeletonizer(
          effect: ShimmerEffect(
            baseColor: AppColors.clayShadow.withAlpha(100),
            highlightColor: AppColors.lilac,
            duration: const Duration(seconds: 3),
          ),
          // enabled: _isLoading,
          child: MainShell(),
        ),
      );
    }

    if (_hasCompletedOnboarding) {
      return const MainShell();
    } else {
      return const OnboardingScreen();
    }
  }
}
